# Important Rules for Custom Code Modifications

This document outlines best practices for maintaining a clean fork of OpenCATS that can easily receive upstream updates.

## The "Clean Fork" Rules

To ensure the upstream sync automation doesn't break your site, follow these guidelines:

### 1. Don't Edit Core Files If Possible

Instead of editing a large core file directly, try to **extend** it:

- **Bad**: Editing a 5,000-line core file to add a Stripe check
- **Good**: Create a separate file (like `saas-gatekeeper.php`) and add just ONE line to the original code to include it

```php
// In core file - add only this line:
require_once('./custom/saas-gatekeeper.php');

// All your logic goes in the separate file
```

### 2. Use CSS for Branding

If you are rebranding the application:

- **Bad**: Changing HTML templates everywhere
- **Good**: Create a custom CSS file that overrides the original styles

```html
<!-- Add one line to load your custom CSS -->
<link rel="stylesheet" href="/css/custom-branding.css">
```

This way, if the original project updates their HTML, your CSS will likely still work.

### 3. Organize Custom Code in Dedicated Directories

Keep all your modifications in separate folders:

```
/custom/
  /modules/       # Custom modules
  /css/           # Custom stylesheets
  /js/            # Custom JavaScript
  /patches/       # Small patches to core files
  /config/        # Custom configuration
```

### 4. Document All Modifications

Keep a `CHANGES.md` file that lists:

- What files you modified
- Why you modified them
- What functionality was added

This makes it easier to re-apply changes after an upstream update.

### 5. The Conflict Alert

If the automation fails because of a **Merge Conflict**:

1. GitHub will send you an email notification
2. You'll need to manually resolve the conflict
3. After resolution, the automation will resume automatically

**How to resolve conflicts:**

```bash
# Fetch upstream changes
git fetch upstream

# Merge upstream into your branch
git merge upstream/master

# Resolve conflicts in the files that Git marks
# Then commit the resolution
git add .
git commit -m "Resolve merge conflicts with upstream"
git push origin master
```

## Files Safe to Modify

These files are typically safe to modify without causing merge conflicts:

- `config.php` - Your local configuration
- Custom files you create in `/custom/` directory
- `.github/workflows/` - Your GitHub Actions
- `RAILWAY_DEPLOY.md` - Your deployment docs

## Files to Avoid Modifying

Try to avoid direct edits to:

- Core application files in `/lib/`
- Module files in `/modules/` (extend instead)
- Database schema files
- JavaScript libraries

## Railway-Specific Customizations

The following files were added for Railway deployment and are safe to modify:

- `Dockerfile` - Docker build configuration
- `docker-entrypoint.sh` - Container startup script
- `000-default.conf` - Apache configuration
- `railway.json` - Railway deployment config
- `.dockerignore` - Docker build exclusions

These files don't exist in the upstream repository, so they won't cause conflicts.

---

**Remember**: The goal is to make upstream updates as smooth as possible. The less you modify core files, the easier it will be to stay up-to-date with the original OpenCATS project.
