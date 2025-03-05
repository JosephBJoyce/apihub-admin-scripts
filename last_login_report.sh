#!/bin/bash
#
# Last Login Report
#
# This script list Users and Last login date/time
#
# This script is not supported by SmartBear Software and is to be used as-is.
#
#   m. higgins    10/05/2022    inital coding (1.0.0)

API_NAME="last_login_report"
RELEASE="v1.0.0"

###################################################################################################
# check that jq is installed

if ! jq --help &> /dev/null; then
   echo " "
   echo "The Linux utility jq must be installed to use this script"
   exit 1
fi

###################################################################################################
# read config file

CONFIG_FILE=$HOME/.swaggerhub-bash.cfg

if [ -f $CONFIG_FILE ]; then
   BUFFER=$(jq -r '.' $CONFIG_FILE)
   IS_SAAS=$(echo $BUFFER | jq -r '.is_saas')
   FQDN=$(echo $BUFFER | jq -r '.fqdn')
   REGISTRY_FQDN=$(echo $BUFFER | jq -r '.registry_fqdn')
   MANAGEMENT_FQDN=$(echo $BUFFER | jq -r '.management_fqdn')
   ADMIN_FQDN=$(echo $BUFFER | jq -r '.admin_fqdn')
   API_KEY=$(echo $BUFFER | jq -r '.api_key')
   ADMIN_USERNAME=$(echo $BUFFER | jq -r '.admin_username')
   DEFAULT_ORG=$(echo $BUFFER | jq -r '.default_org')
else
   echo " "
   echo "No Config file found, please run make_swaggerhub_config.sh"
   exit 1
fi

if [ $IS_SAAS == "false" ]; then
   IDX=5
else
   IDX=4
fi

######################################################################################################
# process the command line arguements

if [ $# -ne 2 ]
then
   echo " "
   echo "Incorrect command line arguements."
   echo " "
   echo "usage: ./last_report.sh <admin-password> <print|csv>"
   echo " "
   exit 1
fi

ADMIN_PASSWORD=$1
OUTPUT=$2

case $OUTPUT in

   print) OK=true;;
   csv)   OK=true;;
   *)     echo "<output> must be one of print, csv";
          exit 1;;
esac

######################################################################################################
# begin

f="%-20.20s  %-35.35s  %-10.10s  %-8.8s\n"

if [ $OUTPUT == "print" ]; then
   echo " "
   echo "$API_NAME  ${RELEASE} - `date`"
   echo " "
   echo "                              User Last Login Report"
   echo " "
   printf "$f" "Username" "Email Address" "Login Date" "Time"
   printf "$f" "--------------------" "-----------------------------------" "----------" "--------"
fi

# get the admin token

WORK=$(curl -sk ${ADMIN_FQDN}/login                                                                   \
            -H 'Content-Type: application/json'                                                       \
            -H "User-Agent: $API_NAME"a                                                               \
            --data-binary "{\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}")

TOKEN=$(echo ${WORK} | grep -o '"token":\s*"[^"]*' | grep -o '[^"]*$')

if [ ${#TOKEN} -lt 5 ]; then
   echo "ERROR: Unable to retrieve admin token."
   exit 1
fi

# get the user payload

WORK=$(curl -sk ${ADMIN_FQDN}/admin/users  \
            -H "User-Agent: $API_NAME"     \
            -H "token: ${TOKEN}")

readarray -t UARR < <(echo $WORK | jq -r '.[].username')
readarray -t EARR < <(echo $WORK | jq -r '.[].email')
readarray -t LARR < <(echo $WORK | jq -r '.[].lastLoggedIn')

# loop the report

declare -A EMAIL_ARRAY
declare -A LOGIN_ARRAY

let i=0

for username in "${UARR[@]}"; do

   EMAIL_ARRAY[$username]="${EARR[$i]}"
   LOGIN_ARRAY[$username]="${LARR[$i]}"

   if [ $OUTPUT == "print" ]; then
      printf "$f" $username ${EARR[$i]} ${LARR[$i]:0:10} ${LARR[$i]:11:8}
   else
      echo "$username,${EARR[$i]},${LARR[$i]:0:10} ${LARR[$i]:11:8}"
   fi

   let i=$i+1

done

if [ $OUTPUT == "print" ]; then
   echo " "
   echo "*** End Report ***"
   echo " "
fi
