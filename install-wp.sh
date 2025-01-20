#!/bin/bash

LOGFILE="/var/log/staging_install_$(whoami)_$(date +'%Y%m%d_%H%M%S').log"

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
      echo "Error: $var_name cannot be blank. Please provide a valid $var_name."
      log_action "Error" "$var_name cannot be blank. Please provide a valid $var_name."
      
      exit 1
      ;;
    *)
      echo "$var_name is set to: $value"
      ;;-
  esac
}

echo "Usage: $0"
echo "Or you can center the details."
echo "For more information, visit: https://example.com/documentation"

# Check if wp-cli is installed
if ! which wp > /dev/null; then
  errormsg="WP CLI could not be found. Please install WP-CLI before running this script."
  echo "$errormsg"
  echo "For installation instructions, visit: https://wp-cli.org/#installing"
  log_action "ERROR" "$errormsg"
  exit 1
fi

log_action "CHECK" "WP CLI INSTALLED"

web_root=${1:-$(read -p "Enter the web server's root directory (default: /var/www/html): " tmp && echo "${tmp:-/var/www/html}")}

# Navigate to the specified web server's root directory
cd "$web_root" || {
    errormsg="Failed to navigate to $web_root. Ensure the directory exists."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
}
log_action "CHECK" "Webroot is accessible"

# Prompt for database credentials
dbuser=${1:-$(read -p "Enter database username: " tmp && echo $tmp)}
#check for blank
check_blank "$dbuser" "DB Username"
dbpass=${2:-$(read -p "Enter database password: " tmp && echo $tmp)}
#check for blank
check_blank "$dbpass" "DB Password"

# Check MySQL credentials
case $(mysql -u"$dbuser" -p"$dbpass" -e "QUIT" >/dev/null 2>&1; echo $?) in
  0)
    echo "Database credentials are valid."
    log_action "CHECK" "Database credentials are valid"
    ;;
  *)
    errormsg="Failed to connect to the database using the credentials provided. Please check your username and password."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
    ;;
esac

# Prompt for base URL
base_url=${3:-$(read -p "Enter base URL (e.g., https://localhost/): " tmp && echo $tmp)}
#check for blank
check_blank "$base_url" "Base URL"

# Prompt for folder name
foldername=${4:-$(read -p "Enter folder name: " tmp && echo $tmp)}
#check for blank
check_blank "$foldername" "Folder name"

# Create the directory
udo -u www-data mkdir -p "$web_root/$foldername"
case $? in
  0)
    echo "Directory $web_root/$foldername created successfully."
    log_action "CHECK" "Directory $web_root/$foldername created successfully."
    ;;
  *)
    errormsg="Failed to create directory $web_root/$foldername. Ensure you have sufficient permissions."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
    ;;
esac

sudo -u www-data chmod -R 775 "$web_root/$foldername"
cd "$web_root/$foldername" || { echo "Failed to navigate to $web_root/$foldername. Exiting."; exit 1; }

# Prompt for database name prefix

dbprefix=$(read -p "Enter database name prefix (default: wp): " tmp && echo "${tmp:-wp}")

dbname="${dbprefix}_${foldername}"
echo "Database name is set to: $dbname"

# Validate the database name
case $(mysql -u"$dbuser" -p"$dbpass" -e "USE $dbname;" 2>/dev/null; echo $?) in
  0)
    echo "Warning!!! Database $dbname already exists."
    read -p "Do you want to drop the existing database? (yes/no): " drop_confirm
    case "$drop_confirm" in
      [Yy][Ee][Ss]|[Yy])
        if mysql -u"$dbuser" -p"$dbpass" -e "DROP DATABASE $dbname;" 2>/dev/null; then
          echo "Database $dbname has been dropped successfully."
        else
          echo "Failed to drop database $dbname. Ensure you have sufficient permissions."
          exit 1
        fi
        ;;
      *)
        errormsg="Error: Database $dbname already exists. Please choose a different name."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Database name $dbname is valid and available."
    log_action "CHECK" "Database name $dbname is valid and available."
    ;;
esac

url="$base_url/$foldername"

title=${5:-$(read -p "Enter site title: " tmp && echo $tmp)}
#check for blank
check_blank "$title" "Site title"

adminuser=${6:-$(read -p "Enter admin username: " tmp && echo $tmp)}
#check for blank
check_blank "$adminuser" "Admin User"

adminpass=${7:-$(read -p "Enter admin password: " tmp && echo $tmp && echo "")}
#check for blank
check_blank "$adminpass" "Admin Pass"

adminemail=${8:-$(read -p "Enter admin email: " tmp && echo $tmp)}
#check for blank
check_blank "$adminemail" "Admin Email"

# Run commands as www-data
sudo -u www-data bash <<EOF
# Download WordPress core
wp core download
case $? in
  0)
    echo "Core downloaded."
    log_action "Done" "WordPress core downloaded."
    ;;
  *)
    echo "Failed to download WordPress core."
    log_action "ERROR" "Failed to download WordPress core."
    exit 1
    ;;
esac

# Create wp-config.php with database details
wp config create --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpass"
case $? in
  0)
    echo "Config created."
    log_action "Done" "WordPress config created."
    ;;
  *)
    echo "Failed to create wp-config.php."
    log_action "ERROR" "Failed to create wp-config.php."
    exit 1
    ;;
esac

# Create the database
wp db create
case $? in
  0)
    echo "Database created."
    log_action "Done" "WordPress database created."
    ;;
  *)
    echo "Failed to create the database."
    log_action "ERROR" "Failed to create the database."
    exit 1
    ;;
esac

# Install WordPress
wp core install --url="$url" --title="$title" --admin_user="$adminuser" --admin_password="$adminpass" --admin_email="$adminemail"
case $? in
  0)
    echo "Core installed."
    log_action "Done" "WordPress core installed."
    ;;
  *)
    echo "Failed to install WordPress core."
    log_action "ERROR" "Failed to install WordPress core."
    exit 1
    ;;
esac
EOF

# Set proper permissions
echo "Setting proper permissions..."
sudo -u www-data find "$web_root/$foldername" -type d -exec chmod 755 {} \;
sudo -u www-data find "$web_root/$foldername" -type f -exec chmod 644 {} \;
echo "Done"
log_action "Done" "WordPress folder and file permissions set: Directories (755), Files (644)."

echo "#### WordPress installation complete."
echo "Site URL: $url"
echo "Site Root Directory: $web_root/$foldername"
log_action "Completed" "Wordpress installation completed."

# Echo the log file path at the end of the script
echo "Log file created at: $LOGFILE";