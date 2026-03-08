## Philosophy
- **Security First:** Secrets management, scanning, access controls built-in, sanitize and validate all external inputs
- **KISS (Keep It Simple, Stupid):** Deliver full functionality without over-engineering or unnecessary complexity
- **Locality of Behaviour:** Keep the logic that triggers a behavior close to the behavior itself
- **DRY & Modular:** Use reusable modules and inherited configs. Keep repositories small and focused
- **Fail-Safe & Early Validation:** Extensive pre-merge checks, schema validation, and detailed error reporting
- **IaC & GitOps:** Everything in version control. All changes via PR with automated plan reviews
- **Rule of Three:** No premature abstraction; wait until you've written the same pattern three times
- **Configuration-Driven:** YAML configs drive infrastructure with minimal code changes
- **Documentation as Code:** Auto-generated docs, comprehensive READMEs
- **Environment Isolation:** Separate state, configs, and deployments per environment
- **Clarity > Cleverness:** Prefer explicit, readable logic over dense, "clever" one-liners
- **Finish the Job:** Handle edge cases, clean up technical debt in your path, and ensure "Definition of Done" includes verification. Don't gold-plate, but don't leave it "half-baked."
- **Be Explicit**: Make all intentions clear and unambiguous in both code and communication

## Communication Style
- Be direct and concise
- Use bullet points over long paragraphs
- Skip preamble and summaries
- If a request is unclear, ask for clarification before proceeding
- Say "I don't know" when uncertain rather than making things up
- All facts must be verified - never invent information

## Code Quality
### Hard Limits
- <=100 lines/function, cyclomatic complexity <=8
- <=5 positional params
- 120 line length
- Google-style docstrings on non-trivial public APIs

### Style
- Prefer small, focused functions
- Use early returns over nested conditionals
- Type hints where possible

### Zero Warnings Policy
- Fix every warning from every tool (linters, type checkers, compilers, tests)
- If a warning truly can't be fixed, add an inline ignore with a justification comment
- Never leave warnings unaddressed; a clean output is the baseline, not the goal

### Comments
- Code should be self-documenting
- Comments must explain the WHY, not the WHAT or the HOW. If you need a comment to explain what the code does, refactor the code instead
- No commented-out code—delete it immediately

### Error handling
- Fail fast with clear, actionable messages
- Never swallow exceptions silently
- Include context (what operation, what input, suggested fix)
