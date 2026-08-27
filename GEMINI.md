@AGENTS.md

# Gemini adapter

Treat `AGENTS.md` as canonical. Do not recursively preload local instruction files. Route to only the nearest `AGENTS.md` files for the current task plus current state and minimum source/tests. In orchestrated work also obey the locked task/file allow-list/human gates. Cross-model procedures live in `.agents/skills/`.
