# BlackLabelOps/ProFTP

Dockerfile  and support scripts to create and manage container with ProFTPd. ProFTPd container provides active ftp and scripts for user management.

* Setting Users and Quotas
* Add read-only Technical Users

## Instant Usage

~~~~
docker run -d -p 42042:21 --name="proftp_proftp_1" blacklabelops/proftp
~~~~

> FTP will be available on port 42042.

## Usage

This container includes all the required scripts for container management. Simply clone the project and enter the described commands in your project directory.

### Project Usage

This project can be used from the command line, by bash scripts and the Docker-Compose tool. It's recommended to use the scripts for container management.

#### Run Recommended

~~~~
$ ./scripts/run.sh
~~~~

> This will run the container with the configuration scripts/container.cfg

#### Run Docker-Compose

~~~~
$ docker-compose -d up
~~~~

> This will run the container detached with the configuration docker-composite.yml

#### Build Recommended

~~~~
$ ./scripts/build.sh
~~~~

> This will build the container from scratch with all required parameters.

#### Build Docker-Compose

~~~~
docker-compose -f docker-compose-dev.yml build
~~~~

> This will build the container according to the docker-compose-dev.yml file.

#### Build Docker Command Line

~~~~
docker build -t="blacklabelops/proftp" .
~~~~

> This will build the container from scratch.

## Container scripts

Scripts that run inside docker container for user management. Type the following in order to start the containers bash console.

~~~~
$ ./scripts/mng.sh
~~~~

List of available symlinks:

* addftpuser - Adding ftp user
* removeftpuser - remove ftp user
* disableftpuser - Disable ftp user
* enableftpuser - Enable ftp user
* chpassftpuser - Change user passwords
* quotaftpset - Set user upload quota
* addtechuser - Add technical user with limited rights

## User Management

All scripts for require one argument - Username. You can specify username with -u flag. Example:

```
$ chpassftpuser -u SomeUserName
```

`quotaftpset` also require users quota value in Mb. You can specify quota with -q flag. Example:


```
$ quotaftpset -u UserWithQuota -q 100
```

To view existing users run any of custom scripts described earlier.

```
$ removeftpuser
            Username                 Status            Quota limit             Quota used
_____________________________________________________________________________________________

             ftpuser                ENABLED


```
Add few new users.

```
$ addftpuser -u newuser1
                Create new user newuser1
         RANDOM PASSWD: e1esAcfp
ftpasswd: using alternate file: /var/ftp/ftpd.passwd
ftpasswd: creating passwd entry for user newuser1

Password:
Re-type password:

ftpasswd: entry created


        Don't forget to set up quota to that user! Use command like this
        quotaftpset -u newuser1 -q QUOTA
$ addftpuser -u newuser2
                Create new user newuser2
         RANDOM PASSWD: aLtXobNq
ftpasswd: using alternate file: /var/ftp/ftpd.passwd
ftpasswd: creating passwd entry for user newuser2

Password:
Re-type password:

ftpasswd: entry created


        Don't forget to set up quota to that user! Use command like this
        quotaftpset -u newuser2 -q QUOTA
$ addftpuser
            Username                 Status            Quota limit             Quota used
_____________________________________________________________________________________________

             ftpuser                ENABLED
            newuser1                ENABLED
            newuser2                ENABLED
```

Don't forget to set up upload quota. Note that quota will be implemented on next login.

```
$ quotaftpset -u newuser2 -q12
$ quotaftpset
            Username                 Status            Quota limit             Quota used
_____________________________________________________________________________________________

             ftpuser                ENABLED
            newuser1                ENABLED
            newuser2                ENABLED                  12.00
$

```
Check out quota.

```
$ ftp 172.16.172.1
Connected to 172.16.172.1.
220 ProFTPD 1.3.5 Server (ProFTPD Default Installation) [172.17.0.85]
Name (172.16.172.1:stepan): newuser2
331 Password required for newuser2
Password:
230 User newuser2 logged in
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
200 PORT command successful
150 Opening ASCII mode data connection for file list
226 Transfer complete
ftp> put 10mb
local: 10mb remote: 10mb
200 PORT command successful
150 Opening BINARY mode data connection for 10mb
226 Transfer complete
10485760 bytes sent in 2.41 secs (4255.2 kB/s)
ftp> put 5mb
local: 5mb remote: 5mb
200 PORT command successful
150 Opening BINARY mode data connection for 5mb
netout: Broken pipe
552 Transfer aborted. Disk quota exceeded
ftp> ls
200 PORT command successful
150 Opening ASCII mode data connection for file list
-rw-r--r--   1 newuser2 99       10485760 Jan 26 20:46 10mb
226 Transfer complete
ftp> quit
221 Goodbye.
$

```
On container side.

