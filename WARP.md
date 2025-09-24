# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Node.js Express application called "Acquisitions" that demonstrates modern full-stack architecture with Docker containerization, Neon database integration, and comprehensive security middleware. The app features a complete authentication system with JWT tokens and role-based access control.

## Key Technologies
- **Runtime**: Node.js 20 with ES modules
- **Framework**: Express.js 5.1.0
- **Database**: PostgreSQL via Neon (serverless/cloud and local development)
- **ORM**: Drizzle ORM with migrations
- **Authentication**: JWT with httpOnly cookies, bcrypt password hashing
- **Security**: Helmet, CORS, Arcjet protection, security middleware
- **Logging**: Winston logger with Morgan HTTP logging
- **Validation**: Zod schemas
- **Containerization**: Docker with separate dev/prod configurations

## Architecture Overview

### Layered Architecture
The codebase follows a clean layered architecture:

```
src/
├── index.js          # Application entry point (loads env, starts server)
├── server.js         # Server setup and port binding
├── app.js            # Express app configuration and middleware setup
├── config/           # Configuration modules (database, logger, arcjet)
├── controllers/      # HTTP request handlers (auth, users)
├── services/         # Business logic layer (auth, users)
├── routes/           # API route definitions
├── middleware/       # Custom middleware (security)
├── models/           # Drizzle ORM database schemas
├── utils/            # Utility functions (JWT, cookies, formatting)
└── validations/      # Zod validation schemas
```

### Database Architecture
- **Development**: Uses Neon Local proxy that creates ephemeral branches for clean testing
- **Production**: Direct connection to Neon Cloud (PostgreSQL)
- **ORM**: Drizzle with type-safe queries and migrations
- **Models**: Currently has User model with authentication fields

### Security Architecture
- **Input Validation**: Zod schemas validate all incoming data
- **Authentication**: JWT tokens stored in httpOnly cookies
- **Password Security**: bcrypt hashing with salt rounds
- **HTTP Security**: Helmet for security headers, CORS configuration
- **Rate Limiting**: Arcjet integration for DDoS protection
- **Container Security**: Non-root user, read-only filesystem in production

## Development Commands

### Docker Development (Recommended)
```powershell
# Start development environment with Neon Local
.\start-dev.ps1

# Or manually:
docker-compose --env-file .env.development -f docker-compose.dev.yml up --build

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop services
docker-compose -f docker-compose.dev.yml down

# Execute commands in running container
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

### Local Development (Without Docker)
```bash
npm run dev          # Start with --watch flag for hot reload
npm start            # Production start
npm run lint         # ESLint code analysis
npm run lint:fix     # Auto-fix linting issues
npm run format       # Format code with Prettier
npm run format:check # Check formatting
```

### Database Commands
```bash
# Generate new migration from schema changes
npm run db:generate

# Apply migrations (development)
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Apply migrations (production)  
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate

# Open Drizzle Studio (database GUI)
npm run db:studio
```

### Production Deployment
```bash
# Deploy to production with Neon Cloud
docker-compose --env-file .env.prod.local -f docker-compose.prod.yml up -d --build

# Scale application
docker-compose -f docker-compose.prod.yml up -d --scale app=3

# View production logs
docker-compose -f docker-compose.prod.yml logs -f app
```

## Code Organization Patterns

### Path Aliases
The project uses Node.js subpath imports for clean imports:
- `#config/*` → `./src/config/*`
- `#controllers/*` → `./src/controllers/*`
- `#middleware/*` → `./src/middleware/*`
- `#models/*` → `./src/models/*`
- `#routes/*` → `./src/routes/*`
- `#services/*` → `./src/services/*`
- `#utils/*` → `./src/utils/*`
- `#validations/*` → `./src/validations/*`

### Controller Pattern
Controllers are thin HTTP handlers that:
1. Validate input using Zod schemas
2. Call service layer for business logic
3. Handle errors and format responses
4. Set authentication cookies when needed

### Service Pattern
Services contain business logic and:
- Interact with database through Drizzle ORM
- Handle password hashing/comparison
- Manage user creation and authentication
- Use structured logging

### Database Migrations
1. Modify schema in `src/models/*.js`
2. Generate migration: `npm run db:generate`
3. Apply migration: `npm run db:migrate`

## Environment Configuration

### Development (.env.development)
- `NEON_API_KEY`: Neon API key for local branch creation
- `NEON_PROJECT_ID`: Your Neon project ID
- `PARENT_BRANCH_ID`: Branch to create ephemeral branches from
- `JWT_SECRET`: Development JWT signing secret
- `COOKIE_SECRET`: Development cookie signing secret
- `DATABASE_URL`: Auto-configured to use neon-local:5432

### Production (.env.production)
- `DATABASE_URL`: Full Neon Cloud connection string
- `JWT_SECRET`: Production JWT secret (must be different from dev)
- `COOKIE_SECRET`: Production cookie secret
- `ARCJET_KEY`: Arcjet protection key
- `CORS_ORIGIN`: Production domain for CORS

## API Structure

### Authentication Endpoints
- `POST /api/auth/sign-up` - User registration
- `POST /api/auth/sign-in` - User login
- `POST /api/auth/sign-out` - User logout

### User Endpoints
- `GET /api/users` - Fetch all users
- `GET /api/users/:id` - Get user by ID (placeholder)
- `PUT /api/users/:id` - Update user (placeholder)
- `DELETE /api/users/:id` - Delete user (placeholder)

### Utility Endpoints
- `GET /` - Basic health check
- `GET /health` - Detailed health status
- `GET /api` - API status

## Development Workflow

### Database Development
The development environment uses Neon Local which creates ephemeral database branches. Each container restart gives you a fresh database state, perfect for testing migrations and schema changes.

### Hot Reload
When using Docker development mode, source code is mounted as a volume, and the app runs with `--watch` flag for automatic restarts on file changes.

### Security Testing
The application includes comprehensive security middleware. Test security features by:
1. Attempting requests without authentication
2. Testing rate limiting with repeated requests
3. Validating input sanitization with malicious payloads

## Troubleshooting

### Neon Local Issues
- Ensure your `NEON_API_KEY`, `NEON_PROJECT_ID`, and `PARENT_BRANCH_ID` are correct
- Check that port 5432 isn't already in use
- Wait for healthcheck to pass before app starts

### Database Connection Issues
- Development: App connects to `neon-local:5432` within Docker network
- Production: Verify your Neon Cloud `DATABASE_URL` is complete and valid
- Check database logs: `docker-compose logs neon-local`

### Authentication Issues
- JWT secrets must be set in environment variables
- Cookies are httpOnly and require proper domain configuration
- Check token expiration and refresh logic

## Code Quality Standards

### Linting and Formatting
- ESLint configured with Prettier integration
- Use `npm run lint:fix` before commits
- Format code with `npm run format`

### Error Handling
- All async operations wrapped in try-catch
- Structured error logging with Winston
- Consistent error response formats
- Service layer throws errors, controllers handle them

### Database Queries
- Use Drizzle ORM type-safe queries
- Normalize email addresses before database operations
- Never return password fields in API responses
- Use database transactions for multi-step operations