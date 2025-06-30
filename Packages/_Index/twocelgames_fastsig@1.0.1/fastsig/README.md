# FastSig

## Ultra-fast signal system for Roblox with zero instances, coroutine support, and customizable execution mode.

**FastSig** is a lightweight, blazing-fast signal implementation for Roblox, designed for performance-critical use cases. It offers low-overhead event signaling with coroutine support, reusable threads, and optional deferred or immediate dispatching.

---

## 🚀 Features

- Double-linked list connection management (O(1) `Connect`/`Disconnect`)
- Support for `.Connect`, `.Once`, `.Wait`, `.Fire`, `.Destroy`
- Configurable dispatch strategy: **Immediate** or **Deferred**
- Coroutine thread reuse via [`FastTasks`](https://github.com/TwocelGames/FastTasks)
- Type-safe and strict-mode compatible (`--!strict`)
- No memory leaks — connections are cleaned automatically
