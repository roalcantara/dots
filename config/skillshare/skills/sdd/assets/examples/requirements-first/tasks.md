# Tasks: User Authentication

- [ ] 1. Set up database schema and repositories
  - Create `users` table with `id`, `email`, `password_hash`, `created_at`, `updated_at`
  - Create `reset_tokens` table with `id`, `user_id`, `token`, `expires_at`, `used_at`
  - Implement `UserRepository.findByEmail()` and `UserRepository.create()`
  - Implement `ResetTokenRepository.create()`, `findByToken()`, and `markUsed()`
  - **Requirements:** 1.1, 3.1, 3.4

- [ ] 2. Implement registration endpoint
  - `POST /auth/register` — validate email format and password length
  - Hash password with bcrypt (cost factor 12)
  - Return 409 if email already exists
  - Return 201 and JWT on success
  - **Requirements:** 1.1, 1.2, 1.3, 1.4

- [ ] 3. Implement login endpoint with brute-force protection
  - `POST /auth/login` — validate credentials against stored hash
  - Increment Redis failed-attempt counter on failure
  - Lock account for 15 minutes after 5 consecutive failures
  - Return generic 401 message (no field disclosure)
  - Reset counter on successful login
  - **Requirements:** 2.1, 2.2, 2.3

- [ ] 4. Implement password reset flow
  - `POST /auth/reset-request` — generate reset token, send email via MailService
  - Return identical response for registered and unregistered emails
  - `POST /auth/reset-confirm` — validate token, check expiry and `used_at`
  - Update password hash, mark token as used, redirect to login
  - **Requirements:** 3.1, 3.2, 3.3, 3.4

- [ ] 5. Implement logout endpoint
  - `POST /auth/logout` — invalidate session token (add to denylist or clear cookie)
  - Return 401 for subsequent requests using the old token
  - **Requirements:** 4.1, 4.2

- [ ] 6. Write tests
  - Unit: `AuthService` — credential validation, lockout counter, token expiry
  - Integration: register → login → logout flow against test DB
  - Integration: full password reset flow with mock MailService
  - E2E: happy path login via UI
  - E2E: brute-force lockout (5 failed attempts)
  - **Requirements:** 1.1–1.4, 2.1–2.3, 3.1–3.4, 4.1–4.2
