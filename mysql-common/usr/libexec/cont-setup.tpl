#!/bin/bash

# This function returns all config files that daemon uses and their path
# includes /opt. It is used to get correct path to the config file.
mysql_get_config_files_scl() {
    scl enable {{ collection }} -- my_print_defaults --help --verbose | \
        grep --after=1 '^Default options' | \
        tail -n 1 | \
        grep -o '[^ ]*opt[^ ]*my.cnf'
}

# This function picks the main config file that deamon uses and we ship in rpm
mysql_get_correct_config() {
    # we use the same config in non-SCL packages, not necessary to guess
    [ -z "{{ collection }}" ] && echo -n "/etc/my.cnf" && return

    # from all config files read by daemon, pick the first that exists
    for f in `mysql_get_config_files_scl` ; do
        [ -f "$f" ] && echo "$f"
    done | head -n 1
}

export MYSQL_CONFIG_FILE=$(mysql_get_correct_config)

[ -z "$MYSQL_CONFIG_FILE" ] && echo "MYSQL_CONFIG_FILE is empty" && exit 1

unset -f mysql_get_correct_config mysql_get_config_files_scl

# API of the container are standard paths /etc/my.cnf and /etc/my.cnf.d
if [ "$MYSQL_CONFIG_FILE" != "/etc/my.cnf" ] ; then
    rm -rf /etc/my.cnf /etc/my.cnf.d
    ln -s ${MYSQL_CONFIG_FILE} /etc/my.cnf
    ln -s ${MYSQL_CONFIG_FILE}.d /etc/my.cnf.d
fi

# comment out log-error from the config, by default the daemon should log to stderr
sed -ie 's/^\([^#]*log[-_]error=.*\)$/# logging to stderr \n# \1/g' ${MYSQL_CONFIG_FILE}

# we may add options during service init, we need to have this dir writable
chown -R mysql:mysql ${MYSQL_CONFIG_FILE}.d
restorecon -R ${MYSQL_CONFIG_FILE}.d

# we provide own config files for the container, so clean what rpm ships here
rm -f ${MYSQL_CONFIG_FILE}.d/*

# setup directory for data, log file and pid file
for dir in /var/lib/mysql{,/data} $(dirname {{ logfile }}) $(dirname {{ pidfile }}) ; do
    mkdir -p $dir
    chown -R mysql:mysql $dir
    restorecon -R $dir
done
