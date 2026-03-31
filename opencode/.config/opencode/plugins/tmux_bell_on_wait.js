const WAITING_EVENTS = new Set([
    "permission.asked",
    "question.asked",
])

const bell = () => {
    if (process.env.TERM_PROGRAM !== "tmux") {
        return
    }

    process.stdout.write("\u0007")
}

export const TmuxBellOnWaitPlugin = async () => {
    return {
        event: async ({ event }) => {
            if (event.type === "session.status" && event.properties?.status?.type === "idle") {
                bell()
                return
            }

            if (!WAITING_EVENTS.has(event.type)) {
                return
            }

            bell()
        },
    }
}
