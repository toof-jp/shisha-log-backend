# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the backend service for the Shisha Log application. The project uses Supabase for database management and authentication.

## Development Setup

### Supabase Setup
- Install Supabase CLI: `npm install -g supabase`
- Initialize Supabase: `supabase init`
- Link to Supabase project: `supabase link --project-ref <project-ref>`
- Run migrations: `supabase db push`
- Generate types: `supabase gen types typescript --local > types/supabase.ts`

### Backend Development

The backend is implemented in Go using the Echo framework.

#### Commands:
- **Install dependencies**: `go mod download`
- **Run development server**: `make dev` (with hot reload) or `make run` (without hot reload)
- **Run tests**: `make test` or `go test -v ./...`
- **Linting and formatting**: `make fmt` and `make lint`
- **Build for production**: `make build`

#### Environment Variables:
- `PORT`: Server port (default: 8080)
- `ENVIRONMENT`: Environment (development/production)
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key
- `JWT_SECRET`: Secret for JWT validation
- `ALLOWED_ORIGINS`: Comma-separated list of allowed CORS origins
- `DATABASE_URL`: Direct database connection URL (required for authentication)
- `TOKEN_DURATION`: JWT token expiration duration (default: 24h)

## Architecture Notes

### Database Management
- **Supabase**: Used for database hosting and real-time subscriptions
- **Direct PostgreSQL**: Used for authentication data
- Database migrations are managed through Supabase CLI
- Use Supabase client libraries for session/profile data
- Use direct PostgreSQL connection for authentication data

### Database Schema

#### Authentication Tables (User ID + Password)
- **users**: User accounts (id, user_id, password_hash, display_name, created_at, updated_at)
- **password_reset_tokens**: Password reset tokens (id, user_id, token, expires_at, used, created_at)

#### Application Tables
- **profiles**: User profiles (id, display_name, created_at, updated_at)
- **shisha_sessions**: Session records (id, user_id, created_by, session_date, store_name, notes, order_details, mix_name, created_at, updated_at)
- **session_flavors**: Flavors used in each session (id, session_id, flavor_name, brand, created_at)

### Key Considerations
- **Web Framework**: Echo (Go)
- **API Design**: RESTful API
- **Authentication**: User ID and password-based authentication
- **Session Management**: JWT tokens with configurable expiration
- **Database Access**: Hybrid approach - Direct PostgreSQL for auth, Supabase client for application data
- **Security**: Bcrypt password hashing, password reset flow, unique user IDs