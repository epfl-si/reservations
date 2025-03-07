#!/usr/bin/env bash

# set -e -x

FILE_WITH_SECRETS=/keybase/team/epfl_resrvations/service.md
# user: your_user
# id: M01234
# pass: aV3ry$3cur3P455w0rd

# ./addAdminToGroup.sh -d -gn calendar_admins_room_gcb110 -al S36745

## Usage
usage () {
  echo ""
  echo -e '\033[1mA script to manage the groups creation for SI_RESERVATION.\033[0m'
  echo ""
  echo "Usage:"
  echo "$0 \\"
  echo "        -gn admins_calendar_obj_officalname \\"
  echo "        -al 168981,169419"
  echo ""
  echo "Options:"
  echo "  -h, --help               Show this help message"
  echo "  -d, -v                   Show more output"
  echo "  -gn, --group-name        Name of the group"
  echo "  -al, --admin-list        Comma-separated list of admins (default to S36745)"
}

DEBUG=false
## Parse args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) usage; exit 0;;
    -d|--debug|-v)
      DEBUG=true
      shift # past argument
      ;;
    -gn|--group-name)
      GROUP_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -al|--admin-list)
      ADMIN_LIST="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      ;;
  esac
done

fail () {
  printf '%s\n' "$1" >&2 ## Send message to stderr.
  exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

if [ "$DEBUG" = true ]; then
  echo "PARAMS:"
  echo "  - DEBUG=$DEBUG"
  echo "  - GROUP_NAME=$GROUP_NAME"
  echo "  - ADMIN_LIST=$ADMIN_LIST"
  echo ""
fi

## Retrieve secrets
if ! test -f "$FILE_WITH_SECRETS"; then
  fail "File with secrets not found ($FILE_WITH_SECRETS). Do you forget to run Keybase?"
else
  SECRETS=$(cat $FILE_WITH_SECRETS)
  USER=$(echo "$SECRETS" | grep 'user:' | cut -d' ' -f2)
  PASS=$(echo "$SECRETS" | grep 'pass:' | cut -d' ' -f2)
  AUTH=$(echo -n "$USER:$PASS" | base64)
  AUTHORIZATION="authorization: Basic $AUTH"
  if [ "$DEBUG" = true ]; then
    echo "Secret file ($FILE_WITH_SECRETS) found"
    echo "  - User=$USER"
    echo "  - Auth=$AUTH"
    echo ""
  fi
fi

## Check args
MODE=false
if [ -z "$ADMIN_LIST" ]; then
  ADMIN_LIST="S36745"
fi
if [ -z "$GROUP_NAME" ]; then
  fail "GROUP_NAME: needed" 4
fi

# Ensure admin list and format it
if [ -z "$ADMIN_LIST" ]; then
  fail "Creating a GROUP without admins is not recommmended. Please specify the list of admin with '--admin-list'" 2
else
  ADMIN_LIST=$(echo "$ADMIN_LIST" | sed 's/[[:space:]]//g')
  if [ "$DEBUG" = true ]; then echo "  ADMIN_LIST=$ADMIN_LIST"; fi
  IFS=',' read -ra ADMIN_LIST_ARRAY <<< "$ADMIN_LIST"
fi

getGroupID () {
  GROUP_ID=$(curl -s --request GET \
    --url "https://api.epfl.ch/v1/groups?name=$1" \
    --header "Accept: application/json" \
    --header "$AUTHORIZATION" | jq -r '.groups[0].id')

  if [ -z $GROUP_ID ]; then
    echo "$GROUP_ID not found"
  else
    echo "$GROUP_ID FOUND!"
  fi
}

getGroupID "$GROUP_NAME"


addAdminToGroup () {
  local _ADMIN="$1" # Either a group or a sciper!
  local _GRP_ID="$2"
  curl -s --request POST \
      --url https://api.epfl.ch/v1/groups/$_GRP_ID/admins \
      --header 'accept: application/json' \
      --header "$AUTHORIZATION" \
      --header 'content-type: application/json' \
      --data '{
        "id": "'"$_ADMIN"'"
      }'
}


if [ "$DEBUG" = true ]; then echo "  - add ´super_admin_reservations´ (S36745) to ´$GROUP_NAME"; fi
addAdminToGroup "S36745" "$GROUP_ID"

if [ -z "$ADMIN_LIST" ]; then
  fail "Creating a GROUP without admins is not recommmended. Please specify the list of admin with '--admin-list'" 2
else
  ADMIN_LIST=$(echo "$ADMIN_LIST" | sed 's/[[:space:]]//g')
  if [ "$DEBUG" = true ]; then echo "  ADMIN_LIST=$ADMIN_LIST"; fi
  IFS=',' read -ra ADMIN_LIST_ARRAY <<< "$ADMIN_LIST"
fi
for _admin in "${ADMIN_LIST_ARRAY[@]}"; do
  if [ "$DEBUG" = true ]; then echo "    - adding ´$_admin´ to the group ´$GROUP_NAME"; fi
  addAdminToGroup "$_admin" "$GROUP_ID"
done
