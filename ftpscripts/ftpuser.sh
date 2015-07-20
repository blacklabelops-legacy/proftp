#!/bin/sh
###################################################################################
############################## SOME VARIABLES #####################################

USERNAME=
ID=
FILEPATH=/var/ftp
QUOTA=


###################################################################################
#############################  SOME FUNCTIONS #####################################

function set_rights {

chown nobody:nobody $FILEPATH/ftpd.*
chmod +rw $FILEPATH/ftpd.*
chmod o-rwx $FILEPATH/ftpd.*

}

# Let UID and GUID will be the same 
function get_last_id {

tail -1 $FILEPATH/ftpd.passwd |awk -F: '{print $3}'

}

function get_id_by_username {

 awk -v username=$USERNAME -F: '{if ($1==username) print $3}' $FILEPATH/ftpd.passwd

}

function user_existance_check {

awk -v username=$USERNAME  -F: '{ if($1==username) exit 1}' $FILEPATH/ftpd.passwd  

}

function tech_user_existance_check {

awk -v username=$TECH_USERNAME  -F: '{ if($1==username) exit 1}' $FILEPATH/ftpd.passwd  

}

function check_if_disabled {

awk -v username=$USERNAME  -F: '{ if($1==username) if($2 ~ "DISABLED") exit 1 }' $FILEPATH/ftpd.passwd

}

function ftpasswd_use {


	sudo -u nobody ftpasswd --passwd --file=$FILEPATH/ftpd.passwd --name=$USERNAME \
	--shell=/sbin/nologin --home=${FILEPATH}/${USERNAME} --uid $ID --gid 99


}


function ftpasswd_tech_use {


	sudo -u nobody ftpasswd --passwd --file=$FILEPATH/ftpd.passwd --name=$TECH_USERNAME \
	--shell=/sbin/nologin --home=${FILEPATH}/${USERNAME} --uid $ID --gid 100


}

function checkargs {

if [[ $OPTARG =~ ^-[hutq]$ ]]
then
	echo "Unknow argument $OPTARG for option $opt!"
	exit 1
fi

}

function usage {

	echo "Usage: $0 -u USERNAME"; 

}

function usage_quota {

	echo "Usage: $0 -u USERNAME -q MB_OF_QOUTA "; 

}

function usage_tech {

	echo "Usage: $0 -u Username -t TechUsername "; 

}


function list_techuser() {

	awk -F: '{ if( $4=="100" ) print $1"  "$5}' $FILEPATH/ftpd.passwd

}

###################################################################################
## Function from CASE

#############################

function addftpuser {
if ! user_existance_check
then
# User exist. 
        echo -e "\t\tUser already exist. Choose different username"



else
# There are no user like this . Create new one
        let "ID = $(get_last_id) + 1"
        echo -e "\t\tCreate new user $USERNAME"
        echo -e "\t RANDOM PASSWD: $(tr -dc A-Za-z0-9_ < /dev/urandom | head -c 8  | xargs)"

        set_rights
        ftpasswd_use
        set_rights

        mkdir ${FILEPATH}/${USERNAME}
        chmod 775 ${FILEPATH}/${USERNAME}
	chown nobody:nobody ${FILEPATH}/${USERNAME}
	
	echo -e "\n\n\tDon't forget to set up quota to that user! Use command like this"
	echo -e "\tquotaftpset -u $USERNAME -q QUOTA"
fi

}

#############################

function addtechuser {

if [[ -z $TECH_USERNAME ]]
then
	usage_tech;
	exit 1;
fi


if ! tech_user_existance_check
then
# User exist. 
        echo -e "\t\tUser already exist. Choose different username"



else
# There are no user like this . Create new one

	if ! user_existance_check
	then

        	let "ID = $(get_last_id) + 1"
        	echo -e "\t\tCreate new user $TECH_USERNAME"
        	echo -e "\t RANDOM PASSWD: $(tr -dc A-Za-z0-9_ < /dev/urandom | head -c 8  | xargs)"

        	set_rights
        	ftpasswd_tech_use
        	set_rights
		ftpquota --add-record --type=limit --quota-type=user  \
                --table-path /var/ftp/ftpquota.limittab \
                --bytes-upload=1 --name=$TECH_USERNAME

	else
		echo "No such user exist"	

	fi
fi

}

#############################

