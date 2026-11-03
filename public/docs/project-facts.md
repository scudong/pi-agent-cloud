# pi-agent-cloud — 项目事实

## 这是什么

一个跑在 Cloudflare **免费档**上的 pi 编码 agent 后端：

- **运行时**：Cloudflare Workers（`nodejs_compat`）
- **会话状态**：Durable Object `PiAgent`（SQLite 存储，可跨请求恢复）
- **Agent 内核**：官方 Agents SDK 的 `PiHarness`（`agents/harness/pi`）+ `@earendil-works/pi-durable`
- **模型**：Workers AI 免费模型 `@cf/openai/gpt-oss-120b`（通过 binding 调用，自动经 AI Gateway）
- **知识库**：Cloudflare AI Search 实例 `pi-agent-cloud-kb`（内置存储，文档经 Items REST API 上传）
- **前端**：单页聊天界面，由 Worker 的 assets 提供

## 能力边界

能做的：

- 多轮对话，会话持久化在 Durable Object 里，刷新页面不丢
- 调用 `ai_search` 工具检索知识库后回答
- 读取当前 UTC 时间（`now` 工具）

不能做的（免费 Workers 运行的固有限制）：

- **没有终端 / 没有 PTY**：不能执行 shell 命令
- **没有本地文件系统**：不能读写你电脑上的项目文件、不能看 git diff
- **没有子进程**：不能跑构建、测试、脚本

也就是说它是「云端问答 + 检索 agent」，不是「能改代码的编码 agent」。
需要真正操作本地代码时，用本地版 pi-web（Pages 反代 + Tunnel 那套）。

## 接口

| 方法 | 路径 | 用途 |
|---|---|---|
| GET | `/api/health` | 健康检查（模型、知识库实例名） |
| POST | `/api/setup` | 幂等创建空的知识库实例 |
| GET | `/api/status` | 知识库状态 |
| POST | `/api/chat` | `{"message":"..."}` → `{"answer":"..."}` |
| GET | `/api/messages` | 当前会话转录 |
| GET | `/api/probe-models` | 探测本计划可用的聊天模型 |

## 金丝雀

仓库里有一份 `canary-ground-truth.md`，其中包含一个只存在于知识库的暗号。
问 agent「知识库里暗号是什么」，答对即证明检索链路（DO → AI Search → 模型）全线打通。
