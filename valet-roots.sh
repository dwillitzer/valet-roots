#!/bin/bash
sitename=$1

#global varables
wpuser='sysad'
# setting path for project folders
path=$HOME/sites
# set db name
dbname=wp_$sitename

# export PATH=$PATH:~/.composer/vendor/bin
# /usr/local/bin/valet

# add a simple yes/no confirmation before we proceed active secure
echo "Want a secure website? (y/n)"
read -e secure

# accept the name of our website
echo "Site Name: "
read -e sitetitle

# accept a comma separated list of pages
echo "Add Pages: "
read -e allpages

# add a simple yes/no confirmation before we proceed
echo "Run Install? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
	exit
else

	# -----------[CONDITIONAL CHECKS]--------------------------------------
	# checking if sitename is set
	if [ -z $sitename ]; then
		echo "Missing parameter SITENAME: $1 "
		echo "Correct Usage: valet-roots SITENAME"
		exit
	fi

	if [[ ! -d "~/sites" && -d "~/sites/valet" ]]; 
		then
		# creating site hosts folder if does not exist
		mkdir $path && mkdir $path/valet
		valet park

		path=$HOME/sites/valet
		if [[ -d "$path/$sitename" ]]; then
			#site exists exit
			echo "ugh oh \"$sitename\" already exists... now exiting"
			exit 0
		else
			echo "Creating site $sitename.dev"
			cwd=$path
			mkdir $path/$sitename && cd $cwd
		fi
	else
		path=$HOME/sites/valet
		if [[ -d "$path/$sitename" ]]; then
			#statements
			echo "ugh oh \"$sitename\" already exists in $path/$sitename... now exiting"
			exit 0
		else
			echo "Creating site $sitename.dev"
			cwd=$path
			mkdir $path/$sitename && cd $cwd
		fi
	fi

	# check is mariadb is active else start
	if [[ $(mysql.server status | grep 'not running') ]]; then
		mysql.server start
	fi

	# Current working directory
	cwd=$path/$sitename


	# downloading and install composer bedrock
	composer create-project roots/bedrock $sitename && cd $cwd

	# if the user didn't say no, then go ahead with secure mode
	if [[ "$secure" == y ]]; then
	    http='https'
	    valet secure
	else
		http='http'
		valet unsecure
	fi

	# checks if wp cli dot-env & login exists if not install which is needed for next steps
	if [[ ! $(wp package list | grep aaemnnosttv/wp-cli-dotenv-command) ]]; then
		wp package install aaemnnosttv/wp-cli-dotenv-command
	fi	
	if [[ ! $(wp package list | grep aaemnnosttv/wp-cli-login-command) ]]; then
		wp package install aaemnnosttv/wp-cli-login-command
	fi

	cp .env.example .env

	wp dotenv set DB_HOST localhost
	wp dotenv set DB_NAME $dbname
	wp dotenv set DB_USER root
	wp dotenv set DB_PASSWORD ''
	wp dotenv set WP_HOME $http://$sitename.dev
	wp dotenv salts regenerate --file=.env
	wp dotenv list

	# check if db exists if so drop and create
	mysql -u root -e "DROP DATABASE IF EXISTS $dbname"
	wp db create
	# https://exmaple.dev
	wp db import ~/Documents/web-dev/wordpress/src/example.sql 
	if $(wp --url=http://example.dev core is-installed --network); then
	    wp search-replace --url=https://example.dev 'https://example.dev' "$(wp dotenv get WP_HOME)" --recurse-objects --network --skip-columns=guid
	else
	    wp search-replace 'http://example.dev' "$(wp dotenv get WP_HOME)" --recurse-objects --skip-columns=guid
	fi
	wp db query "UPDATE wp_options SET option_value='$sitetitle' WHERE option_name='blogname';UPDATE wp_options SET option_value='' WHERE option_name='blogdescription';"

	# generate random 12 character password
	password=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)
	# copy password to clipboard
	echo $password | pbcopy
	# discourage search engines
	wp option update blog_public 0

	# show only 6 posts on an archive page
	wp option update posts_per_page 6

	# delete sample page, and create homepage
	wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="sample-page" --field=ID --format=ids)
	wp post create --post_type=page --post_title=Home --post_status=publish --post_author=$(wp user get admin --field=ID --format=ids)

	# set homepage as front page
	wp option update show_on_front 'page'

	# set homepage to be the new page
	wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids)

	# create all of the pages
	export IFS=","
	for page in $allpages; do
		wp post create --post_type=page --post_status=publish --post_author=$(wp user get admin --field=ID --format=ids) --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')"
	done

	# delete akismet and hello dolly
	wp plugin delete akismet
	wp plugin delete hello
	wp login install --activate

	# create a navigation bar
	wp menu create "Main Navigation"

	# add pages to navigation
	export IFS=" "
	for pageid in $(wp post list --order="ASC" --orderby="date" --post_type=page --post_status=publish --posts_per_page=-1 --field=ID --format=ids); do
		wp menu item add-post main-navigation $pageid
	done

	# assign navigaiton to primary location
	wp menu location assign main-navigation primary
	# set pretty urls
	wp rewrite structure '/%postname%/' --hard
	wp rewrite flush --hard

	themepath=web/app/themes/$sitename
	composer create-project roots/sage $themepath dev-master
	cd $themepath 
	npm install

	clear

	echo "================================================================="
	echo "Installation is complete. Your username/password is listed below."
	echo ""
	echo "Username: admin"
	echo "Password: $password"
	echo ""
	echo "================================================================="

	wp login create admin --launch

fi
