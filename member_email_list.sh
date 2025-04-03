#!/bin/bash
#
# Member email list
#
# This script list all Members in all Organizations by role
#
# The Script uses the SwaggerHub User Management API.
#
# This script is not supported by SmartBear Software and is to be used as-is.
#
#   m. higgins    01/10/2023    inital coding (1.0.0)
#
 
RELEASE="v1.0.0"
API_NAME="member_email_list"

declare -A USER_ARR

###################################################################################################
# check that jq is installed

if ! jq --help &> /dev/null; then
   echo " "
   echo "The Linux utility jq must be installed to use this script"
   echo " "
   exit 1
fi

###################################################################################################
# read config file

CONFIG_FILE=$HOME/.swaggerhub-bash.cfg

if [ -f $CONFIG_FILE ]; then
   BUFFER=$(jq -r '.' $CONFIG_FILE)
   IS_SAAS=$(echo $BUFFER | jq -r '.is_saas')
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

######################################################################################################
# process the command line arguements

if [ $# -ne 1 ]
then
   echo " "
   echo "Incorrect command line arguements."
   echo " "
   echo "usage: ./$API_NAME.sh <print|csv>"
   echo "   <output> one of: print, csv"
   exit 1
fi

OUTPUT=$1

case $OUTPUT in

   print) OK=true;;
   csv)   OK=true;;
   *)     echo "<output> must be one of print, csv";
          exit 1;;
esac

######################################################################################################
# beginb

if [ $OUTPUT == "print" ]; then
   echo " "
   echo "$API_NAME  ${RELEASE}"
   echo " "
fi

######################################################################################################
# organization loop 


let p=0

STRING=$(curl -sk -X GET "$MANAGEMENT_FQDN/orgs?page=$p&pageSize=100"  \
                  -H "accept: application/json"                     \
                  -H "User-Agent: $API_NAME"                        \
                  -H "Authorization: Bearer $API_KEY")

TOTALCOUNT=$(echo $STRING | jq '.totalCount')
WORK=$(echo $STRING | jq '.items[].name')
NAME=($(echo $WORK | tr " " "\n" | tr -d "\""))

######################################################################################################
# members loop 

let i=0
let p=0

while [ $i -lt $TOTALCOUNT ]; do

   ORG=${NAME[$i]}

   if [ $OUTPUT == "print" ]; then
      echo "  >>>scanning: $ORG"
   fi

   STRING5=$(curl -sk -X GET "$MANAGEMENT_FQDN/orgs/$ORG/members?orgQueryBy=NAME&page=$p&pageSize=100" \
                      -H "accept: application/json"                                                    \
                      -H "User-Agent: $API_NAME"                                                       \
                      -H "Authorization: Bearer $API_KEY")

   REALCOUNT=$(echo $STRING5 | jq '.totalCount')

######################################################################################################
# members detail loop 

   let REALPAGES=($REALCOUNT/100)+1

   let k=0
   let lp=-1
 
   while [ $k -lt $REALPAGES ]; do
  
      let lp=$lp+1

      STRING2=$(curl -sk -X GET "$MANAGEMENT_FQDN/orgs/$ORG/members?orgQueryBy=NAME&page=$lp&pageSize=100" \
                         -H "accept: application/json"                                                     \
                         -H "User-Agent: $API_NAME"                                                        \
                         -H "Authorization: Bearer $API_KEY")

      WORK2=$(echo $STRING2 | jq '.items[].username')
      USERNAME=($(echo $WORK2 | tr " " "\n" | tr -d "\""))
   
      WORK3=$(echo $STRING2 | jq '.items[].role')
      ROLE=($(echo $WORK3 | tr " " "\n" | tr -d "\""))
   
      WORK4=$(echo $STRING2 | jq '.items[].startTime')
      JOINED=($(echo $WORK4 | tr " " "\n" | tr -d "\""))
   
      WORK5=$(echo $STRING2 | jq '.items[].lastActive')
      ACTIVE=($(echo $WORK5 | tr " " "\n" | tr -d "\""))
   
      WORK6=$(echo $STRING2 | jq '.items[].email')
      EMAIL=($(echo $WORK6 | tr " " "\n" | tr -d "\""))

      j=0
   
      while [ $j -lt $REALCOUNT ]; do
   
         OUTROLE=$(echo ${ROLE[$j]} | tr [:upper:] [:lower:])
         THISUSER=${USERNAME[$j]}
         if [ ${#THISUSER} -lt 2 ]; then
            THISUSER="Unknown"
         fi
         USER_ARR[$THISUSER]+="$ORG~$OUTROLE~${EMAIL[$j]}~${JOINED[$j]:0:10}~${ACTIVE[$j]:0:10},"
    
         let j=$j+1
         
      done  

      let k=$k+1

   done

   let i=$i+1

done  # organizations loop 

######################################################################################################
# report

TOTALMEMBERS=${#USER_ARR[@]}

if [ $OUTPUT == "print" ]; then
   echo " "
   echo "                                                MEMBER ACTIVITY REPORT"
   echo " "
   echo "Total Organizations: $TOTALCOUNT"
   echo "Total Members      : $TOTALMEMBERS"
   echo " "
fi

# page header

p1="%-20.20s %-35.35s\n"
c1="%-20.20s,%-35.35s\n"

if [ $OUTPUT == "print" ]; then
   printf "$p1" "Member Name" "Member Email"
   printf "$p1" "--------------------" "-----------------------------------" 
fi

## sort the keys inthe associative array

mapfile -d '' SORTED < <(printf '%s\0' "${!USER_ARR[@]}" | sort -z)

## main print loop

for key in "${SORTED[@]}"; do 

   declare -a WORK=($(echo ${USER_ARR[$key]} | tr ',' '\n'))

   MY_ORGS=${#WORK[@]}

   let counter=0

   for dkey in "${!WORK[@]}"; do

      declare -a DETAILS=($(echo ${WORK[$dkey]} | tr '~' '\n'))

      if [ $OUTPUT == "print" ]; then 
         if [ $counter -eq 0 ]; then
            printf "$p1" $key ${DETAILS[2]}
         fi
      else
         if [ $counter -eq 0 ]; then
            echo "$key,${DETAILS[2]}"
         fi
      fi
break;
      let counter+=1

   done

   if [ $OUTPUT == "print" ]; then 
      echo " "
   fi

done

if [ $OUTPUT == "print" ]; then
   echo "*** End Report ***"
   echo " "
fi

