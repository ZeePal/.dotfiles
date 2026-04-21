import { FooterComponent, type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";

type CopilotQuotaState = {
    requestsLeft?: number;
    resetTimeIso?: string;
    loading: boolean;
    promptsSinceRefresh: number;
    inFlight?: Promise<void>;
};

const GITHUB_COPILOT_PROVIDER = "github-copilot";
const COPILOT_INTERNAL_USER_URL = "https://api.github.com/copilot_internal/user";
const GITHUB_API_VERSION = "2022-11-28";
const REQUEST_TIMEOUT_MS = 15_000;
const PROMPTS_PER_REFRESH = 5;

function coerceFiniteNumber(value: unknown): number | undefined {
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value !== "string") return undefined;
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : undefined;
}

function coerceNonEmptyString(value: unknown): string | undefined {
    if (typeof value !== "string") return undefined;
    const trimmed = value.trim();
    return trimmed || undefined;
}

function getNestedValue(source: unknown, path: string[]): unknown {
    let current = source;
    for (const key of path) {
        if (!current || typeof current !== "object" || !(key in current)) return undefined;
        current = (current as Record<string, unknown>)[key];
    }
    return current;
}

function getFirstNestedNumber(source: unknown, paths: string[][]): number | undefined {
    for (const path of paths) {
        const value = coerceFiniteNumber(getNestedValue(source, path));
        if (value !== undefined) return value;
    }
    return undefined;
}

function getFirstNestedString(source: unknown, paths: string[][]): string | undefined {
    for (const path of paths) {
        const value = coerceNonEmptyString(getNestedValue(source, path));
        if (value !== undefined) return value;
    }
    return undefined;
}

function normalizeResetTimeIso(value: string | undefined): string | undefined {
    if (!value) return undefined;
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return `${value}T00:00:00.000Z`;
    const timestamp = Date.parse(value);
    return Number.isNaN(timestamp) ? undefined : new Date(timestamp).toISOString();
}

function getApproxNextResetIso(nowMs: number = Date.now()): string {
    const now = new Date(nowMs);
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)).toISOString();
}

function formatTimeTillReset(resetTimeIso?: string): string {
    if (!resetTimeIso) return "?";

    const resetAt = Date.parse(resetTimeIso);
    if (Number.isNaN(resetAt)) return "?";

    const diffMs = resetAt - Date.now();
    const hourMs = 60 * 60 * 1000;
    const dayMs = 24 * hourMs;

    if (diffMs < hourMs) return "<1h";
    if (diffMs < dayMs) return `${Math.floor(diffMs / hourMs)}h`;
    return `${Math.floor(diffMs / dayMs)}d`;
}

function isCopilotModel(model: { provider?: string } | undefined): boolean {
    return model?.provider === GITHUB_COPILOT_PROVIDER;
}

function getQuotaLabel(quota: CopilotQuotaState): string {
    if (typeof quota.requestsLeft === "number") {
        return `${quota.requestsLeft} (${formatTimeTillReset(quota.resetTimeIso)})`;
    }
    return quota.loading ? "…" : "?";
}

function parseCopilotUserQuota(payload: unknown): { requestsLeft: number; resetTimeIso: string } {
    const requestsLeft = getFirstNestedNumber(payload, [
        ["quota_snapshots", "premium_interactions", "remaining"],
        ["quota_snapshots", "premium_interactions", "quota_remaining"],
        ["premium_requests", "remaining"],
        ["quota", "remaining"],
        ["remaining"],
    ]);

    const resetTimeIso =
        normalizeResetTimeIso(
            getFirstNestedString(payload, [
                ["quota_reset_date_utc"],
                ["quota_reset_date"],
                ["premium_requests", "reset_at"],
                ["quota", "reset_at"],
                ["reset_at"],
            ]),
        ) ?? getApproxNextResetIso();

    if (requestsLeft === undefined) {
        throw new Error("GitHub Copilot premium request remaining count was missing from /copilot_internal/user.");
    }

    return {
        requestsLeft: Math.max(0, Math.floor(requestsLeft)),
        resetTimeIso,
    };
}

async function readErrorText(response: Response): Promise<string> {
    try {
        const text = await response.text();
        if (!text.trim()) return `${response.status} ${response.statusText}`;
        try {
            const json = JSON.parse(text) as { message?: unknown };
            if (typeof json.message === "string" && json.message.trim()) {
                return `${response.status} ${json.message.trim()}`;
            }
        } catch {
            // ignore parse failures
        }
        return `${response.status} ${text.replace(/\s+/g, " ").trim().slice(0, 200)}`;
    } catch {
        return `${response.status} ${response.statusText}`;
    }
}

