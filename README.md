# wpv

A quick and dirty script to create and provision WP development sites for use with Laravel Valet. It's meant to be used for plugin development in particular, ideally for creating development sites inside plugin or project repositories.

Requires both [Laravel Valet](https://laravel.com/docs/valet) and [WP-CLI](https://wp-cli.org/).

## Features (kind of)

**wpv** adheres to the "convention over configuration" pattern, which means it has very few configurable options.

As such, some of the choices it makes (with no user intervention) can't be changed via the CLI or a configuration file (at least at this moment).
Still, using WP-CLI or Valet commands directly can provide what's needed to alter some initial configuration made by **wpv**.

### Initial Config

Sites created via **wpv** will be created with:

- A domain name based on the name of directory used as "source" or "project" directory (the `-s` option).
- `WP_DEBUG`, `WP_SCRIPT_DEBUG`, error reporting and logging enabled.
- The WP theme is changed to _Twenty Twelve_, which is simpler than the default.
- 4 users, all with password "password" and e-mail `<username>@<domain>`:
  - An administrator with username "admin",
  - 3 users with _Subscriber_ role and usernames "bob", "john" and "jane".
- 3 plugins installed and activated:
  - [Query Monitor](https://wordpress.org/plugins/query-monitor/),
  - [ARI Adminer](https://wordpress.org/plugins/ari-adminer/),
  - An empty plugin (no real code) called "Test Plugin" (file `test-plugin.php`) that can be used for quickly trying things out. 
  
### Per-project customization (running an script after initial setup)

If a script at `.wpv/after.sh` is found inside the source directory, it'll be sourced after the initial set up, allowing developers to customize or do some extra initialization on a per-project or per-repository basis.
This script can make use of the following shell variables if necessary:

- `SRC_DIR` - Source/project directory path
- `DEST_DIR` - Destination directory where the site was installed (i.e. the root of the WP install)
- `SITE_NAME` - The name for this site and the MySQL database
- `DB_NAME` - Identical to `SITE_NAME` at the moment
- `DOMAIN_NAME` - Domain name for this site including the Valet domain extension

## Usage examples

The following are some common scenarios that **wpv** can handle. For details on usage and command-line options, use `wpv -h`.

1. Set up a site at an arbitrary directory using the name of the directory as site name:
   ```
   wpv -c
   ```
2. Set up a site under "public_html" in the current directory using the name of the current directory as site name:
   ```
   wpv -c -d public_html
   ```
3. Create a folder for a site called "seriousmovies" (domain name will be "seriousmovies.test" or similar) and use it as the root of a WP dev environment:
   ```
   mkdir seriousmovies
   cd seriousmovies
   wpv -c -n
   # -n means no confirmation is needed before proceeding (non-interactive)
   ```
4. Create a folder for a site called "seriousmovies" (domain name will be "seriousmovies.test" or similar) but use "seriousmovies/_www" as the root of the WP install, leaving the parent folder unpolluted so that it can be used for other project files:
   ```
   mkdir seriousmovies
   cd seriousmovies
   wpv -c -d _www
   ```
