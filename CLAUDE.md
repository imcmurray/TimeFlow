# TimeFlow Project Instructions

## Playwright Testing - USE DOCKER! (CRITICAL)

DO NOT try to install Playwright browsers locally. This project is configured to run Playwright tests in a Docker container.

### Running E2E Tests

```bash
# Use the provided script - handles everything automatically
./run-tests.sh

# Or use Docker Compose directly
docker-compose run --rm playwright npm test

# Run specific test file
docker-compose run --rm playwright npm test tests/example.spec.js

# Open shell in container for debugging
./run-tests.sh shell
```

### What NOT to Do

- ❌ `npx playwright install` - Don't install browsers locally
- ❌ `apt-get install` browser dependencies - Not needed
- ❌ Fighting with missing browser/dependency errors - Use Docker instead

### Why Docker?

The Docker container (`mcr.microsoft.com/playwright:v1.48.0-jammy`) comes with all browsers and dependencies pre-installed. No setup required.

See `PLAYWRIGHT.md` for full documentation.