function chpassftpuser {
if ! user_existance_check
then
# User exist. Change passwd to him
        ID=$(get_id_by_username)
        echo -e "\t\tUpdate password to $USERNAME"

        set_rights
        ftpasswd_use
        set_rights


else
# There are no user like this . Create new one
        echo -e "\t\User does not  exists. Create new one at first"

fi

}

#############################

function removeftpuser {
if ! user_existance_check
then
# User exist. Delete him
	sed -i "/^${USERNAME}:/d" $FILEPATH/ftpd.passwd
	rm -rf ${FILEPATH}/${USERNAME}

else
# There are no user like this.
	echo -e "There are no user like this"

fi

}

#############################

function disableftpuser {

if ! user_existance_check
then
# User exist. Disable him
	if ! check_if_disabled
	then
	# User already disabled
		echo "User already disabled"
	else
	# He is enbled. Disable him
        	echo "User ${USERNAME}  disabled"
		sed -i "s/^${USERNAME}:/${USERNAME}:DISABLED/" $FILEPATH/ftpd.passwd
	fi

else
# There are no user like this.
        echo -e "There are no user like this"

fi



}

#############################

function enableftpuser {

if ! user_existance_check
then
# User exist. Enable him
        if ! check_if_disabled
        then
        # User  disabled. Enable him
	echo "User ${USERNAME} enabled"
	sed -i "s/^${USERNAME}:DISABLED/${USERNAME}:/" $FILEPATH/ftpd.passwd
	else
	# User already enabled
	echo "User already enabled"

	fi

else
# There are no user like this.
        echo -e "There are no user like this"

fi


}

#############################

function quotaftpset {

if ! user_existance_check
then
# User exist. 

	if [[ -z $QUOTA ]] 
	then 
	
	usage_quota;exit1

	else
		ftpquota --add-record --type=limit --quota-type=user --units=Mb \
		--table-path /var/ftp/ftpquota.limittab \
		--bytes-upload=$QUOTA --name=$USERNAME
	fi
else
# There are no user like this.
        echo -e "There are no user like this"

fi



}

#############################

function list {
clear
printf "%20s   %20s   %20s   %20s" "Username" "Status" "Quota limit" "Quota used"
echo  -e "\n_____________________________________________________________________________________________\n"

for USER in $(awk -F: '{ if( $4=="99" ) print $1}' $FILEPATH/ftpd.passwd)
do

	local STATUS=$(awk -v username=$USER  -F: '{ if($1==username) if($2 ~ "DISABLED") print "DISABLED" ; else print "ENABLED"   }' $FILEPATH/ftpd.passwd)
	local LIMIT=$(ftpquota --show-records --units=Mb --type=limit --table-path /var/ftp/ftpquota.limittab| grep -A4 "${USER}$" | grep "Uploaded Mb:" | awk '{print $3}' )
	local USED=$(ftpquota --show-records --units=Mb --type=tally --table-path /var/ftp/ftpquota.tallytab | grep -A4 "${USER}$" | grep "Uploaded Mb:" | awk '{print $3}' )

	printf "%20s   %20s   %20s   %20s" $USER $STATUS $LIMIT $USED
	
echo 

done
echo  -e "\n_____________________________________________________________________________________________\n\t\tTech USERS:"

list_techuser

}

#############################

###################################################################################
############################## ARGUMENTS ##########################################

while getopts "u:hq:t:" opt
do
  case "$opt" in
         h)  usage;exit ;;
         u) checkargs;
		 USERNAME=$OPTARG;
	 ;;
	 t) checkargs;
		TECH_USERNAME=$OPTARG;
	 ;;
	 q) checkargs;
		QUOTA=$OPTARG;
	 ;;
         ?) usage;exit 2;;
  esac
done


if [[ -z $1 ]] ; then
        list; exit 0
fi


if [[ -z $USERNAME ]] ; then
	usage; exit 1
fi

###################################################################################
############################### Script ############################################


case $0 in
	
	*addftpuser)  addftpuser
			;;
	*addtechuser) addtechuser
			;;
	*removeftpuser) removeftpuser
			;;
	*disableftpuser) disableftpuser
			;;
	*enableftpuser)  enableftpuser
			;;	
	*chpassftpuser) chpassftpuser 
			;;
	*quotaftpset) quotaftpset
			;;
	*) list
			;;
esac



