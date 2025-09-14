# 📚 Git Repository Setup Guide

Hướng dẫn chi tiết để setup Git repository cho ProductAuth Microservice với best practices về security và configuration management.

## 🔧 Initial Git Setup

### 1. Initialize Git Repository
```bash
# Navigate to project directory
cd ProductAuthMicroservice

# Initialize git repository
git init

# Add remote origin (replace with your repository URL)
git remote add origin https://github.com/yourusername/ProductAuthMicroservice.git

# Verify remote
git remote -v
```

### 2. Verify .gitignore Configuration
```bash
# Check if .gitignore exists và includes security exclusions
cat .gitignore

# Verify important exclusions:
# ✅ appsettings.*.json (except Example)
# ✅ .env files (except .env.example)
# ✅ docker-compose.yml (except example)
# ✅ bin/, obj/, logs/
# ✅ *.user files
# ✅ certificates và keys
```

### 3. Setup Configuration Files
```bash
# Ensure example files are ready to commit
ls -la *.example*
ls -la src/*/appsettings.Example.json

# Check that sensitive files are excluded
git status --ignored

# Should NOT see:
# - appsettings.json
# - appsettings.Development.json
# - .env
# - docker-compose.yml (unless manually added)
```

## 🔒 Security Best Practices

### 1. Pre-commit Security Check
```bash
# Create security check script
cat > scripts/pre-commit-security-check.sh << 'EOF'
#!/bin/bash
echo "🔍 Running pre-commit security checks..."

# Check for sensitive data patterns
if git diff --cached | grep -i -E "(password|secret|key|token)" | grep -v -E "(Example|Template|placeholder)"; then
    echo "❌ WARNING: Potential sensitive data detected in staged changes!"
    echo "Please review the following matches:"
    git diff --cached | grep -i -E "(password|secret|key|token)" | grep -v -E "(Example|Template|placeholder)"
    echo "If this is intentional, commit with --no-verify flag"
    exit 1
fi

# Check for configuration files
if git diff --cached --name-only | grep -E "appsettings\.(json|Development\.json)$|\.env$|docker-compose\.yml$"; then
    echo "❌ WARNING: Configuration files detected in staged changes!"
    echo "Files:"
    git diff --cached --name-only | grep -E "appsettings\.(json|Development\.json)$|\.env$|docker-compose\.yml$"
    echo "Only commit .example files for configuration templates"
    exit 1
fi

echo "✅ Security checks passed!"
EOF

# Make script executable
chmod +x scripts/pre-commit-security-check.sh
```

### 2. Setup Git Hooks
```bash
# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run security check
./scripts/pre-commit-security-check.sh
EOF

# Make hook executable
chmod +x .git/hooks/pre-commit
```

### 3. Environment Variables Setup
```bash
# Ensure .env.example exists và contains all required variables
cat .env.example

# Create your actual .env file (NEVER commit this)
cp .env.example .env

# Update .env với your actual values
# Note: This file is in .gitignore và will not be committed
```

## 📝 Commit Message Conventions

### Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes
- `build`: Build system changes

### Examples
```bash
feat(auth): add Redis distributed caching for user sessions

- Implement RedisUserStateCache class
- Add Redis configuration in appsettings
- Update dependency injection for distributed cache
- Resolves cross-service authentication issues

Closes #123

---

fix(gateway): resolve middleware dependency injection scoping

- Change IUserStateCache from Scoped to Singleton
- Fix constructor dependency resolution in middleware
- Add proper error handling for cache failures

---

docs(readme): add comprehensive setup guide

- Add step-by-step Docker setup instructions
- Include configuration examples
- Add troubleshooting section
- Update API testing examples

---

refactor(product): improve query performance

- Add database indexes for frequently queried fields
- Optimize LINQ queries in ProductRepository
- Implement query result caching
- Reduce database roundtrips by 60%
```

## 🚀 First Commit Setup

### 1. Stage Template Files
```bash
# Add all template và example files
git add .env.example
git add docker-compose.example.yml
git add src/*/appsettings.Example.json
git add .gitignore

# Add documentation
git add README.md
git add COMPLETE_SETUP_GUIDE.md
git add GIT_SETUP_GUIDE.md

# Add source code (excluding sensitive configs)
git add src/
git add scripts/
git add *.sln
git add *.md

# Verify staged files don't contain sensitive data
git diff --cached --name-only
```

### 2. Verify No Sensitive Data
```bash
# Double-check staged content for sensitive information
git diff --cached | grep -i -E "(password|secret|key|token)" | grep -v -E "(Example|Template|placeholder|your_)"

# Should return empty result
# If any matches found, review và exclude those files
```

### 3. Make Initial Commit
```bash
# Initial commit
git commit -m "feat: initial project setup with distributed microservice architecture

- Add AuthService with JWT authentication and Redis caching
- Add ProductService with CQRS pattern and event sourcing
- Add Gateway with Ocelot and distributed authentication middleware
- Add PostgreSQL databases with EF Core migrations
- Add RabbitMQ event bus with transactional outbox pattern
- Add Redis distributed cache for cross-service session sharing
- Add Docker Compose orchestration with health checks
- Add comprehensive documentation and setup guides
- Add security-focused Git configuration with pre-commit hooks

Services:
- AuthService (Port 5001): User authentication and authorization
- ProductService (Port 5002): Product catalog and inventory
- Gateway (Port 5000): API Gateway with authentication
- PostgreSQL (Ports 5433, 5434): Separate databases per service
- Redis (Port 6379): Distributed cache for shared state
- RabbitMQ (Ports 5672, 15672): Message broker for events

Architecture:
- Clean Architecture with Domain-Driven Design
- CQRS with MediatR for command/query separation
- Event-driven communication with Saga choreography
- Distributed authentication with Redis state sharing
- Container-first deployment with Docker Compose"

# Push to remote repository
git push -u origin main
```

