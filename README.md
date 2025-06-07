# Shisha Log Backend

Backend service for the Shisha Log application with Passkey (WebAuthn) authentication.

## Requirements

- Go 1.21+
- PostgreSQL database (via Supabase)
- Supabase CLI
- Make (optional)

## Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and fill in your credentials
3. Set up the database:
   ```bash
   # Install Supabase CLI
   npm install -g supabase
   
   # Link to your Supabase project
   supabase link --project-ref <your-project-ref>
   
   # Run the Passkey authentication migration
   supabase db push supabase/migrations/20250106_initial_schema_passkey.sql
   ```
4. Install dependencies:
   ```bash
   go mod download
   ```

## Development

Run the server with hot reload:
```bash
# Install air for hot reload
go install github.com/air-verse/air@latest

# Run with hot reload
make dev
# or
air
```

Run the server without hot reload:
```bash
make run
# or
go run cmd/server/main.go
```

## Build

```bash
make build
# or
go build -o bin/server cmd/server/main.go
```

## API Endpoints

### Health Check
- `GET /health` - Returns server status

### Profile Endpoints (Protected)
- `GET /api/v1/profile` - Get user profile
- `POST /api/v1/profile` - Create user profile
- `PUT /api/v1/profile` - Update user profile

### Session Endpoints (Protected)
- `POST /api/v1/sessions` - Create a new session
- `GET /api/v1/sessions` - Get user sessions (with pagination)
- `GET /api/v1/sessions/:id` - Get a specific session
- `PUT /api/v1/sessions/:id` - Update a session
- `DELETE /api/v1/sessions/:id` - Delete a session

## Authentication

The application uses Passkey (WebAuthn) for passwordless authentication.

### Authentication Flow
1. **Registration**: Users register with a username and create a Passkey
2. **Login**: Users authenticate using their registered Passkey
3. **Token**: Upon successful authentication, users receive a JWT token
4. **API Access**: Use the JWT token in the Authorization header for protected endpoints

```
Authorization: Bearer <your-jwt-token>
```

### Authentication Endpoints
- `POST /api/v1/auth/register/begin` - Start registration
- `POST /api/v1/auth/register/finish` - Complete registration
- `POST /api/v1/auth/login/begin` - Start login
- `POST /api/v1/auth/login/finish` - Complete login
- `GET /api/v1/auth/credentials` - List user credentials (protected)
- `DELETE /api/v1/auth/credentials/:id` - Delete credential (protected)

## Project Structure

```
.
├── cmd/
│   └── server/         # Application entrypoint
├── internal/
│   ├── api/           # HTTP handlers
│   ├── auth/          # Authentication middleware
│   ├── config/        # Configuration management
│   ├── models/        # Data models
│   ├── repository/    # Database access layer
│   └── service/       # Business logic services
├── pkg/              # Reusable packages
└── supabase/         # Supabase migrations and config
```