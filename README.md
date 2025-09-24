# Acquisitions App - Docker Setup with Neon Database

A Node.js Express application with Drizzle ORM, configured to work with both Neon Local (development) and Neon Cloud (production) databases using Docker.

## 📋 Prerequisites

- Docker and Docker Compose installed
- Neon account and project set up
- Node.js 20+ (for local development without Docker)

## 🏗️ Architecture Overview

This setup provides two distinct environments:

### Development Environment
- **Neon Local**: Uses a Docker proxy that creates ephemeral database branches
- **Fresh Database**: Each container restart gives you a clean database state
- **Local Network**: Application connects to `neon-local:5432` within Docker network
- **Automatic Cleanup**: Database branches are deleted when containers stop

### Production Environment
- **Neon Cloud**: Direct connection to your production Neon database
- **Persistent Data**: Uses your actual production database
- **Security Hardened**: Read-only filesystem, non-root user, resource limits
- **Health Checks**: Built-in health monitoring

## 🚀 Quick Start

### Development Setup

1. **Clone and navigate to the project:**
   ```bash
   git clone <your-repo-url>
   cd acquisitions
   ```

2. **Update your development environment file:**
   Edit `.env.development` with your actual Neon credentials:
   ```bash
   # Get these from your Neon Console (https://console.neon.com)
   NEON_API_KEY=napi_your_actual_api_key_here
   NEON_PROJECT_ID=your_actual_project_id_here
   PARENT_BRANCH_ID=br_your_actual_branch_id_here
   
   # Application secrets (generate secure values)
   JWT_SECRET=your_development_jwt_secret
   COOKIE_SECRET=your_development_cookie_secret
   ```

3. **Start the development environment (Easy Mode):**
   
   **Windows (PowerShell):**
   ```powershell
   .\start-dev.ps1
   ```
   
   **Linux/Mac (Bash):**
   ```bash
   chmod +x start-dev.sh
   ./start-dev.sh
   ```

4. **Or start manually:**
   ```bash
   docker-compose --env-file .env.development -f docker-compose.dev.yml up --build
   ```

5. **Access your application:**
   - Application: http://localhost:3002
   - Health check: http://localhost:3002/health
   - API: http://localhost:3002/api

6. **Run database migrations (if needed):**
   ```bash
   docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
   ```

### Production Setup

1. **Create your production environment file:**
   ```bash
   cp .env.production .env.prod.local
   ```

2. **Edit `.env.prod.local` with your production values:**
   ```bash
   # Your actual Neon Cloud database URL (from Neon Console)
   DATABASE_URL=postgres://username:password@ep-cool-darkness-123456.us-east-1.aws.neon.tech/dbname?sslmode=require
   
   # Generate secure production secrets
   JWT_SECRET=your_secure_production_jwt_secret_here
   COOKIE_SECRET=your_secure_production_cookie_secret_here
   ARCJET_KEY=your_production_arcjet_key_here
   CORS_ORIGIN=https://your-production-domain.com
   ```

3. **Deploy to production:**
   ```bash
   docker-compose --env-file .env.prod.local -f docker-compose.prod.yml up -d --build
   ```

## 📁 Project Structure

```
acquisitions/
├── src/                          # Application source code
│   ├── app.js                   # Express app configuration
│   ├── server.js                # Server setup
│   └── index.js                 # Application entry point
├── Dockerfile                   # Production-ready Docker image
├── docker-compose.dev.yml       # Development with Neon Local
├── docker-compose.prod.yml      # Production with Neon Cloud
├── .env.development             # Development environment with your credentials
├── .env.production              # Production environment template
├── start-dev.ps1               # Windows PowerShell startup script
├── start-dev.sh                # Linux/Mac Bash startup script
├── drizzle.config.js           # Database ORM configuration
├── package.json                # Node.js dependencies and scripts
└── README.md                   # This file
```

## 🔧 Environment Variables

### Required for Development (.env.development)
- `NEON_API_KEY`: Your Neon API key from the console
- `NEON_PROJECT_ID`: Your Neon project ID
- `PARENT_BRANCH_ID`: The branch to create ephemeral branches from
- `JWT_SECRET`: Secret for JWT token signing
- `COOKIE_SECRET`: Secret for cookie signing

