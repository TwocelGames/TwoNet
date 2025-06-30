# FastTasks

A high-performance thread pooling library for Roblox.

## 🚀 Features
- Reuses idle coroutines to avoid allocation overhead
- Custom sweeping logic for cleaning up unused threads
- Drop-in replacement for `task.spawn`, `task.defer`, and `task.delay`
- Lightweight and highly optimized

---

## 📘 API

```luau
FastTask.spawn(f: (...any) -> ()) -> thread
-- Works similarly to task.spawn but reuses coroutines.

FastTask.defer(f: (...any) -> ()) -> thread
-- Works similarly to task.defer with pooling.

FastTask.delay(delay: number, f: (...any) -> ()) -> thread
-- Works similarly to task.delay with pooling.
