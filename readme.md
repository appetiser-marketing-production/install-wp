# 🚀 WordPress Installation Script

## 📌 Introduction

This script **automates** the installation of WordPress by setting up the web server, configuring the database, and ensuring proper file permissions. Whether you're deploying a **staging** or **production** environment, this script guarantees a **fast, consistent, and optimized** WordPress installation.

---

## 📝 Version Information
- **Version:** 1.1.0
- **Author:** Landing Page Team
- **Author URI:** [https://appetiser.com.au/](https://appetiser.com.au/)

---
## 🔥 What's New in Version 1.1.0

✅ **Config File Support:** The script now loads configurations from `install-wp.conf` to enable automated installations.  
✅ **Improved Logging:** All installation steps are logged for troubleshooting.  
✅ **User-Friendly Prompts:** If values are missing from the config, the script will **prompt interactively** instead of failing.  

---

## 🛠️ Requisites

Before running this script, ensure the following requirements are met:

1️⃣ **WP-CLI** - Installed and accessible. [Install WP-CLI](https://wp-cli.org/#installing)  
2️⃣ **SSH Access** - Required to run this script remotely.  
3️⃣ **Sudo Privileges** - User must have `sudo` permissions to modify directories and set permissions.  
4️⃣ **MySQL/MariaDB Client** - Needed for database operations.  
5️⃣ **Web Server** - Apache or Nginx should be set up and running.  
6️⃣ **PHP Installed** - Ensure PHP and required extensions are installed.  

---

## 📝 Configuration File (`install-wp.conf`)

The script **automatically loads** values from `install-wp.conf`. If the file is missing, the script will **prompt for input**.

### Example `install-wp.conf`:
```ini
# Install WP Configuration File

# Web root directory
WEB_ROOT="/var/www/html"

# Database credentials
DB_USER="wpuser"
DB_PASS="wppassword"

# Base URL (without trailing slash)
BASE_URL="https://example.com"

# Folder name for WordPress installation
FOLDER_NAME="mywp"

# Database name prefix (without underscore)
DB_PREFIX="wp"

# WordPress site details
SITE_TITLE="My WordPress Site"
ADMIN_USER="admin"
ADMIN_PASS="securepassword"
ADMIN_EMAIL="admin@example.com"
