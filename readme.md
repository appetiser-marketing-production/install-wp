# WordPress Installation Script

## Introduction

This script automates the process of installing a WordPress website. Designed for flexibility and ease of use, it allows you to set up WordPress in a web server's root directory, configure the database, and ensure proper file permissions in just a few steps. Whether you're setting up a new staging environment or deploying a production-ready instance, this script ensures consistency and accuracy in your WordPress installation.

---

## Requisites

Before running this script, ensure the following prerequisites are met:

1. **WP-CLI**:
   - WP-CLI must be installed and accessible in the environment. For installation instructions, visit [WP-CLI Installation Guide](https://wp-cli.org/#installing).

2. **SSH Access**:
   - Secure Shell (SSH) access to the server where WordPress will be installed.

3. **User with Sudo Privileges**:
   - The script requires a user with `sudo` privileges to execute certain commands, such as creating directories and setting permissions.

4. **MySQL/MariaDB Client**:
   - The MySQL or MariaDB client must be installed for database-related operations.

5. **Valid Database Credentials**:
   - Ensure you have a valid database username and password with sufficient privileges to create and manage databases.

6. **Web Server**:
   - A functional web server (e.g., Apache or Nginx) configured to serve files from the target directory.

7. **PHP**:
   - PHP must be installed, including required extensions for WordPress.

---

## Steps and Procedures

### 1. **Initialization and Logging**
- A log file is dynamically created in `/var/log` with the current timestamp for detailed tracking of each step executed during the installation.

### 2. **Environment Validation**
- Verifies if WP-CLI is installed. If it's not available, the script notifies the user and provides instructions for installation.

### 3. **User Inputs**
The script collects critical setup details, including:
- **Web server root directory**: Defaults to `/var/www/html` if not specified.
- **Database credentials**: Username and password for the database.
- **Base URL**: The URL of the site (e.g., `https://example.com`).
- **Folder name**: Name of the folder where WordPress will be installed.
- **Database name prefix**: Defaults to `wp` but can be customized.
- **Site details**:
  - Site title
  - Admin username, password, and email

### 4. **Database Validation**
- Checks the validity of the provided database credentials.
- Ensures the database name is unique, prompting the user to drop the existing database if necessary.

### 5. **Directory Setup**
- Creates the specified folder under the web root directory.
- Ensures proper permissions to proceed with the installation.

### 6. **WordPress Core Installation**
- Downloads the WordPress core files.
- Creates the `wp-config.php` file using the provided database details.
- Creates the database and completes the WordPress installation with the provided site and admin credentials.

### 7. **Permission Settings**
- Adjusts directory and file permissions to ensure security and proper web server access:
  - Directories: `755`
  - Files: `644`

### 8. **Completion**
- Displays the following:
  - The URL of the newly installed WordPress site.
  - The root directory where the site's files are located.
- Logs the completion of the installation process.

---

## Usage Example

Run the script using the following command:
```bash
./install_wordpress.sh
