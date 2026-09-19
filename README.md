# Tasks

Google Tasks on the Mac, and in Claude.

- **`mcp/`**: a remote MCP connector on Cloudflare Workers. Claude can read your todos, tick them off, add them and edit them. It can't delete anything.
- **`mac/`**: a SwiftUI menu bar app for macOS 27. Shows a due count, quick add with date parsing, Overdue and Today, plus a full window with lists, subtasks and search.
- **`docs/`**: the public website (homepage, [privacy policy](https://binhnguyeeen.github.io/tasks/privacy.html), [terms](https://binhnguyeeen.github.io/tasks/terms.html)), served by GitHub Pages.

This is a personal project. The hosted connector only accepts allow-listed Google accounts. To use it yourself, deploy your own copy with your own Google Cloud OAuth clients. Not affiliated with Google, Apple or Anthropic.

MIT licensed. See [LICENSE](LICENSE).
