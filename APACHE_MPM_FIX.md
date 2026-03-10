# Apache MPM Conflict Fix - Summary

## Problem
The application was failing with the error:
```
AH00534: apache2: Configuration error: More than one MPM loaded.
```

This occurred because the `php:8.0-apache` Docker image had both `mpm_event` and `mpm_prefork` modules loaded simultaneously, which is not allowed by Apache.

## Root Cause
1. The PHP Apache base image may automatically enable `mpm_prefork` when PHP is installed
2. The `mpm_event` module might also be enabled by default
3. The previous approach of just running `a2dismod mpm_event` wasn't sufficient because:
   - It ran after modules might already be enabled
   - It didn't handle the case where both were already enabled
   - Changes weren't applied before Apache started

## Solution
A multi-layered approach was implemented:

### 1. Build-Time Fix (Dockerfile)
**File:** `Dockerfile` (lines 41-45)

**Before:**
```dockerfile
RUN a2enmod rewrite headers \
    && a2dismod mpm_event 2>/dev/null || true
```

**After:**
```dockerfile
# Disable ALL MPMs first, then enable ONLY mpm_prefork (required for mod_php)
RUN a2dismod mpm_event mpm_prefork mpm_worker 2>/dev/null || true \
    && a2enmod mpm_prefork \
    && a2enmod rewrite headers
```

**Why this works:**
- Explicitly disables ALL MPM modules first (event, prefork, worker)
- Then enables ONLY `mpm_prefork`, which is required for mod_php
- The `|| true` ensures the command doesn't fail if modules aren't enabled

### 2. Runtime Fix (start.sh)
**File:** `start.sh` (lines 12-18)

**Added MPM configuration before starting Apache:**
```bash
# Fix Apache MPM configuration BEFORE starting Apache
echo -e "${YELLOW}Fixing Apache MPM configuration...${NC}"
echo "Disabling all MPMs..."
a2dismod mpm_event mpm_prefork mpm_worker 2>/dev/null || true
echo "Enabling mpm_prefork (required for PHP)..."
a2enmod mpm_prefork
echo -e "${GREEN}Apache MPM configuration fixed.${NC}"
```

**Why this works:**
- Fixes MPM configuration at runtime as a safety net
- Runs BEFORE Apache starts, ensuring configuration is correct
- Same strategy as build-time: disable all, then enable only prefork

### 3. Container Startup Flow
**Updated Dockerfile (lines 77-90):**
```dockerfile
# Copy startup scripts
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY start.sh /usr/local/bin/start.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/start.sh

# Expose port 80 for HTTP
EXPOSE 80

# Set entrypoint and command
ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD []
```

**Updated start.sh flow:**
1. Fix MPM configuration (disable all, enable prefork)
2. Run database setup via `docker-entrypoint.sh`
3. Start Apache in foreground with `exec apache2-foreground`

### 4. Additional Safety (docker-entrypoint.sh)
**File:** `docker-entrypoint.sh` (lines 25-36)

**Enhanced MPM checking:**
```bash
# Fix Apache MPM conflict - ensure only mpm_prefork is loaded
echo -e "${YELLOW}Checking Apache MPM configuration...${NC}"
MPM_LOADED=$(ls /etc/apache2/mods-enabled/mpm_*.load 2>/dev/null | wc -l)

if [ "$MPM_LOADED" -gt 1 ]; then
    echo -e "${RED}Multiple MPMs detected ($MPM_LOADED). Fixing MPM conflict...${NC}"
    echo "Disabling all MPMs..."
    a2dismod mpm_event mpm_prefork mpm_worker 2>/dev/null || true
    echo "Enabling mpm_prefork (required for PHP)..."
    a2enmod mpm_prefork
    echo -e "${GREEN}MPM conflict resolved. Only mpm_prefork is now enabled.${NC}"
else
    echo -e "${GREEN}MPM configuration is correct ($MPM_LOADED MPM loaded).${NC}"
fi
```

**Why this works:**
- Active detection of MPM conflicts at runtime
- Only fixes if multiple MPMs are detected
- Provides clear feedback about what's happening

## Files Changed

1. **Dockerfile**
   - Lines 41-45: Updated MPM configuration at build time
   - Lines 77-90: Added script copying and proper ENTRYPOINT/CMD setup

2. **start.sh**
   - Complete rewrite for proper MPM handling and startup flow
   - Lines 12-18: MPM configuration before Apache start
   - Lines 20-27: Database setup with proper error handling
   - Line 34: Apache starts in foreground using `exec`

3. **docker-entrypoint.sh**
   - Lines 25-36: Enhanced MPM checking and fixing
   - Lines 430-432: Simplified exit handling

## Why This Solution Works

### Three-Layer Defense
1. **Build-time**: Ensures correct configuration when image is built
2. **Runtime start**: Fixes configuration before Apache starts
3. **Runtime check**: Detects and fixes any issues during database setup

### Why mpm_prefork?
- PHP with mod_php requires `mpm_prefork`
- `mpm_event` and `mpm_worker` use threads, which mod_php doesn't support
- Only ONE MPM can be loaded at a time

### Why `exec apache2-foreground`?
- Replaces the shell process with Apache (PID 1)
- Proper signal handling for graceful shutdowns
- Keeps container running until Apache exits

## Testing
To verify the fix works:

1. Build the image:
   ```bash
   docker build -t opencats:latest .
   ```

2. Run a container:
   ```bash
   docker run -p 8080:80 -e DATABASE_HOST=localhost -e DATABASE_USER=root -e DATABASE_PASS=secret -e DATABASE_NAME=opencats opencats:latest
   ```

3. Check for MPM error in logs:
   ```bash
   docker logs <container-id>
   ```

You should see:
```
Fixing Apache MPM configuration...
Disabling all MPMs...
Enabling mpm_prefork (required for PHP)...
Apache MPM configuration fixed.
```

And NO "AH00534" error.

## Key Takeaways

1. **Always disable ALL MPMs first** - ensures clean state
2. **Enable only ONE MPM** - in this case, `mpm_prefork` for PHP
3. **Fix at multiple stages** - build time AND runtime for redundancy
4. **Use `exec` for the final process** - proper PID 1 and signal handling
5. **Log clearly** - helps with debugging future issues

## Related Documentation

- Apache MPM Documentation: https://httpd.apache.org/docs/current/mod/mpm_common.html
- PHP with Apache: https://httpd.apache.org/docs/2.4/howto/public_html.html
- Docker Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
