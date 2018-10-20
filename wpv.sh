#!/bin/bash
#
# wpv - A quick and dirty script to create and provision WP development sites for use with Laravel Valet.
# Copyright (C) 2018  Smiling Robots hello@smilingrobots.com
#


# Some helper functions.
function print_help {
    echo "\
Usage:
    wpv -c [-s <sourcedir>] [-d <sitedir>]
    wpv -h

    -c             Create site.
    -s <sourcedir> Source/project directory. Defaults to current directory.
    -d <sitedir>   Destination directory relative to <sourcedir>. This is where the WP install will live. Defaults to ''.
    -n             Run non-interactive. Do not ask questions.

    -h             Display help.

    Usage examples:
        wpv -d www    Sets up WP inside the "www" directory in the current folder. Asks for confirmation.
        wpv -n        Sets up WP inside the current directory. Does not ask for confirmation.
"
    exit 2
}

function err {
    echo "[!] $1"; exit 65;
}

function is_empty_dir {
    if [ ! -d "$1" ]; then
        return 1
    else
        $(find "$1" -mindepth 1 | read)
        return $?
    fi
}

function untrailingslashit {
    echo "$1" | sed 's/\/*$//g'
}

function trailingslashit {
    local noslashversion=$(untrailingslashit "$1");
    echo "$noslashversion/"
}

# Parse args.
SRC_DIR=$(pwd)
DEST_DIR=""

while getopts ":cs:d:hn" argname; do
    case $argname in
        s) SRC_DIR="$OPTARG";;
        d) DEST_DIR="$OPTARG";;
        n) DONT_ASK=1;;
        c) DO_SOMETHING=1;;
        ?) print_help;;
    esac
done

if [ -z "$DO_SOMETHING" ]; then
    print_help
fi

# Check source dir is valid.
SRC_DIR=$(untrailingslashit "$SRC_DIR")
if [ ! -d "$SRC_DIR" ]; then
    err "\"$SRC_DIR\" is not a valid directory."
fi

# Figure out domain/db name
SITE_NAME=`basename "$SRC_DIR"`
SITE_NAME=${SITE_NAME// /_}
SITE_NAME=${SITE_NAME//[^a-zA-Z0-9_-]/}
SITE_NAME=$(echo "$SITE_NAME" | tr A-Z a-z)
DOMAIN_NAME="$SITE_NAME.$(valet domain)"
DB_NAME="$SITE_NAME"

# Make sure dest dir does not exist or is empty.
DEST_DIR=$(untrailingslashit "$SRC_DIR/$DEST_DIR" )
is_empty_dir "$DEST_DIR";
if [ 1 -ne $? ]; then
    err "\"$DEST_DIR\" is not empty."
fi

# Confirm that MySQL credentials work and the database does not exist.
mysql -uroot -e ''
if [ $? != 0 ]; then
    err "Could not access MySQL server."
fi

mysql -uroot -e "USE ${DB_NAME}" > /dev/null 2>&1
if [ $? == 0 ]; then
    err "Database \"$DB_NAME\" already exists."
fi

# Make sure Valet link is not already in use.
valet links | grep "$DOMAIN_NAME" > /dev/null
if [ $? == 0 ]; then
    err "Domain name \"$DOMAIN_NAME\" is already in use by Valet."
fi

# Everything checks out, last confirmation (maybe).
if [ -z "$DONT_ASK" ]; then
    echo "=> We're about to install a WordPress development environment in \"$DEST_DIR\" with domain name \"$DOMAIN_NAME\" and MySQL database \"$SITE_NAME\"."
    read -p "=> Are we gonna do this?... (y/n) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "=> OK. (° ͜°)╭∩╮"
        exit 1;
    fi
fi

# Proceed.
echo "=> Working..."

mkdir "$DEST_DIR"
cd "$DEST_DIR"

mysql -uroot -e "CREATE DATABASE ${DB_NAME}"

# WP core config.
wp core download
wp core config --dbname=$DB_NAME --dbuser=root --dbpass='' --extra-php <<-PHP
    define( 'WP_DEBUG', true );

    if ( WP_DEBUG ) {
        @error_reporting( E_ALL );
        @ini_set( 'log_errors', true );

        define( 'WP_DEBUG_LOG', true );
        define( 'WP_DEBUG_DISPLAY', false );
        define( 'SCRIPT_DEBUG', true );
    }
PHP

wp core install --url="$DOMAIN_NAME" --title="$SITE_NAME" --admin_user=admin --admin_password=password --admin_email=admin@"$DOMAIN_NAME"

# Configure some users.
wp user update admin --first_name=Admin --last_name=Istrator
wp user create john john@"$DOMAIN_NAME" --first_name=John --last_name=Doe
wp user create bob bob@"$DOMAIN_NAME" --first_name=Bob --last_name=Foo
wp user create jane jane@"$DOMAIN_NAME" --first_name=Jane --last_name=Doe

# Install and activate TwentyTwelve.
wp theme install twentytwelve --activate

# Install extra plugins.
wp plugin install query-monitor --activate
wp plugin install ari-adminer --activate

# Install & activate a special plugin with no content that can be used for quickly testing things.
cat <<-EOF > "$DEST_DIR/wp-content/plugins/test-plugin.php"
    <?php
    /**
     * Plugin Name: Test Plugin
     * Description: This plugin contains no real code. Edit its content to quickly test things.
     */
EOF
wp plugin activate test-plugin

valet link "$SITE_NAME"

if [ -e "$SRC_DIR/.wpv/after.sh" ]; then
    source "$SRC_DIR/.wpv/after.sh"
fi

echo "=> That's it! \(ᵔᵕᵔ)/"
echo "==> Your new WordPress site is available at http://$DOMAIN_NAME."
echo "==> Root directory is at \"$DEST_DIR\""
echo "==> Remember: \"admin\" user has password \"password\"".
echo "=> Thank you for flying wpv airlines."

