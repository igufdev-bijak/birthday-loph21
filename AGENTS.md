# AGENTS.md

- Static site, no framework or build step. `netlify.toml` publishes `public/`.
- `public/index.html` is the entire app: inline CSS and JS, Indonesian-language copy.
- State (customisations) lives in browser `localStorage`; there is no backend.
- Keep it self-contained — edit the single HTML file in place.
