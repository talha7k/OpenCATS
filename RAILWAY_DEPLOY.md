# Railway Deployment Guide for OpenCATS

This guide will help you deploy OpenCATS Applicant Tracking System to Railway.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Deployment Steps](#deployment-steps)
- [Database Setup](#database-setup)
- [Post-Deployment Setup](#post-deployment-setup)
- [Troubleshooting](#troubleshooting)
- [Updating Your Deployment](#updating-your-deployment)
- [Scaling and Performance](#scaling-and-performance)

## Prerequisites

Before you begin, make sure you have:

1. A Railway account (sign up at https://railway.app)
2. Git installed on your local machine
3. This repository cloned to your local machine
4. Railway CLI installed (optional, but recommended)

## Quick Start

### 1. Install Railway CLI (Optional but Recommended)

```bash
npm install -g @railway/cli
railway login
```

### 2. Initialize Railway Project

```bash
cd /path/to/recruiter
railway init
```

### 3. Add MySQL Database

```bash
railway add mysql
```

### 4. Configure Environment Variables

```bash
railway variables set DATABASE_HOST=mysql.railway.internal
railway variables set DATABASE_USER=root
railway variables set DATABASE_PASS=${RAILWAY_PRIVATE_KEY}
railway variables set DATABASE_NAME=opencats
railway variables set LICENSE_KEY=3163GQ-54ISGW-14E4SHD-ES9ICL-X02DTG-GYRSQ6
```

### 5. Deploy

```bash
railway up
```

## Configuration

### Railway Web UI Method

1. Go to [Railway](https://railway.app) and log in
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your OpenCATS repository
4. Add a MySQL database plugin
5. Configure environment variables (see below)
6. Click "Deploy"

### Environment Variables

Configure these environment variables in Railway:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_HOST` | Yes | - | MySQL hostname (e.g., `mysql.railway.internal`) |
| `DATABASE_USER` | Yes | - | MySQL username |
| `DATABASE_PASS` | Yes | - | MySQL password |
| `DATABASE_NAME` | Yes | - | MySQL database name |
| `LICENSE_KEY` | No | `3163GQ-54ISGW-14E4SHD-ES9ICL-X02DTG-GYRSQ6` | OpenCATS license key |

### Setting Environment Variables in Railway

**Using CLI:**

```bash
railway variables set DATABASE_HOST=mysql.railway.internal
railway variables set DATABASE_NAME=opencats
railway variables set DATABASE_USER=root
railway variables set DATABASE_PASS=${RAILWAY_PRIVATE_KEY}
```

**Using Web UI:**

1. Go to your project
2. Select your OpenCATS service
3. Click "Variables" tab
4. Add each variable with its value

## Deployment Steps

### Step 1: Prepare Your Code

Ensure all deployment files are present:
- `Dockerfile`
- `docker-entrypoint.sh`
- `000-default.conf`
- `railway.json`
- `.dockerignore`

### Step 2: Create Railway Project

**Option A: Using Railway CLI**

```bash
# Navigate to your project directory
cd /Users/talha/Documents/workspace/recruiter

# Initialize Railway
railway init

# Add MySQL database
railway add mysql

# Set environment variables
railway variables set DATABASE_HOST=mysql.railway.internal
railway variables set DATABASE_NAME=opencats
railway variables set DATABASE_USER=root
railway variables set DATABASE_PASS=${RAILWAY_PRIVATE_KEY}

# Deploy
railway up
```

**Option B: Using Railway Web UI**

1. Push your code to GitHub
2. Log in to Railway
3. Create new project from GitHub
4. Add MySQL database plugin
5. Configure environment variables
6. Deploy

### Step 3: Verify Deployment

After deployment completes:

1. Check the deployment logs for any errors
2. Verify the service is healthy (green checkmark)
3. Get your deployment URL from Railway dashboard
4. Access your OpenCATS instance

## Database Setup

The deployment process automatically:

1. Creates the database if it doesn't exist
2. Imports the schema from `db/cats_schema.sql`
3. Configures the connection using environment variables

### Manual Database Setup (If Needed)

If you need to manually set up the database:

```bash
# Connect to Railway database
railway db

# Or use MySQL client
mysql -h <DATABASE_HOST> -u <DATABASE_USER> -p <DATABASE_NAME>

# Import schema (done automatically by entrypoint)
mysql -h <DATABASE_HOST> -u <DATABASE_USER> -p <DATABASE_NAME> < db/cats_schema.sql
```

## Post-Deployment Setup

### 1. Access OpenCATS

Navigate to your Railway deployment URL. You'll see the OpenCATS login screen.

### 2. Default Login

The default administrator credentials are set up during schema import:
- Username: `admin`
- Password: `admin`

**IMPORTANT:** Change the default password immediately after your first login!

### 3. Configure SMTP Settings

To enable email functionality:

1. Login as administrator
2. Go to Settings → Email
3. Configure your SMTP settings
4. Test the configuration

You can also set these via environment variables if you add them to the Dockerfile/config:

```
MAIL_SMTP_HOST=smtp.example.com
MAIL_SMTP_PORT=587
MAIL_SMTP_AUTH=true
MAIL_SMTP_USER=your-email@example.com
MAIL_SMTP_PASS=your-email-password
MAIL_SMTP_SECURE=tls
```

### 4. Configure Career Portal

To set up the career portal:

1. Go to Settings → Career Portal
2. Enable the portal
3. Customize the URL and appearance
4. Create job orders to display

### 5. Set Up Backups

Railway automatically backs up your MySQL database. To access backups:

1. Go to your MySQL service in Railway
2. Click "Backups" tab
3. Download or restore backups as needed

For file uploads and attachments, consider:

- Using Railway volumes for persistent storage
- Setting up S3 or similar storage for attachments
- Regular exports via cron jobs

## Troubleshooting

### Common Issues

#### 1. Database Connection Failed

**Symptoms:** Application shows database connection errors

**Solutions:**
- Verify `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASS` are correct
- Ensure MySQL service is running
- Check deployment logs: `railway logs`

#### 2. Permission Denied Errors

**Symptoms:** Errors writing to temp/upload/attachments directories

**Solutions:**
- The entrypoint script should set permissions automatically
- If issues persist, check logs for specific errors
- Verify directories exist and have correct permissions

#### 3. 500 Internal Server Error

**Symptoms:** Generic server error when accessing the site

**Solutions:**
- Check Apache error logs in Railway deployment
- Verify all PHP extensions are installed (done in Dockerfile)
- Ensure `.htaccess` file is present and readable

#### 4. Memory or Upload Limit Errors

**Symptoms:** Uploads fail or script execution times out

**Solutions:**
- Adjust PHP memory/upload limits in `Dockerfile`
- Current settings: memory_limit=256M, upload_max_filesize=20M
- Modify these values and redeploy

### Viewing Logs

**Using CLI:**

```bash
# View real-time logs
railway logs

# View logs for specific service
railway logs --service opencats
```

**Using Web UI:**

1. Go to your project
2. Select the service
3. Click "Logs" tab
4. View deployment and runtime logs

### Debug Mode

To enable debug mode, modify the entrypoint to set PHP error reporting:

Add to `docker-entrypoint.sh`:

```bash
export PHP_DISPLAY_ERRORS=On
export PHP_ERROR_REPORTING=E_ALL
```

Then redeploy.

## Updating Your Deployment

### Automatic Updates (Recommended)

When you push changes to your main branch:

1. Enable auto-deploy in Railway settings
2. Railway automatically builds and deploys

### Manual Updates

**Using CLI:**

```bash
# Push changes to Git
git add .
git commit -m "Update deployment"
git push

# Redeploy to Railway
railway up
```

**Using Web UI:**

1. Push changes to GitHub
2. Go to Railway project
3. Click "Redeploy" button

### Database Updates

When updating the database schema:

1. Add migration SQL files to the `db/` directory
2. Modify `docker-entrypoint.sh` to run migrations
3. Test locally before deploying to production

Example migration:

```sql
-- db/migration_001_add_new_column.sql
ALTER TABLE candidates ADD COLUMN new_column VARCHAR(255);
```

## Scaling and Performance

### Horizontal Scaling

Railway supports automatic scaling. Configure in `railway.json`:

```json
{
  "deploy": {
    "numReplicas": 2
  }
}
```

**Note:** Multiple replicas require:
- Shared storage for attachments
- Session storage in Redis or database
- Database connection pooling

### Vertical Scaling

Increase resources in Railway:
1. Go to your service settings
2. Adjust CPU/RAM allocation
3. Save and redeploy

### Performance Optimization

1. **Enable Caching:**
   ```php
   // In config.php
   define('CACHE_MODULES', true);
   ```

2. **Database Indexes:**
   - Review and add indexes to frequently queried columns
   - Use Railway's database tools to analyze queries

3. **CDN for Static Assets:**
   - Configure CDN for images, CSS, and JavaScript
   - Reduce load on application servers

4. **Enable OPcache:**
   ```bash
   # Add to Dockerfile
   RUN docker-php-ext-enable opcache
   ```

### Monitoring

Use Railway's built-in monitoring:

1. Go to "Metrics" tab
2. Monitor CPU, memory, and network usage
3. Set up alerts for resource thresholds

## Additional Configuration

### SSL/HTTPS

Railway automatically provides HTTPS. Ensure:
- `SSL_ENABLED` is set to `false` in config.php (Railway handles SSL at the proxy level)
- All resources use relative URLs

### Custom Domain

To use a custom domain:

1. Go to your service in Railway
2. Click "Settings" → "Domains"
3. Add your custom domain
4. Update DNS records as instructed
5. Wait for SSL certificate issuance

### Storage Considerations

For production deployments, consider:

1. **Database:** Use Railway's managed MySQL
2. **Attachments:**
   - Option A: Railway volumes (easiest)
   - Option B: S3-compatible storage (recommended for scaling)
   - Option C: External file storage service

For S3 storage, modify config.php:

```php
define('ATTACHMENTS_S3_BUCKET', 'your-bucket');
define('ATTACHMENTS_S3_REGION', 'us-east-1');
define('ATTACHMENTS_S3_KEY', 'your-access-key');
define('ATTACHMENTS_S3_SECRET', 'your-secret-key');
```

## Security Best Practices

1. **Change Default Credentials**
   - Immediately change admin password after deployment
   - Use strong, unique passwords

2. **Environment Variables**
   - Never commit secrets to Git
   - Use Railway's variable management
   - Rotate passwords regularly

3. **Access Control**
   - Limit Railway access to authorized team members
   - Enable two-factor authentication on Railway

4. **Regular Backups**
   - Configure automatic backups
   - Test restoration procedures
   - Keep off-site backups

5. **Keep Updated**
   - Update OpenCATS regularly
   - Monitor security advisories
   - Update PHP and dependencies

## Support and Resources

- **OpenCATS Documentation:** http://www.opencats.org/docs/
- **Railway Documentation:** https://docs.railway.app/
- **Railway Support:** https://support.railway.app/

## Contributing

If you encounter issues or want to improve the deployment:

1. Check existing issues in the repository
2. Create a new issue with details
3. Submit pull requests for improvements
4. Document any changes to this guide

## License

This deployment configuration is part of OpenCATS and follows the same license as the main project.

---

**Last Updated:** 2026-03-11

**Version:** 1.0.0
