#!/bin/bash
# Created an easy bedrock project builder for easier local website deployment
# @author: Daniel Willitzer
#
# Requirements: MacOS, laravel valet, php 5.6>, mariadb 10.1.16>, wp-cli, composer, npm
# Suggested Guide: 
#
# Github Projects: wp-cli/wp-cli, aaemnnosttv/wp-cli-dotenv-command, aaemnnosttv/wp-cli-login-command, 
# aaemnnosttv/wp-cli-valet-command, roots/bedrock, roots/sage
# 
# Thanks to Evan Mattson https://github.com/aaemnnosttv 
# 
sitename=$1
debug=$2


#global varables
# set to your default personal perfences
wpuser='sysad'
wpemail='daniel@thedjdesign.com'
# setting path for project folders
path=$HOME/sites



# /*=============================================
# =  No need to Modify below this point         =
# =============================================*/



# generate random 12 character password
wppass=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)
# copy password to clipboard
echo $wppass | pbcopy

# set db name
dbname=wp_$sitename

# accept the name of our website
echo "Site Name: "
read -e sitetitle

# accept a comma separated list of pages
echo "Add Pages: "
read -e allpages

# add a simple yes/no confirmation before we proceed active secure
echo "Want a secure website? (y/n)"
read -e secure

# add sage theme?
echo "Want to install roots.io sage them? (y/n)"
read -e sagetheme

# add a simple yes/no confirmation before we proceed
echo "Run Install? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
	exit
else

if [[ "$debug" == "--debug" ]]; then
	debugmode=''
else
	debugmode='--quiet'
fi

	# -----------[CONDITIONAL CHECKS]--------------------------------------
	
	# checking if sitename is set
	if [ -z $sitename ]; then
		echo "Missing parameter SITENAME: $1 "
		echo "Correct Usage: valet-roots SITENAME"
		exit
	fi
	# checks if local folders sites and valet exist
	if [[ ! -d "~/sites" && -d "~/sites/valet" ]]; 
		then
		# creating site hosts folder if does not exist
		mkdir $path $path/valet
		valet park

		path=$HOME/sites/valet
		if [[ -d "$path/$sitename" ]]; then
			#site exists exit
			echo "\"$sitename\" already exists... now exiting"
			exit 0
		else
			echo "Creating site $sitename.dev"
			cwd=$path
			cd $path
		fi
	else
		path=$HOME/sites/valet
		if [[ -d "$path/$sitename" ]]; then
			#statements
			echo "\"$sitename\" already exists in $path/$sitename... now exiting"
			exit 0
		else
			echo "Creating site $sitename.dev"
			cwd=$path
		fi
	fi

	# check is sql is active else start
	if [[ $(mysql.server status | grep 'not running') ]]; then
		mysql.server start
	fi

	# Current working directory
	cwd=$path/$sitename
	themepath=web/app/themes/$sitename

	# if the user didn't say no, then go ahead with secure mode
	if [[ "$secure" == y ]]; then
	    http='https'
	else
		http='http'
	fi

	# checks if wp cli (dotenv, login, valet) exists if not install which is needed for next steps
	if [[ ! $(wp package list | grep aaemnnosttv/wp-cli-dotenv-command) ]]; then
		wp package install aaemnnosttv/wp-cli-dotenv-command
	fi	
	if [[ ! $(wp package list | grep aaemnnosttv/wp-cli-login-command) ]]; then
		wp package install aaemnnosttv/wp-cli-login-command
	fi
	if [[ ! $(wp package list | grep aaemnnosttv/wp-cli-valet-command) ]]; then
		wp package install aaemnnosttv/wp-cli-valet-command
	fi

	# check if db exists if so drop and create
	mysql -u root -e "DROP DATABASE IF EXISTS $dbname"
	
	# install bedrock
	wp valet new $sitename --project=bedrock --in=$path --admin_user=$wpuser --admin_password=$wppass --admin_email=$wpemail
	cd $cwd && wp dotenv salts generate && wp dotenv list

	# discourage search engines
	wp option update blog_public 0

	# show only 6 posts on an archive page
	wp option update posts_per_page 6

	# delete sample page, and create homepage
	wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="sample-page" --field=ID --format=ids)
	wp post create --post_type=page --post_title=Home --post_status=publish --post_author=$(wp user get $wpuser --field=ID --format=ids)

	# set homepage as front page
	wp option update show_on_front 'page'

	# set homepage to be the new page
	wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids)

	# create all of the pages
	export IFS=","
	for page in $allpages; do
		wp post create --post_type=page --post_status=publish --post_author=$(wp user get $wpuser --field=ID --format=ids) --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')"
	done


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
	wp rewrite structure '/%postname%/'
	wp rewrite flush

	# delete akismet and hello dolly
	wp plugin delete akismet hello	
	
	# install automated login magic links
	composer require aaemnnosttv/wp-cli-login-server && wp login toggle on


	if [[ "$sagetheme" == y ]]; then
		
		composer create-project roots/sage $themepath dev-master --yes
		cd $themepath 
		npm -s install
		sed "s/http://example.dev/$(wp dotenv get WP_HOME --path=$cwd)/g"
		npm -s run build
		wp theme activate $sitename

	fi

	clear


	echo "================================================================="
	echo "Installation is complete. Your username/password is listed below."
	echo ""
	echo "Username: $wpuser"
	echo "Password: $wppass"
	echo ""
	echo "================================================================="

	wp login create $wpuser --launch

fi
