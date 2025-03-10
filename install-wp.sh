#!/bin/bash

# Get script directory
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CONFIG_FILE="$SCRIPT_DIR/install-wp.conf"

LOGFILE="/var/log/install-wp_$(whoami)_$(date +'%Y%m%d_%H%M%S').log"

# Function to log actions
log_action() {
  local result=$?
  local time_stamp
  time_stamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$time_stamp: $1: $2" | sudo tee -a "$LOGFILE" > /dev/null
  return $result
}

# Function to check if a variable is blank
check_blank() {
  local value="$1"
  local var_name="$2"

  case "$value" in
    "")
      echo -e "❌ Error: $var_name cannot be blank. Please provide a valid $var_name."
      log_action "ERROR" "$var_name cannot be blank. Please provide a valid $var_name."
      exit 1
      ;;
    *)
      echo -e "✅ $var_name is set to: $value"
      ;;
  esac
}

# Load config file if exists
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
  echo -e "⚙️  Configuration loaded from $CONFIG_FILE"
else
  echo -e "⚠️  Configuration file not found. Running interactively."
fi

echo -e "🔧 Preparing the installation details."
echo -e "📖 For more information, Read the readme.md file."

# Check if wp-cli is installed
if ! which wp > /dev/null; then
  errormsg="WP CLI could not be found. Please install WP-CLI before running this script."
  echo -e "❌ $errormsg"
  echo -e "🔗 For installation instructions, visit: https://wp-cli.org/#installing"
  log_action "ERROR" "$errormsg"
  exit 1
fi

log_action "CHECK" "WP CLI INSTALLED"

# Prompt or use config for web root
web_root=${WEB_ROOT:-$(read -p "Enter the web server's root directory (default: /var/www/html): " tmp && echo "${tmp:-/var/www/html}")}

# Navigate to the web server's root directory
cd "$web_root" || {
    errormsg="Failed to navigate to $web_root. Ensure the directory exists."
    echo -e "❌ $errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
}
log_action "CHECK" "Webroot is accessible"

# Prompt or use config for database credentials
dbuser=${DB_USER:-$(read -p "Enter database username: " tmp && echo $tmp)}
check_blank "$dbuser" "DB Username"

dbpass=${DB_PASS:-$(read -p "Enter database password: " tmp && echo $tmp)}
check_blank "$dbpass" "DB Password"

# Check MySQL credentials
case $(mysql -u"$dbuser" -p"$dbpass" -e "QUIT" >/dev/null 2>&1; echo $?) in
  0)
    echo -e "✅ Database credentials are valid."
    log_action "CHECK" "Database credentials are valid"
    ;;
  *)
    errormsg="Failed to connect to the database using the credentials provided."
    echo -e "❌ $errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
    ;;
esac

# Prompt or use config for base URL
base_url=${BASE_URL:-$(read -p "Enter base URL (e.g., https://localhost): " tmp && echo $tmp)}
check_blank "$base_url" "Base URL"
base_url=${base_url%/} # Remove trailing slash if present

# Prompt or use config for folder name
foldername=${FOLDER_NAME:-$(read -p "Enter folder name: " tmp && echo $tmp)}
check_blank "$foldername" "Folder name"

# Create the directory
sudo -u www-data mkdir -p "$web_root/$foldername"
case $? in
  0)
    echo -e "📂 Directory $web_root/$foldername created successfully."
    log_action "CHECK" "Directory $web_root/$foldername created successfully."
    ;;
  *)
    errormsg="Failed to create directory $web_root/$foldername."
    echo -e "❌ $errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
    ;;
esac

sudo -u www-data chmod -R 775 "$web_root/$foldername"
cd "$web_root/$foldername" || { echo -e "❌ Failed to navigate to $web_root/$foldername. Exiting."; exit 1; }

# Download Wordpress core.
echo -e "📥 Downloading WordPress core..."
sudo -u www-data wp core download --path="$web_root/$foldername"
case $? in
  0)
    echo -e "✅ WordPress core downloaded successfully."
    log_action "Done" "WordPress core downloaded."
    ;;
  *)
    echo -e "❌ Failed to download WordPress core."
    log_action "ERROR" "Failed to download WordPress core."
    exit 1
    ;;
esac

# Prompt or use config for database name prefix
dbprefix=${DB_PREFIX:-$(read -p "Enter database name prefix [default: wp]: " tmp && echo "${tmp:-wp}")}
check_blank "$dbprefix" "Database Name Prefix"

dbname="${dbprefix}_${foldername}"
echo -e "🗄️  Database name is set to: $dbname"

# Validate the database name
case $(mysql -u"$dbuser" -p"$dbpass" -e "USE $dbname;" 2>/dev/null; echo $?) in
  0)
    echo -e "⚠️  Database $dbname already exists."
    read -p "Do you want to drop the existing database? (yes/no): " drop_confirm
    case "$drop_confirm" in
      [Yy][Ee][Ss]|[Yy])
        if mysql -u"$dbuser" -p"$dbpass" -e "DROP DATABASE $dbname;" 2>/dev/null; then
          echo -e "🗑️  Database $dbname has been dropped successfully."
        else
          echo -e "❌ Failed to drop database $dbname."
          exit 1
        fi
        ;;
      *)
        errormsg="Error: Database $dbname already exists."
        echo -e "❌ $errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
    esac
    ;;
  *)
    echo -e "✅ Database name $dbname is available."
    log_action "CHECK" "Database name $dbname is available."
    ;;
esac

url="$base_url/$foldername"

echo -e "🔧 Creating wp-config.php..."
sudo -u www-data wp config create --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpass" --dbprefix="${dbprefix}_"
echo -e "✅ Config created."

echo -e "🗄️  Creating database..."
sudo -u www-data wp db create
echo -e "✅ Database created."

echo -e "🚀 Installing WordPress..."
sudo -u www-data wp core install --url="$url" --title="${SITE_TITLE:-Default Site}" --admin_user="${ADMIN_USER:-admin}" --admin_password="${ADMIN_PASS:-password}" --admin_email="${ADMIN_EMAIL:-admin@example.com}"
echo -e "✅ WordPress installed."

# Set proper permissions
echo -e "🔑 Setting proper permissions..."
sudo -u www-data find "$web_root/$foldername" -type d -exec chmod 755 {} \;
sudo -u www-data find "$web_root/$foldername" -type f -exec chmod 644 {} \;
echo -e "✅ Permissions set."

echo -e "🎉 WordPress installation complete!"
echo -e "🌐 Site URL: $url"
echo -e "📂 Site Root Directory: $web_root/$foldername"
log_action "COMPLETED" "WordPress installation finished."

echo -e "📝 Log file saved at: $LOGFILE"
