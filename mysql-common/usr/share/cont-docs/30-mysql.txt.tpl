{{ name }} Docker Image based on {{ collection }} Software Collection
{{ '=' * (collection|length + 43 + name|length) }}

{{ name }} is a multi-user, multi-threaded SQL database server. It is a
client/server implementation consisting of a server daemon (mysqld)
and many different client programs and libraries. This docker image contains
the {{ name }} server and some accompanying files and directories.

The Docker image includes packages from Software Collections (SCL).
For more information about Software Collections, see
http://softwarecollections.org.


Environment variables and volumes
----------------------------------

The image recognizes following environment variables that you can set during
initialization, by passing `-e VAR=VALUE` to the Docker run command.

|    Variable name       |    Description                            |
| :--------------------- | ----------------------------------------- |
|  `MYSQL_USER`          | User name for MySQL account to be created |
|  `MYSQL_PASSWORD`      | Password for the user account             |
|  `MYSQL_DATABASE`      | Database name                             |
|  `MYSQL_ROOT_PASSWORD` | Password for the root user (optional)     |

You can also set following mount points by passing `-v /host:/container` flag to docker.

|  Volume mount point      | Description          |
| :----------------------- | -------------------- |
|  `/var/lib/mysql/data`   | MySQL data directory |


Usage
-----

To just run the dameon and not store the database in a host directory,
you need to execute the following command:

```
# docker run -d -p 3306:3306 THIS_IMAGE
```

This will run the daemon in default configuration and port 3306 will be
exposed and mapped to host.

It is recommended to use run the container with mounted data directory everytime.
This example shows how to run the container with `/host/data` directory mounted
and so the database will store data into this directory on host:

```
docker run -d -v /host/data:/var/lib/mysql/data THIS_IMAGE
```

This will create a container running {{ name }} daemon
and storing data into `/host/data` on the host.

For debugging purposes or just connecting to the running container, run
`docker exec -ti CONTAINERID container-entrypoint` in a separate terminal.

You can stop the detached container by running `docker stop CONTAINERID`.


Database initialization
-----------------------

If the database directory is not initialized, the container script will first
run [`mysql_install_db`](https://dev.mysql.com/doc/refman/5.5/en/mysql-install-db.html)
during start and setup necessary database users and passwords. After the database is
initialized, or if it was already present, `mysqld` is executed and will run as PID 1.

To pass arguments that are used for initializing the database if it is not yet
initialized, define them as environment variables

```
docker run -d -e MYSQL_USER=user -e MYSQL_PASSWORD=pass -e MYSQL_DATABASE=db THIS_IMAGE
```

This will create a container running {{ name }} with database
`db` and user with credentials `user:pass` that has access to the database `db`.


MySQL root user
---------------
The root user has no password set by default, only allowing local connections.
You can set it by setting `MYSQL_ROOT_PASSWORD` environment variable when initializing
your container. This will allow you to login to the root account remotely. Local
connections will still not require password.


