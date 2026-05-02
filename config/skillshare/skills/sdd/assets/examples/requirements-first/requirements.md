# Requirements: User Authentication

## Overview

Allow users to register, log in, reset forgotten passwords, and log out
securely. The system must prevent brute-force attacks and validate email
formats before account creation.

## Requirements

### 1. User Registration

**User Story:** As a new user, I want to create an account with my email
and password, so that I can access the platform.

#### Acceptance Criteria

1. WHEN a user submits a valid email and password
   THE SYSTEM SHALL create a new account and redirect to the dashboard.

2. WHEN a user submits an email that already exists
   THE SYSTEM SHALL display "Email already registered" and not create a
   duplicate account.

3. WHEN a user submits an invalid email format
   THE SYSTEM SHALL display an inline validation error before form submission.

4. WHEN a user submits a password shorter than 8 characters
   THE SYSTEM SHALL display "Password must be at least 8 characters."

---

### 2. User Login

**User Story:** As a registered user, I want to log in with my credentials,
so that I can access my account.

#### Acceptance Criteria

1. WHEN a user submits valid credentials
   THE SYSTEM SHALL create an authenticated session and redirect to the dashboard.

2. IF a user submits invalid credentials 5 times in a row
   THEN THE SYSTEM SHALL lock the account for 15 minutes and display
   "Too many failed attempts. Try again in 15 minutes."

3. WHEN a user submits invalid credentials (below the lockout threshold)
   THE SYSTEM SHALL display "Invalid email or password" without revealing
   which field is incorrect.

---

### 3. Password Reset

**User Story:** As a user who forgot my password, I want to reset it via
email, so that I can regain access to my account.

#### Acceptance Criteria

1. WHEN a user requests a password reset for a registered email
   THE SYSTEM SHALL send a reset link valid for 1 hour to that address.

2. WHEN a user requests a password reset for an unregistered email
   THE SYSTEM SHALL display the same confirmation message as a registered
   email (to prevent account enumeration).

3. WHEN a user clicks an expired or already-used reset link
   THE SYSTEM SHALL display "This link has expired. Request a new one."

4. WHEN a user submits a new password via a valid reset link
   THE SYSTEM SHALL update the password, invalidate the reset token, and
   redirect to the login page.

---

### 4. Logout

**User Story:** As an authenticated user, I want to log out, so that my
session is terminated on this device.

#### Acceptance Criteria

1. WHEN a user clicks "Logout"
   THE SYSTEM SHALL invalidate the session token and redirect to the login page.

2. WHILE a session is invalidated
   THE SYSTEM SHALL reject any subsequent requests using the old token
   with a 401 response.