```
[root@d2c011134a44 /]# quotaftpset
            Username                 Status            Quota limit             Quota used
_____________________________________________________________________________________________

             ftpuser                ENABLED
            newuser1                ENABLED
            newuser2                ENABLED                  12.00                  10.00
[root@d2c011134a44 /]#
```

Disable newuser2

```
$ disableftpuser -u  newuser2
User newuser2  disabled
$ disableftpuser
            Username                 Status            Quota limit             Quota used
_____________________________________________________________________________________________

             ftpuser                ENABLED
            newuser1                ENABLED
            newuser2               DISABLED                  12.00                  10.00
```

Try to login with newuser2 account.

```
$ ftp 172.16.172.1
Connected to 172.16.172.1.
220 ProFTPD 1.3.5 Server (ProFTPD Default Installation) [172.17.0.85]
Name (172.16.172.1:stepan): newuser2
331 Password required for newuser2
Password:
530 Login incorrect.
Login failed.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> exit
221 Goodbye.
```

Enable user.

```
$ enableftpuser -u newuser2
User newuser2 enabled
$ enableftpuser
            Username                 Status            Quota limit             Quota used
_____________________________________________________________________________________________

             ftpuser                ENABLED
            newuser1                ENABLED
            newuser2                ENABLED                  12.00                  10.00
```

Check.

```
$ ftp 172.16.172.1
Connected to 172.16.172.1.
220 ProFTPD 1.3.5 Server (ProFTPD Default Installation) [172.17.0.85]
Name (172.16.172.1:stepan): newuser2
331 Password required for newuser2
Password:
230 User newuser2 logged in
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
200 PORT command successful
150 Opening ASCII mode data connection for file list
-rw-r--r--   1 newuser2 99       10485760 Jan 26 20:46 10mb
226 Transfer complete
ftp> quit
221 Goodbye.
```

And tech user adding example:

```
Usage: /usr/bin/addtechuser -u Username -t TechUsername

$ addtechuser -u ftpuser -t tech
```

## Docker Wrapper Scripts

Convenient wrapper scripts for container and image management. The scripts manage one container. In oder to manage multiple containers, copy the scripts and adjust the container.cfg.

Name              | Description
----------------- | ------------
build.sh          | Build the container from scratch.
run.sh            | Run the container.
start.sh          | Start the container from a stopped state.
stop.sh           | Stop the container from a running state.
rm.sh             | Kill all running containers and remove it.
rmi.sh            | Delete container image.
mng.sh            | Manage the docker volume from another container.

> Simply invoke the commands in the project's folder.

## Feature Scripts

Feature scripts for the container. The scripts manage one container. In oder to manage multiple containers, copy the scripts and adjust the container.cfg.

Name              | Description
----------------- | ------------
logs.sh  | Downloads logs file from container
backup.sh         | Backups docker volume from container
restore.sh        | Restore the backup into container

> The examples are executed from project folder.

### logs.sh

This script will search for configured docker container. If no container
found, an error message will be shown. Otherwise, an jenkins logs will be
copied by default into 'logs' folder with following file name and timestamp.

~~~~
$ ./scripts/logs.sh
~~~~

> The log file with timestamp as name und suffix ".log" can be found in the project's logs folder.

### backup.sh

Backup of docker volume in a tar archive.

~~~~
$ ./scripts/backup.sh
~~~~

> The backups will be placed in the project's backups folder.

### restore.sh

Restore container from a tar archive.

~~~~
$ ./scripts/restore.sh ./backups/ProFTPBackup-2015-03-08-16-28-40.tar
~~~~

> A temp container will be created and backup file will be extracted into docker volume. The container will be stopped and restartet afterwards.

## Managing Multiple Containers

The scripts can be configured for the support of different containers on the same host manchine. Just copy and paste the project and folder and adjust the configuration file scripts/container.cfg

Name              | Description
----------------- | ------------
CONTAINER_NAME    | The name of the docker container.
IMAGE_NAME         | The name of the docker image.
HOST_PORT        | The exposed port on the host machine.
BACKUP_DIRECTORY | Change the backup directory.
LOGFILE_DIRECTORY | Change the logs download directory.
FILE_TIMESTAMP | Timestamp format for logs and backups.

> Note: CONTAINER_VOLUME must not be changed.

## Docker-Compose

This project supports docker-compose. The configuration is inside the docker-compose.yml file.

Example:

~~~~
$ docker-compose -d up
~~~~

> Starts a detached docker container.

Consult the [docker-compose](https://docs.docker.com/compose/) manual for specifics.

# Support

Leave a message and ask questions on Hipchat: [blacklabelops/hipchat](http://support.blacklabelops.com)

# References

* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
* [ProFTP Homepage](http://www.proftpd.org/)


