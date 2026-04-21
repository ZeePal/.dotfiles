import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const isTmux = () => Boolean(process.env.TMUX) || process.env.TERM_PROGRAM === "tmux";

const bell = () => {
    if (isTmux()) process.stdout.write("\x07");
};

export default function tmuxBellOnWait(pi: ExtensionAPI) {
    pi.on("agent_end", () => {
        bell();
    });
}
