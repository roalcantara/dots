# Tasks: Rate Limiter Middleware

- [ ] 1. Implement core TokenBucket algorithm
  - Create `TokenBucket.consume(state, config)` with refill math
  - Enforce burst ceiling (`min(tokens + refilled, capacity)`)
  - Return `{ allowed, remaining, resetAt }`
  - **Requirements:** 1.1, 1.2

- [ ] 2. Implement RedisStore with atomic operations
  - Use Lua script for atomic GET + SET to prevent race conditions
  - Set TTL on bucket keys equal to `config.windowMs`
  - Expose `get(key)` and `set(key, state, ttl)` methods
  - **Requirements:** 1.2, 1.3

- [ ] 3. Implement `rateLimiter()` middleware factory
  - Accept per-route `LimitConfig`; fall back to global default if absent
  - Resolve client key: authenticated user ID or IP address
  - Call `RedisStore.get()` → `TokenBucket.consume()` → `RedisStore.set()`
  - On allowed: call `next()`
  - On denied: respond 429 with `Retry-After` header
  - On Redis error: log warning and call `next()` (fail-open)
  - **Requirements:** 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2

- [ ] 4. Write tests
  - Unit: `TokenBucket.consume()` — refill, ceiling, exhaustion edge cases
  - Unit: `resolveKey()` — authenticated vs unauthenticated
  - Integration: middleware on test Express app with `ioredis-mock`
  - Integration: Redis failure → fail-open behaviour
  - Load: verify <100ms overhead at 1000 req/s with `autocannon`
  - **Requirements:** 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2
