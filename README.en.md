# pi-agent-cloud

English | [中文](./README.md)

The [pi](https://github.com/earendil-works/pi) agent kernel running on the **Cloudflare Workers free tier**:
`PiHarness` on a Durable Object, Workers AI for the model, AI Search for the knowledge base — no credit card, no API token.

> Relation to [agegr/pi-web](https://github.com/agegr/pi-web):
> **the agent kernel is version-aligned with pi-web v0.14.1 (`@earendil-works/pi-ai` 1.4.0), and the UI uses pi-web's design tokens.**
> pi-web itself (68 API routes, terminal, filesystem) cannot run on Workers — see "Capabilities" below.

## Architecture

```
Browser
  │  pages.dev (reachable from CN) / workers.dev
  ▼
Worker  src/index.ts          static assets + /api/*
  │
  ├─ PiAgent (Durable Object, SQLite)   src/agent.ts
  │    ├─ PiHarness (agents/harness/pi)
  │    ├─ createAI({ binding: AI })  → Workers AI
  │    └─ tools: ai_search / now
  │
  └─ AI Search instance pi-agent-cloud-kb (built-in storage)
```

Sessions, transcripts and tool-call records live in **Durable Object SQLite**: they survive page reloads,
other devices and redeployments.

## Capabilities

| Can | Cannot |
|---|---|
| Multi-turn chat, sessions persisted in the DO | ❌ run shell commands (no child processes / PTY) |
| Call `ai_search` over the knowledge base | ❌ read or write local project files (no filesystem) |
| Read the current UTC time | ❌ git diff / builds / tests |
| Stay online 24/7 without your machine | ❌ replace pi-web |

For real code editing, use the local pi-web setup ([pi-web-cloudflare](https://github.com/scudong/pi-web-cloudflare)).

## Version alignment

```bash
./scripts/check-upstream.sh          # compares against pi-web v0.14.1 by default
```

```
pi-web v0.14.1 (0.14.1) pi-ai: 1.4.0
this project            pi-ai: 1.4.0
Agents SDK pi-durable range: ~1.4.0
aligned ✅
```

Why we stop at 1.4.0: the Cloudflare Agents SDK (even 0.32.0) still declares `@earendil-works/pi-durable ~1.4.0`,
while pi-web v0.14.2 moved to pi 1.5.0. Dependencies are pinned exactly to prevent silent drift.

## Deploy

```bash
pnpm install
pnpm exec wrangler deploy                 # requires a logged-in wrangler
curl -X POST https://<worker>/api/setup   # create the empty KB instance (idempotent)
CLOUDFLARE_ACCOUNT_ID=<acc> ./scripts/kb-sync.sh   # upload public/docs/*.md (wrangler OAuth, zero tokens)
```

Mainland mirror: `mirror/_worker.js` is a Pages Advanced Mode reverse proxy in front of the Worker,
deployed with `wrangler pages deploy mirror --project-name pi-agent-cloud-mirror`.

## API

| Method | Path | Description |
|---|---|---|
| GET | `/api/health` | model + KB instance |
| POST | `/api/setup` | idempotently create the empty AI Search instance |
| GET | `/api/status` | KB status |
| POST | `/api/chat` | `{"message":"..."}` → `{"text":"..."}` |
| GET | `/api/messages` | transcript from DO storage |
| POST | `/api/reset` | reset the conversation |
| GET | `/api/probe-models` | probe which free-tier models are runnable |

## Acceptance

Ask "what is the passphrase in the knowledge base?" — the agent must call `ai_search` to answer
"紫电青霜-2026", a string that only exists in `public/docs/canary-ground-truth.md`.

## License

MIT
