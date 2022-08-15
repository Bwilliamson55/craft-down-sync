# Craft CMS 3 and 4 down-sync

Pull a specific database, and configuration folder from a Craft CMS remote environment into a local one.
Local DB is backed up prior to replacement, config folder is not.

## Description

This is a script to synchronize a remote Craft CMS installation with a local one, or a local docker container.
Currently, this only connects to the remote via SSH key for both mysqldump and rsync.
I've attempted to make the configuration and function files as straight forward as possible; I've found and taken inspiration from many projects, but they all had one thing in common:
**Too much crap**

So, this is an attempt at a 'boiled down', to the point script. Most of the over-engineering I've found in similar projects is appropriate solutions to edge cases or customization needs per-project. 
This is not that. This is for a specific type of set up, which you can of course modify to fit your needs.

## Getting Started
This script is not dependent on being in any specific location, just that it's in the same location as the `functions.sh` and `craft-down-sync.conf`  
I keep this in my `<project root dir>/scripts` folder, but again, put this anywhere you like.

### Dependencies
This is first and foremost a ***bash*** script.
This was built on Ubuntu 20.04, but should work with any POSIX capable system.
Mysql8.0 and Bash 5 (I avoided asoc arrays) were used during testing, but hopefully not required.

The script tests for local command/bin dependencies:  
- mysql
- mysqldump
- zcat
- ssh
- pv
- rsync
- cut
- du  

You can add to the list of cmds tested before execution in the `.conf`

### Installing and Running

- Place these files in any folder you like
- Closely examine the `example.conf` to see what types of information you need to gather
  - The variables are named and notated helpfully, or there was an attempt
  - This expects a single remote environment, and a single local environment
    - The local environment can toggle `local_uses_docker` from `=0` to `=1` in the `conf` so that the `mysql` and `mysqldump` commands are prefaced with `docker exec -i ${local_container_name}`
      - This may need some tweaking for your specific set up, eg your container would need mysqldump and gzip
    - If you're not using docker, you can ignore the `#docker` section of the config
- Copy the `example.conf` to `craft-down-sync.conf` and configure for your environments
- ***Warning*** this is a destructive process!
The local DB is backed up prior to clobbering with the remote DB, but the `config` folder is not! ***I recommend pulling config to a separate folder locally to diff by hand at first***
- Run `bash craft-down-sync.sh`
  - The script should stop and warn you about anything that doesn't work right, but allow you to continue if you want.
    - The first few runs you may need to tweak the config or script itself to meet your needs

## Help

I've made an attempt at putting helpful notes in the files here, but sometimes you only know if you know.  
Ask questions, and I'll attempt to answer if Google can't get you there.

## Authors

[@Bwilliamson55](https://github.com/bwilliamson55)

## Version History

* 0.1
    * Initial Release

## TODO:

- Add optional DB-backup-file wipe after restore (For PII reasons)

## License

This project is distributed under the [MIT License](https://spdx.org/licenses/MIT.html).

## Acknowledgments

Inspiration, code snippets, etc. (I made a version of this for Magento 2 as well)
* [clivewalkden/bash-magento2-db-sync](https://github.com/clivewalkden/bash-magento2-db-sync/blob/master/db-sync.sh) This is a good example of component-izing sh scripts
* [MagePsycho/magento2-db-code-backup-bash-script](https://github.com/MagePsycho/magento2-db-code-backup-bash-script/blob/master/src/mage2-db-code-backup.sh) another simple example with some prettified stuff
* [MAD-I-T/magento-actions](https://github.com/MAD-I-T/magento-actions) good repo with lots of scripts to learn from
* [erikhansen](https://gist.github.com/erikhansen/26e59f8c8de749790d146bb48a7d6946) The newest forks of this have good examples on anonymizing and stripping / sanitizing data. (Probably not that relevant for this)
* [nystudio107/craft-scripts](https://github.com/nystudio107/craft-scripts/blob/master/scripts/backup_db.sh) - Nystudio107 is always my first stop along with-
* [Craft Quest](https://craftquest.io/) Craft Quest isn't necessarily bash related, but essential to my learning journey with Craft