## 🔄 Development Workflow

### 1. Feature Development Workflow
```bash
# 1. Create feature branch
git checkout -b feature/user-profile-management

# 2. Make changes
# ... develop your feature ...

# 3. Stage changes (security check will run automatically)
git add .

# 4. Commit với proper message
git commit -m "feat(auth): add user profile management endpoints

- Add GetProfile, UpdateProfile, ChangePassword endpoints
- Implement profile validation with FluentValidation
- Add profile update events for audit logging
- Add comprehensive unit tests for profile operations

Breaking Changes: None
Closes #456"

# 5. Push feature branch
git push origin feature/user-profile-management

# 6. Create Pull Request on GitHub/GitLab
```

### 2. Hotfix Workflow
```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/auth-token-validation

# 2. Make fix
# ... implement fix ...

# 3. Commit fix
git commit -m "fix(auth): resolve JWT token validation edge case

- Handle null claims properly in token validation
- Add defensive programming for edge cases
- Improve error messages for invalid tokens
- Add unit tests for edge case scenarios

Fixes critical authentication bug affecting production users"

# 4. Push và create PR
git push origin hotfix/auth-token-validation
```

### 3. Configuration Updates Workflow
```bash
# When updating configuration examples:

# 1. Update example files only
git add src/AuthService/AuthService.API/appsettings.Example.json
git add docker-compose.example.yml
git add .env.example

# 2. Commit configuration updates
git commit -m "docs(config): update configuration examples for Redis clustering

- Add Redis cluster configuration options
- Update connection string examples for HA Redis
- Add new environment variables for cluster setup
- Update documentation for Redis cluster deployment"

# 3. Push changes
git push origin main
```

## 📋 Regular Maintenance

### 1. Security Audit
```bash
# Weekly security audit
echo "Running weekly security audit..."

# Check for accidentally committed sensitive files
git log --all --name-only | grep -E "appsettings\.(json|Development\.json)$|\.env$" | grep -v Example

# Check for sensitive data patterns trong commit history
git log --all -p | grep -i -E "(password|secret|key|token)" | grep -v -E "(Example|Template|placeholder|your_)"

# Scan for high-entropy strings (potential secrets)
git log --all -p | grep -E "[a-zA-Z0-9]{32,}"
```

### 2. Clean Up Old Branches
```bash
# List merged branches
git branch --merged main | grep -v main

# Delete merged feature branches
git branch --merged main | grep -v main | xargs -r git branch -d

# Clean up remote tracking branches
git remote prune origin
```

### 3. Update Documentation
```bash
# Regular documentation updates
git add README.md
git add COMPLETE_SETUP_GUIDE.md
git add docs/

git commit -m "docs: update setup guide with latest configuration options

- Add new Redis cluster configuration section
- Update troubleshooting guide với common issues
- Add performance optimization recommendations
- Update API examples với latest endpoints"
```

## 🔐 Advanced Security

### 1. Signed Commits
```bash
# Generate GPG key
gpg --full-generate-key

# Get key ID
gpg --list-secret-keys --keyid-format LONG

# Configure Git to use GPG key
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true

# Commit với signature
git commit -S -m "feat: add secure feature"
```

### 2. Repository Security Settings
```bash
# Enable these settings trong GitHub/GitLab:
# ✅ Require pull request reviews
# ✅ Require status checks to pass
# ✅ Require branches to be up to date
# ✅ Require signed commits
# ✅ Include administrators
# ✅ Restrict pushes that create files containing secrets
# ✅ Enable vulnerability alerts
# ✅ Enable automated security updates
```

### 3. Secrets Scanning
```bash
# Add GitHub secret scanning (automatically enabled)
# Or use tools like:

# TruffleHog for secret scanning
pip install truffleHog
trufflehog --regex --entropy=False .

# GitLeaks
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source="/path" -v
```

## 📊 Repository Health

### Health Check Script
```bash
# Create repository health check
cat > scripts/repo-health-check.sh << 'EOF'
#!/bin/bash
echo "🏥 Repository Health Check"
echo "========================"

# Check .gitignore effectiveness
echo "📝 Checking .gitignore..."
if git status --ignored | grep -E "(appsettings\.json|\.env|docker-compose\.yml)$"; then
    echo "⚠️  WARNING: Sensitive files found trong working directory!"
else
    echo "✅ No sensitive files trong working directory"
fi

# Check for large files
echo "📦 Checking for large files..."
find . -type f -size +10M | grep -v ".git" | head -5

# Check commit message format
echo "💬 Checking recent commit messages..."
git log --oneline -10 | while read commit; do
    if echo "$commit" | grep -E "^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore|perf|ci|build)\(.*\):"; then
        echo "✅ $commit"
    else
        echo "❌ $commit (format issue)"
    fi
done

# Check branch protection
echo "🛡️  Branch protection status: Check GitHub/GitLab settings manually"

echo "🎉 Health check complete!"
EOF

chmod +x scripts/repo-health-check.sh
```

---

## 🎯 Summary Checklist

Before pushing to production:

- [ ] ✅ .gitignore properly excludes sensitive files
- [ ] ✅ Only .example configuration files are committed
- [ ] ✅ Pre-commit hooks are working
- [ ] ✅ Commit messages follow convention
- [ ] ✅ No sensitive data trong commit history
- [ ] ✅ Documentation is up to date
- [ ] ✅ Branch protection rules are enabled
- [ ] ✅ Security scanning is configured
- [ ] ✅ All tests pass
- [ ] ✅ Code review is completed

**🚀 Your repository is now secure và ready for collaborative development!**