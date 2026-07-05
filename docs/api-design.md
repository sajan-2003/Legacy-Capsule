# Legacy Capsule — API Design

Base URL: `https://api.legacycapsule.app/v1`

All endpoints (except where noted) require header: `Authorization: Bearer <token>`

---

## 1. Authentication

### 1.1 Register
- **Method:** POST
- **Endpoint:** `/auth/register`
- **Description:** Creates a new user account.
- **Auth:** None
- **Request:**
```json
{
  "email": "user@example.com",
  "password": "StrongPass123!",
  "display_name": "Jane Doe"
}
```
- **Response:**
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "token": "jwt-token",
  "created_at": "2026-07-05T10:00:00Z"
}
```
- **Status Codes:** `201 Created`, `400 Bad Request`, `409 Conflict (email exists)`

### 1.2 Login
- **Method:** POST
- **Endpoint:** `/auth/login`
- **Description:** Authenticates a user and returns a session token.
- **Auth:** None
- **Request:** `{ "email": "user@example.com", "password": "StrongPass123!" }`
- **Response:** `{ "token": "jwt-token", "refresh_token": "refresh-jwt", "expires_in": 3600 }`
- **Status Codes:** `200 OK`, `401 Unauthorized`

### 1.3 Refresh Token
- **Method:** POST
- **Endpoint:** `/auth/refresh`
- **Description:** Issues a new access token using a valid refresh token.
- **Auth:** Refresh token in body
- **Request:** `{ "refresh_token": "refresh-jwt" }`
- **Response:** `{ "token": "new-jwt-token", "expires_in": 3600 }`
- **Status Codes:** `200 OK`, `401 Unauthorized`

---

## 2. Capsules

### 2.1 Create Capsule
- **Method:** POST
- **Endpoint:** `/capsules`
- **Description:** Creates a new capsule.
- **Auth:** Required
- **Request:**
```json
{
  "title": "For my daughter's 18th birthday",
  "description": "A letter and photos",
  "unlock_at": "2040-05-01T00:00:00Z",
  "unlock_event_type": "date"
}
```
- **Response:** `{ "capsule_id": "uuid", "status": "locked", "created_at": "2026-07-05T10:05:00Z" }`
- **Status Codes:** `201 Created`, `400 Bad Request`, `401 Unauthorized`

### 2.2 Get Capsule
- **Method:** GET
- **Endpoint:** `/capsules/{capsule_id}`
- **Description:** Retrieves capsule metadata (content withheld if still locked).
- **Auth:** Required (owner or authorized recipient)
- **Response:** `{ "capsule_id": "uuid", "title": "...", "status": "locked", "unlock_at": "2040-05-01T00:00:00Z" }`
- **Status Codes:** `200 OK`, `403 Forbidden`, `404 Not Found`

### 2.3 List Capsules
- **Method:** GET
- **Endpoint:** `/capsules?status=locked&page=1&limit=20`
- **Description:** Lists capsules owned by the authenticated user.
- **Auth:** Required
- **Response:** `{ "capsules": [ { "capsule_id": "uuid", "title": "..." } ], "page": 1, "total": 42 }`
- **Status Codes:** `200 OK`

### 2.4 Update Capsule
- **Method:** PATCH
- **Endpoint:** `/capsules/{capsule_id}`
- **Description:** Updates capsule metadata (only permitted while unlocked/unsealed).
- **Auth:** Required (owner)
- **Request:** `{ "title": "Updated title" }`
- **Response:** `{ "capsule_id": "uuid", "title": "Updated title", "updated_at": "..." }`
- **Status Codes:** `200 OK`, `403 Forbidden`, `404 Not Found`

### 2.5 Delete Capsule
- **Method:** DELETE
- **Endpoint:** `/capsules/{capsule_id}`
- **Description:** Permanently deletes a capsule and its memories.
- **Auth:** Required (owner)
- **Response:** `{ "message": "Capsule deleted" }`
- **Status Codes:** `200 OK`, `403 Forbidden`, `404 Not Found`

---

## 3. Memories

### 3.1 Add Memory to Capsule
- **Method:** POST
- **Endpoint:** `/capsules/{capsule_id}/memories`
- **Description:** Adds a memory (text/photo/video/audio/document) to a capsule.
- **Auth:** Required (owner)
- **Request:**
```json
{
  "type": "text",
  "content_text": "Dear Emma, on your 18th birthday...",
  "tags": ["birthday", "letter"]
}
```
- **Response:** `{ "memory_id": "uuid", "capsule_id": "uuid", "created_at": "..." }`
- **Status Codes:** `201 Created`, `400 Bad Request`, `403 Forbidden`

### 3.2 Get Memory
- **Method:** GET
- **Endpoint:** `/memories/{memory_id}`
- **Description:** Retrieves a single memory (subject to capsule lock status).
- **Auth:** Required
- **Response:** `{ "memory_id": "uuid", "type": "text", "content_text": "...", "tags": [...] }`
- **Status Codes:** `200 OK`, `403 Forbidden`, `423 Locked`

### 3.3 Delete Memory
- **Method:** DELETE
- **Endpoint:** `/memories/{memory_id}`
- **Description:** Deletes a memory from its capsule.
- **Auth:** Required (owner)
- **Response:** `{ "message": "Memory deleted" }`
- **Status Codes:** `200 OK`, `403 Forbidden`, `404 Not Found`

---

## 4. Community

### 4.1 Create Community
- **Method:** POST
- **Endpoint:** `/communities`
- **Description:** Creates a new community space.
- **Auth:** Required (premium for private communities)
- **Request:** `{ "name": "Smith Family Archive", "privacy_level": "private" }`
- **Response:** `{ "community_id": "uuid", "name": "Smith Family Archive" }`
- **Status Codes:** `201 Created`, `403 Forbidden`

### 4.2 Join Community
- **Method:** POST
- **Endpoint:** `/communities/{community_id}/join`
- **Description:** Requests to join a community.
- **Auth:** Required
- **Response:** `{ "status": "pending" }`
- **Status Codes:** `202 Accepted`, `404 Not Found`

### 4.3 List Community Members
- **Method:** GET
- **Endpoint:** `/communities/{community_id}/members`
- **Description:** Lists all approved members of a community.
- **Auth:** Required (member)
- **Response:** `{ "members": [ { "user_id": "uuid", "role": "admin" } ] }`
- **Status Codes:** `200 OK`, `403 Forbidden`

---

## 5. Friends

### 5.1 Send Friend Request
- **Method:** POST
- **Endpoint:** `/friends/requests`
- **Description:** Sends a trusted-contact request to another user.
- **Auth:** Required
- **Request:** `{ "target_user_id": "uuid" }`
- **Response:** `{ "request_id": "uuid", "status": "pending" }`
- **Status Codes:** `201 Created`, `409 Conflict`

### 5.2 Accept Friend Request
- **Method:** POST
- **Endpoint:** `/friends/requests/{request_id}/accept`
- **Description:** Accepts a pending trusted-contact request.
- **Auth:** Required (recipient)
- **Response:** `{ "friend_id": "uuid", "status": "accepted" }`
- **Status Codes:** `200 OK`, `404 Not Found`

### 5.3 Designate Successor
- **Method:** POST
- **Endpoint:** `/friends/{friend_id}/successor`
- **Description:** Marks a trusted contact as a legacy successor.
- **Auth:** Required
- **Request:** `{ "is_successor": true }`
- **Response:** `{ "friend_id": "uuid", "is_successor": true }`
- **Status Codes:** `200 OK`, `403 Forbidden`

---

## 6. Chat

### 6.1 Send Message
- **Method:** POST
- **Endpoint:** `/messages`
- **Description:** Sends a chat message to a user or community.
- **Auth:** Required
- **Request:** `{ "recipient_type": "community", "recipient_id": "uuid", "content": "Welcome to the archive!" }`
- **Response:** `{ "message_id": "uuid", "sent_at": "..." }`
- **Status Codes:** `201 Created`, `403 Forbidden`

### 6.2 Get Message History
- **Method:** GET
- **Endpoint:** `/messages?community_id={id}&page=1`
- **Description:** Retrieves paginated chat history.
- **Auth:** Required (member)
- **Response:** `{ "messages": [ { "message_id": "uuid", "content": "...", "sent_at": "..." } ] }`
- **Status Codes:** `200 OK`, `403 Forbidden`

---

## 7. Notifications

### 7.1 List Notifications
- **Method:** GET
- **Endpoint:** `/notifications?unread_only=true`
- **Description:** Lists notifications for the authenticated user.
- **Auth:** Required
- **Response:** `{ "notifications": [ { "id": "uuid", "type": "capsule_unlocked", "is_read": false } ] }`
- **Status Codes:** `200 OK`

### 7.2 Mark Notification as Read
- **Method:** PATCH
- **Endpoint:** `/notifications/{id}/read`
- **Description:** Marks a specific notification as read.
- **Auth:** Required
- **Response:** `{ "id": "uuid", "is_read": true }`
- **Status Codes:** `200 OK`, `404 Not Found`

---

## 8. Profile

### 8.1 Get Profile
- **Method:** GET
- **Endpoint:** `/profile/me`
- **Description:** Retrieves the authenticated user's profile.
- **Auth:** Required
- **Response:** `{ "user_id": "uuid", "display_name": "Jane Doe", "avatar_url": "https://..." }`
- **Status Codes:** `200 OK`

### 8.2 Update Profile
- **Method:** PATCH
- **Endpoint:** `/profile/me`
- **Description:** Updates the authenticated user's profile.
- **Auth:** Required
- **Request:** `{ "display_name": "Jane A. Doe" }`
- **Response:** `{ "user_id": "uuid", "display_name": "Jane A. Doe" }`
- **Status Codes:** `200 OK`, `400 Bad Request`

---

## 9. Media Upload

### 9.1 Request Upload URL
- **Method:** POST
- **Endpoint:** `/media/upload-url`
- **Description:** Generates a signed URL for direct client-to-storage upload.
- **Auth:** Required
- **Request:** `{ "file_type": "image/jpeg", "file_size_bytes": 2048000 }`
- **Response:** `{ "upload_url": "https://storage.../signed", "media_id": "uuid", "expires_in": 300 }`
- **Status Codes:** `200 OK`, `413 Payload Too Large`

### 9.2 Confirm Upload
- **Method:** POST
- **Endpoint:** `/media/{media_id}/confirm`
- **Description:** Confirms a completed upload and links it to a memory.
- **Auth:** Required
- **Request:** `{ "memory_id": "uuid", "checksum": "sha256-hash" }`
- **Response:** `{ "media_id": "uuid", "status": "confirmed", "file_url": "https://..." }`
- **Status Codes:** `200 OK`, `400 Bad Request`, `409 Conflict (checksum mismatch)`

---

## Standard Error Format

```json
{
  "error": {
    "code": "CAPSULE_LOCKED",
    "message": "This capsule cannot be accessed until its unlock date.",
    "status": 423
  }
}
```

## Common Status Codes

| Code | Meaning |
|---|---|
| 200 | OK |
| 201 | Created |
| 202 | Accepted (async processing) |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 413 | Payload Too Large |
| 423 | Locked (time-locked capsule) |
| 429 | Too Many Requests |
| 500 | Internal Server Error |
