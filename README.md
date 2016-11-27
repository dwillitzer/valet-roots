# valet-roots
Created an easy bedrock project builder for easier local wordpress deployment with valet + bedrock + sage (optional)

**Requirements**: MacOS, [laravel valet](https://laravel.com/docs/5.3/valet#installation), php 5.6>, [mariadb 10.1.16>](), [wp-cli}(https://wp-cli.org), [composer](https://garthkerr.com/composer-install-on-os-x-10-11-el-capitan/), [npm](http://blog.teamtreehouse.com/install-node-js-npm-mac)
Before using the valet-roots script, You should follow this setup guide to prepare your mac. [link](https://scotch.io/tutorials/use-laravel-valet-for-a-supe
r-quick-dev-server)
### Usage
1. Open terminal download the script.
2.  Set proper permissions on script using
 `chmod a+x valet-roots.sh`
3.  Next, a few modifications are needed so you need to set open up the script in your favorite text editor. 
 - set the default username, email, & path you want
 - _Path_: set this to where you set your valet sites folder home is.
 - Save modifcations and preferences.
4.  Time to run your script.
`$ bash valet-roots.sh sitename`

> **Note:**
> - Replace `sitename` with the desired local domain and theme-name
> - Set a [bash alias](https://www.digitalocean.com/community/tutorials/an-introduction-to-useful-bash-aliases-and-functions) for the script for quicker deployment usage.

 **Github Projects used**
 _(credits for development to the following developers & companies)_
- [wp-cli/wp-cli](//github.com/wp-cli/wp-cli)
- [aaemnnosttv/wp-cli-dotenv-command](//github.com/aaemnnosttv/wp-cli-dotenv-command)
- [aaemnnosttv/wp-cli-login-command](//github.com/aaemnnosttv/wp-cli-login-command)
- [aaemnnosttv/wp-cli-valet-command](//github.com/aaemnnosttv/wp-cli-valet-command)
- [roots/bedrock](//github.com/roots/bedrock)
- [roots/sage](//github.com/roots/sage)
