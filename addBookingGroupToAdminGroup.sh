#!/usr/bin/env bash

set -e -x

FILE_WITH_SECRETS=/keybase/team/epfl_resrvations/service.md
# user: your_user
# id: M01234
# pass: aV3ry$3cur3P455w0rd

# ./addBookingGroupToAdminGroup.sh -d -gn calendar_admins_room_gcb110

## Usage
usage () {
  echo ""
  echo -e '\033[1mA script to manage the groups creation for SI_RESERVATION.\033[0m'
  echo ""
  echo "Usage:"
  echo "$0 \\"
  echo "        -ag calendar_admins_room_xx111 \\"
  echo "        -bg calendar_booking_room_xx111 \\"
  echo ""
  echo "Options:"
  echo "  -h, --help               Show this help message"
  echo "  -d, -v                   Show more output"
  echo "  -ag, --admin-group       Name of the admin group"
  echo "  -bg, --booking-group     Name of the booking group"
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
    -ag|--admin-group)
      ADMIN_GROUP="$2"
      shift # past argument
      shift # past value
      ;;
    -bg|--booking-group)
      BOOKING_GROUP="$2"
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
  echo "  - ADMIN_GROUP=$ADMIN_GROUP"
  echo "  - BOOKING_GROUP=$BOOKING_GROUP"
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
if [ -z "$ADMIN_GROUP" ]; then
  fail "ADMIN_GROUP: needed" 3
fi
if [ -z "$BOOKING_GROUP" ]; then
  fail "BOOKING_GROUP: needed" 4
fi

getGroupID () {
  GROUP_ID=$(curl -s --request GET \
    --url "https://api.epfl.ch/v1/groups?name=$1" \
    --header "Accept: application/json" \
    --header "$AUTHORIZATION" | jq -r '.groups[0].id')

  if [ -z $GROUP_ID ]; then
    echo "$GROUP_ID not found"
  else
    echo "$GROUP_ID"
  fi
}

ADMIN_GROUP_ID=$(getGroupID "$ADMIN_GROUP")
BOOKING_GROUP_ID=$(getGroupID "$BOOKING_GROUP")

addAdminToGroup () {
  echo "Adding $1 as admin of $2"
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

addMembersToGroup () {
  local _MEMBERS="$1" # comma separated list
  local _GRP_ID="$2"
  curl -s --request POST \
    --url https://api.epfl.ch/v1/groups/$_GRP_ID/members \
    --header 'accept: application/json' \
    --header "$AUTHORIZATION" \
    --header 'content-type: application/json' \
    --data '{
      "ids": "'"$_MEMBERS"'"
    }'
}

# Note: Admin haz to be members first...
addMembersToGroup "$ADMIN_GROUP_ID" "$BOOKING_GROUP_ID"
addMembersToGroup "S36745" "$BOOKING_GROUP_ID"

addAdminToGroup $ADMIN_GROUP_ID $BOOKING_GROUP_ID
addAdminToGroup "S36745" $BOOKING_GROUP_ID
