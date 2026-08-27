# Trade Reputation frontend

- Use current Discourse frontend/plugin conventions verified from source.
- Consume only Trade Reputation JSON APIs; never call Marketplace internals from the client.
- Do not invent private IDs or reputation scores absent from backend responses.
- Comments render as escaped plain text, not raw HTML/Markdown cooking.
- Support mobile/desktop and light/dark themes.
- Pagination must actually reload the requested backend page.
- Distinguish valid numeric `0` from null/missing data.
- User-visible copy belongs in locale files.
