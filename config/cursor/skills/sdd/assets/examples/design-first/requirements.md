# Requirements: Rate Limiter Middleware

## Overview

Provide configurable per-endpoint rate limiting for the Express API using
a token bucket algorithm backed by Redis, enforcing limits per user or IP.

## Requirements

### 1. Request Limiting

**User Story:** As an API operator, I want requests to be rate-limited per
endpoint, so that no single client can exhaust server resources.

#### Acceptance Criteria

1. WHEN a client exceeds the configured request limit for an endpoint
   THE SYSTEM SHALL respond with HTTP 429 and a `Retry-After` header
   indicating when the client may retry.

2. WHEN a client is within the configured request limit
   THE SYSTEM SHALL pass the request through to the next middleware without
   adding more than 100ms of latency.

3. IF Redis is unreachable
   THEN THE SYSTEM SHALL allow the request through and log a warning
   (fail-open behaviour).

---

### 2. Configuration

**User Story:** As a developer, I want to configure different rate limits
per endpoint, so that I can apply stricter limits to sensitive routes.

#### Acceptance Criteria

1. WHEN a route has no explicit limit configured
   THE SYSTEM SHALL apply the global default limit.

2. WHEN a route has an explicit limit configured
   THE SYSTEM SHALL apply that limit instead of the global default.

---

### 3. Client Identification

**User Story:** As an API operator, I want limits enforced per user for
authenticated requests and per IP for unauthenticated ones, so that
limits are fairly scoped.

#### Acceptance Criteria

1. WHEN a request carries a valid authentication token
   THE SYSTEM SHALL apply the rate limit against the authenticated user ID.

2. WHEN a request has no authentication token
   THE SYSTEM SHALL apply the rate limit against the client IP address.
