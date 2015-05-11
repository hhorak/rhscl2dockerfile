#!/bin/bash

# Get prefix rather than hard-code it
mysql_get_config_files_scl() {
    scl enable {{ collection }} -- my_print_defaults --help --verbose | \
        grep --after=1 '^Default options' | \
        tail -n 1 | \
        grep -o '.*opt[^ ]*my.cnf'
}

mysql_get_correct_config() {
    # we use the same config in non-SCL packages, not necessary to guess
    [ -z "{{ collection }}" ] && echo -n "/etc/my.cnf" && return

    for f in `mysql_get_config_files_scl` ; do
        echo "$f"
    done | grep -v mysql/my.cnf
}

export MYSQL_CONFIG_FILE=$(mysql_get_correct_config)

unset -f mysql_get_correct_config mysql_get_config_files_scl

# API of the container are standard paths /etc/my.cnf and /etc/my.cnf.d
if [ "$MYSQL_CONFIG_FILE" != "/etc/my.cnf" ] ; then
    rm -rf /etc/my.cnf /etc/my.cnf.d
    ln -s ${MYSQL_CONFIG_FILE} /etc/my.cnf
    ln -s ${MYSQL_CONFIG_FILE}.d /etc/my.cnf.d
fi

# we may add options during service init, we need to have this dir writable
chown -R mysql:mysql ${MYSQL_CONFIG_FILE}.d
restorecon -R ${MYSQL_CONFIG_FILE}.d

# setup directory for data, log file and pid file
for dir in /var/lib/mysql{,/data} $(dirname {{ logfile }}) $(dirname {{ pidfile }}) ; do
    mkdir -p $dir
    chown -R mysql:mysql $dir
    restorecon -R $dir
done
