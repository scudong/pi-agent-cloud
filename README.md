# pi-agent-cloud

**English** | 中文

把 [pi](https://github.com/earendil-works/pi) 的 agent 内核搬到 **Cloudflare Workers 免费档**：
`PiHarness` 跑在 Durable Object 上，模型走 Workers AI，知识库走 AI Search——不绑卡、不需要 API token。

> 与 [agegr/pi-web](https://github.com/agegr/pi-web) 的关系：
> **agent 内核版本对齐 pi-web v0.14.1（`@earendil-works/pi-ai` 1.4.0），界面取色沿用 pi-web 的 design token。**
> pi-web 本身（68 个 API、终端、文件系统）跑不进 Workers——那些依赖不存在，见下文「能力边界」。

## 架构

```
浏览器
  │  pages.dev（大陆可达）/ workers.dev
  ▼
Worker  src/index.ts          assets 静态页 + /api/*
  │
  ├─ PiAgent（Durable Object，SQLite）   src/agent.ts
  │    ├─ PiHarness（agents/harness/pi）
  │    ├─ createAI({ binding: AI })  → Workers AI
  │    └─ tools: ai_search / now
  │
  └─ AI Search 实例 pi-agent-cloud-kb（内置存储）
```

会话、转录、工具调用记录全部存在 **Durable Object 的 SQLite** 里：刷新页面、换设备、重新部署都不丢。

## 能力边界

| 能做 | 不能做 |
|---|---|
| 多轮对话，会话持久化在 DO | ❌ 执行 shell 命令（没有子进程/PTY） |
| 调用 `ai_search` 检索知识库 | ❌ 读写本地项目文件（没有文件系统） |
| 读取当前 UTC 时间 | ❌ git diff / 构建 / 测试 |
| 24 小时在线，不依赖本机 | ❌ 充当完整的 pi-web |

需要真正改代码时，用本地版 pi-web（[pi-web-cloudflare](https://github.com/scudong/pi-web-cloudflare) 那套）。

## 版本对齐

```bash
./scripts/check-upstream.sh          # 默认参照 pi-web v0.14.1
```

当前结果：

```
参照 pi-web v0.14.1（0.14.1）的 pi-ai: 1.4.0
本项目 pi-ai: 1.4.0
Agents SDK 声明的 pi-durable 范围: ~1.4.0
结论: 已对齐 ✅
```

为什么停 1.4.0：Cloudflare Agents SDK（含最新 0.32.0）的 `PiHarness` 仍声明 `@earendil-works/pi-durable ~1.4.0`；
pi-web v0.14.2 起用 pi 1.5.0，在 Agents SDK 放开 peer 之前无法跟随。依赖已锁精确版本，避免悄悄漂移。

## 部署

```bash
pnpm install
pnpm exec wrangler deploy                 # 需要已登录的 wrangler
curl -X POST https://<worker>/api/setup   # 建空的知识库实例（幂等）
CLOUDFLARE_ACCOUNT_ID=<acc> ./scripts/kb-sync.sh   # 上传 public/docs/*.md（wrangler OAuth，零 token）
```

镜像（大陆可达）：`mirror/_worker.js` 用 Pages Advanced Mode 反代 Worker，
`wrangler pages deploy mirror --project-name pi-agent-cloud-mirror`。

## 接口

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/health` | 模型、知识库实例名 |
| POST | `/api/setup` | 幂等创建空 AI Search 实例 |
| GET | `/api/status` | 知识库状态 |
| POST | `/api/chat` | `{"message":"..."}` → `{"text":"..."}` |
| GET | `/api/messages` | 当前会话转录（DO 存储） |
| POST | `/api/reset` | 重置会话 |
| GET | `/api/probe-models` | 探测免费档可用的模型 |

## 验收

问「知识库里的暗号是什么？」→ 必须调 `ai_search` 才能答出「紫电青霜-2026」。
暗号只存在于 `public/docs/canary-ground-truth.md`。

## License

MIT
