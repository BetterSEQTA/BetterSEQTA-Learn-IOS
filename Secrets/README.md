# Secrets (not committed)

This folder holds machine-local credentials and signing material. **Nothing here should be committed to git** except `.gitkeep` and this README.

## Recommended files

| File | Purpose |
|------|---------|
| `SeqtaTestCredentials.plist` | Manual QA login (generate locally) |
| `.env.local` | Playwright or automation env vars (see repo `.env.example` when added) |

Use environment variables in scripts and docs, for example:

- `SEQTA_TEST_BASE_URL` — school base URL (no trailing path)
- `SEQTA_TEST_USERNAME` / `SEQTA_TEST_PASSWORD` — never paste into markdown or source

Rotate any credential that may have been exposed in chat or logs.
