#!/usr/bin bash

## Assumptions
# An ssh key is available to connect to the remote machine
# You are running this from the destination (local) machine or its host if docker

#utility vars
date_stamp=$(date +%Y%m%d%H%M%S)
starttime=$(date +%s)
conf_file=craft-down-sync.conf

# Pull in config
if [[ ! -s "$conf_file" ]] ; then
    echo "Config file ${conf_file} missing!"
    exit 1;
fi

if [[ ! -s "functions.sh" ]] ; then
    echo "Functions script is missing!"
    exit 1;
fi
. "functions.sh"
_success "Functions loaded"
. "$conf_file"
_success "Config file loaded"
_note "Starting at $(date +%Y-%m-%d-%H:%M:%S)"


_header "****** Using $conf_file to begin down sync from ${remote_ssh_host} ******"

# Run validators and tests
_arrow "Validations Starting"
_testRequiredCmds
_validateSsh ${remote_ssh_host} ${remote_ssh_port}
_testMysql
_testFs
_note "Validations Complete"

# Backup local db ##################################################
_header "Local DB Backup"
if [[ ${local_uses_docker} == '1' ]] ; then
    docker exec -i ${local_db_container} "bin/bash -c ${local_mysqldump_cmd} ${local_mysql_creds_and_dbname} ${local_excluded_tables_string} ${mysqldump_args} | gzip " | pv > ${local_db_dump_dir}${local_db_dump_file_name}_${date_stamp}.sql.gz 2>/dev/null
else
    ${local_mysqldump_cmd} ${local_mysql_creds_and_dbname} ${local_excluded_tables_string} ${mysqldump_args} | gzip | pv > ${local_db_dump_dir}${local_db_dump_file_name}_${date_stamp}.sql.gz 2>/dev/null
fi
_errorExitPromptNoSuccessMsg $? "Local DB backup did not return a 0 result! Continue anyway?"

if [[ ! -s "${local_db_dump_dir}${local_db_dump_file_name}_$date_stamp.sql.gz" ]]; then
    _die "Local DB dump failed! Aborting!"
fi
_success "Local DB backup complete, file is "${local_db_dump_dir}${local_db_dump_file_name}_$date_stamp.sql.gz" with size of $((`du -k ${local_db_dump_dir}${local_db_dump_file_name}_$date_stamp.sql.gz | cut -f1` / 1024))MB"

# confirmation prompt example
#echo "Do you wish to pull down the remote db now?"
#select yn in "Yes" "No"; do
#  case $yn in
#    Yes ) break;;
#    No ) _safeExit;;
#  esac
#done

# Pull down remote db ##################################################
_header "Remote DB backup and pull"
remote_backup_file_path="${local_db_dump_dir}${remote_db_dump_file_name}_${date_stamp}.sql.gz"
ssh -p ${remote_ssh_port} $remote_ssh_user@$remote_ssh_host "${remote_mysqldump_cmd} ${remote_mysql_creds_and_dbname} ${remote_excluded_tables_string} ${mysqldump_args} | gzip -9" | pv > ${remote_backup_file_path}
_errorExitPromptNoSuccessMsg $? "DB backup and or pull from remote did not return a 0 result! Continue anyway?"

if [[ ! -s "${local_db_dump_dir}${remote_db_dump_file_name}_${date_stamp}.sql.gz" ]]; then
    _die "Remote DB dump failed! Aborting!"
fi
_success "Remote DB pulled down to "${remote_backup_file_path}" with size of $((`du -k ${remote_backup_file_path} | cut -f1` / 1024))MB"



# Start local processing ##################################################
_header "Begin local processing"

if [[ ${local_uses_docker} == '1' ]]; then
    zcat "${remote_backup_file_path}" | docker exec -i ${local_db_container} "${local_mysql_cmd} ${local_mysql_creds_and_dbname}"
else
    zcat "${remote_backup_file_path}" | ${local_mysql_cmd} ${local_mysql_creds_and_dbname}
fi
_errorExitPromptNoSuccessMsg $? "DB restore did not return a 0 result! Continue anyway?"
_success "Remote backup restored from file ${remote_backup_file_path}"

# Composer install? npm build? nuke static files? These are things we aren't doing here atm

# Config Sync ##################################################
if [[ ${sync_config} == '1' ]]; then
    _arrow "Syncing config from remote"
    rsync -az -e "ssh -p ${remote_ssh_port}" --progress $remote_ssh_user@$remote_ssh_host:$remote_config_path $local_config_path
    _errorExitPromptNoSuccessMsg $? "Rsync did not return a 0 result! Continue anyway?"
    _success "config sync complete"
fi

# Done ##################################################
_success "Finished at $(date +%Y-%m-%d-%H:%M:%S)"
endtime=$(date +%s)
deltatime=$(($endtime - $starttime))
_note "Time elapsed was "$(_convertsecs $deltatime)
_safeExit