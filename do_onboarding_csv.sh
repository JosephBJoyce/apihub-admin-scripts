#!/bin/bash
#
# Invite Members to an Organizations with a Roles from the 
# members_report CSV file.
#
# This script is not supported by SmartBear Software and is to be used as-is.
#
#   m. higgins    09/9072021    inital coding (1.0.0)
#   m. higgins    19/01/2022    fixed some wording (1.0.1)
#   m. higgins    25/07/2022    cloned from json and update to read csv (1.1.0)
#   m. higgins    19/09/2024    added echo and counter (1.3.0)
#

API_NAME="do_onboarding_csv"
RELEASE="v1.3.0"

echo " "
echo "$API_NAME  ${RELEASE} - `date`"

###################################################################################################
# check that jq is installed

if ! jq --help &> /dev/null; then
   echo " "
   echo "The Linux utility jq must be installed to use this script"
   echo " "
   exit 1
fi

######################################################################################################
# process the command line arguements

if [ $# -ne 1 ]; then
   echo " "
   echo "usage: ./do_onboarding_csv.sh <csvFileName>"
   echo " "
   exit 1
fi

FILE=$1

if [ ! -f $FILE ]; then
  echo "   Can not read file: $REPO/$FILE"
  echo " "
  exit 1
fi

######################################################################################################
# begin

echo " "

let lc=0
let counter=0

while read -r line; do

   let lc=lc+1

   STRARR=($(echo $line | tr "," "\n")) 

   if [ $lc -gt 1 ]; then

      # assumes mail in column B, Org name in coluimn C and Role in D

      EMAIL=${STRARR[3]}
      ROLE=${STRARR[1]}
      ORG='mhiggins-sa'

      let counter=$counter+1
      echo -e  ">> Member: $counter \c"

      ~/bin/scripts/invite_member.sh $EMAIL $ORG $ROLE quiet

   fi

done < $FILE

echo " "
echo "End: $API_NAME"
echo " "