### Required for Production (.env.production)
- `DATABASE_URL`: Your full Neon Cloud database connection string
- `JWT_SECRET`: Production JWT secret (different from development)
- `COOKIE_SECRET`: Production cookie secret
- `CORS_ORIGIN`: Your production domain

### Optional Environment Variables
- `PORT`: Application port (default: 3002)
- `LOG_LEVEL`: Logging level (development: debug, production: info)
- `NODE_ENV`: Environment mode (set automatically)

## 🛠️ Common Commands

### Development Commands

```bash
# Easy startup (recommended)
./start-dev.ps1          # Windows PowerShell
./start-dev.sh           # Linux/Mac

# Manual startup
docker-compose --env-file .env.development -f docker-compose.dev.yml up --build

# Run in background
docker-compose --env-file .env.development -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop services
docker-compose -f docker-compose.dev.yml down

# Execute commands in app container
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

### Production Commands

```bash
# Deploy to production
docker-compose --env-file .env.prod.local -f docker-compose.prod.yml up -d --build

# View production logs
docker-compose -f docker-compose.prod.yml logs -f app

# Scale the application (if needed)
docker-compose -f docker-compose.prod.yml up -d --scale app=3

# Update production deployment
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d --build
```

### Database Commands

```bash
# Generate database migrations
npm run db:generate

# Apply migrations (development)
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Apply migrations (production)
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate

# Open Drizzle Studio (development)
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

## 🔍 Troubleshooting

### Development Issues

**Neon Local container won't start:**
- Verify your `NEON_API_KEY`, `NEON_PROJECT_ID`, and `PARENT_BRANCH_ID` are correct
- Check if port 5432 is already in use: `netstat -an | grep 5432`
- Ensure your API key has the required permissions

**App can't connect to database:**
- Wait for the Neon Local healthcheck to pass (check with `docker-compose logs neon-local`)
- Verify the `DATABASE_URL` in development uses `neon-local` as the hostname
- Check that both services are on the same Docker network

**SSL/TLS connection issues:**
- The Neon Local proxy uses self-signed certificates
- Ensure `sslmode=require` is in your connection string
- For Node.js apps, you might need `ssl: { rejectUnauthorized: false }` in your database config

### Production Issues

**Can't connect to Neon Cloud:**
- Verify your `DATABASE_URL` is correct and complete
- Ensure your Neon project allows connections from your deployment IP
- Check that your database exists and credentials are valid

**Health checks failing:**
- Verify the `/health` endpoint is accessible
- Check application logs: `docker-compose -f docker-compose.prod.yml logs app`
- Ensure the database connection is established

### General Docker Issues

**Build failures:**
- Clear Docker cache: `docker system prune -a`
- Ensure all files are properly copied (check `.dockerignore`)
- Verify Node.js version compatibility

**Permission issues:**
- On Linux/Mac, ensure proper file permissions
- Check that the `nodejs` user can access required directories

## 📊 Database Schema Management

This project uses Drizzle ORM for database management:

1. **Make schema changes** in `src/models/*.js`
2. **Generate migrations:** `npm run db:generate`
3. **Apply migrations:**
   - Development: `docker-compose -f docker-compose.dev.yml exec app npm run db:migrate`
   - Production: `docker-compose -f docker-compose.prod.yml exec app npm run db:migrate`

## 🔒 Security Best Practices

### Development
- Never commit `.env` files with real credentials
- Use different secrets for development and production
- Neon Local creates isolated, ephemeral branches

### Production
- Use strong, randomly generated secrets
- Enable HTTPS in production (consider adding nginx reverse proxy)
- Regularly rotate API keys and secrets
- Monitor database access logs in Neon Console
- Use Neon's branch-based development workflow

## 🚀 Deployment Options

### Local Development
- Use `docker-compose.dev.yml` with Neon Local
- Automatic database branch management
- Hot reload with volume mounts

### Production Deployment Options
1. **Docker Compose** (single server)
2. **Docker Swarm** (multi-server)
3. **Kubernetes** (adapt the compose files)
4. **Cloud Platforms** (AWS ECS, Google Cloud Run, etc.)

## 📚 Additional Resources

- [Neon Documentation](https://neon.com/docs)
- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Drizzle ORM Documentation](https://orm.drizzle.team/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Docker and application logs
3. Verify all environment variables are set correctly
4. Consult the Neon documentation for database-specific issues

---

**Happy coding! 🎉**