async function fetchCopilotUserQuota(ctx: ExtensionContext): Promise<{ requestsLeft: number; resetTimeIso: string }> {
    const auth = ctx.modelRegistry.authStorage.get(GITHUB_COPILOT_PROVIDER) as
        | { refresh?: string; access?: string }
        | undefined;
    const token =
        auth?.refresh?.trim() ||
        auth?.access?.trim() ||
        (await ctx.modelRegistry.getApiKeyForProvider(GITHUB_COPILOT_PROVIDER));

    if (!token) throw new Error("No GitHub Copilot credentials are configured.");

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
        const response = await fetch(COPILOT_INTERNAL_USER_URL, {
            headers: {
                Accept: "application/vnd.github+json",
                Authorization: `Bearer ${token}`,
                "X-GitHub-Api-Version": GITHUB_API_VERSION,
                "User-Agent": "pi-github-copilot-quota-extension",
            },
            signal: controller.signal,
        });

        if (!response.ok) throw new Error(await readErrorText(response));
        return parseCopilotUserQuota(await response.json());
    } finally {
        clearTimeout(timeout);
    }
}

export default function (pi: ExtensionAPI) {
    const quota: CopilotQuotaState = {
        loading: false,
        promptsSinceRefresh: 0,
    };

    let activeCtx: ExtensionContext | undefined;
    let currentModel: { id?: string; provider?: string; reasoning?: boolean } | undefined;
    let footerRequestRender: (() => void) | undefined;

    function requestRender(): void {
        footerRequestRender?.();
    }

    async function refreshQuota(ctx: ExtensionContext): Promise<void> {
        if (quota.inFlight) return quota.inFlight;

        quota.loading = true;
        requestRender();

        const run = (async () => {
            try {
                const result = await fetchCopilotUserQuota(ctx);
                if (activeCtx !== ctx) return;
                quota.requestsLeft = result.requestsLeft;
                quota.resetTimeIso = result.resetTimeIso;
                quota.promptsSinceRefresh = 0;
            } catch {
                if (activeCtx !== ctx) return;
            } finally {
                if (quota.inFlight === run) quota.inFlight = undefined;
                if (activeCtx === ctx) {
                    quota.loading = false;
                    requestRender();
                }
            }
        })();

        quota.inFlight = run;
        return run;
    }

    function maybeRefreshQuota(ctx: ExtensionContext, force: boolean = false): void {
        if (!isCopilotModel(currentModel)) return;
        if (force || quota.requestsLeft === undefined || quota.promptsSinceRefresh >= PROMPTS_PER_REFRESH) {
            void refreshQuota(ctx);
        }
    }

    function installFooter(ctx: ExtensionContext): void {
        ctx.ui.setFooter((tui, _theme, footerData) => {
            footerRequestRender = () => tui.requestRender();
            const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

            const sessionAdapter = {
                get state() {
                    const model = currentModel;
                    return {
                        model:
                            model && isCopilotModel(model)
                                ? { ...model, id: `${getQuotaLabel(quota)} • ${model.id}` }
                                : model,
                        thinkingLevel: pi.getThinkingLevel(),
                    };
                },
                get sessionManager() {
                    return activeCtx!.sessionManager;
                },
                get modelRegistry() {
                    return activeCtx!.modelRegistry;
                },
                getContextUsage() {
                    return activeCtx?.getContextUsage();
                },
            };

            const footer = new FooterComponent(sessionAdapter as any, footerData);

            return {
                dispose() {
                    unsubscribe();
                    footer.dispose?.();
                    if (footerRequestRender) footerRequestRender = undefined;
                },
                invalidate() {
                    footer.invalidate();
                },
                render(width: number): string[] {
                    return footer.render(width);
                },
            };
        });
    }

    pi.on("session_start", async (_event, ctx) => {
        activeCtx = ctx;
        currentModel = ctx.model;
        quota.promptsSinceRefresh = 0;
        installFooter(ctx);
        maybeRefreshQuota(ctx, true);
    });

    pi.on("model_select", async (event, ctx) => {
        activeCtx = ctx;
        currentModel = event.model;
        if (isCopilotModel(event.model) && quota.requestsLeft === undefined) {
            maybeRefreshQuota(ctx, true);
        }
    });

    pi.on("agent_end", async (_event, ctx) => {
        activeCtx = ctx;
        currentModel = ctx.model;
        if (!isCopilotModel(currentModel)) return;

        quota.promptsSinceRefresh += 1;
        if (quota.promptsSinceRefresh >= PROMPTS_PER_REFRESH) {
            maybeRefreshQuota(ctx, true);
        }
    });
}
