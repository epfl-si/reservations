#!/usr/bin/env bash

# set -e -x

FILE_WITH_SECRETS=/keybase/team/epfl_resrvations/service.md
# user: your_user
# id: M01234
# pass: aV3ry$3cur3P455w0rd

## Usage
usage () {
  echo ""
  echo -e '\033[1mA script to manage the groups creation for SI_RESERVATION.\033[0m'
  echo ""
  echo "Usage:"
  echo "$0 \\"
  echo "        -ag admins_calendar_obj_officalname \\"
  echo "        -bg book_calendar_obj_officalname \\"
  echo "        -al 168981,169419"
  echo ""
  echo "Note: if both admin-group and bookin-group are specified, then the admin-group"
  echo "      will be added as administrator in the booking-group."
  echo ""
  echo "Options:"
  echo "  -h, --help               Show this help message"
  echo "  -d, -v                   Show more output"
  echo "  -ag, --admin-group       Name of the admin group (who can edit other's reservations)"
  echo "  -bg, --booking-group     Name of the booking group (who can book (add and see))"
  echo "  -gd, --group-description Specify the groups' description"
  echo "  -al, --admin-list        Comma-separated list of admins"
  echo "  -ml, --member-list       Comma-separated list of members"
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
    -gd|--group-description)
      GROUP_DESCRIPTION="$2"
      shift # past argument
      shift # past value
      ;;
    -bg|--booking-group)
      BOOKING_GROUP="$2"
      shift # past argument
      shift # past value
      ;;
    -ml|--member-list)
      MEMBER_LIST="$2"
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
  echo "  - ADMIN_GROUP=$ADMIN_GROUP"
  echo "  - GROUP_DESCRIPTION=$GROUP_DESCRIPTION"
  echo "  - BOOKING_GROUP=$BOOKING_GROUP"
  echo "  - MEMBER_LIST=$MEMBER_LIST"
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
if [ -z "$ADMIN_GROUP" ] && [ -z "$BOOKING_GROUP" ]; then
  fail "Please specify at least a group." 2
fi
if [ -n "$ADMIN_GROUP" ] && [ -z "$BOOKING_GROUP" ]; then
  if [ "$DEBUG" = true ]; then echo "Only create ADMIN GROUP ($ADMIN_GROUP)"; fi
  fail "ADMIN_GROUP_ONLY: not implemented" 4
fi
if [ -z "$ADMIN_GROUP" ] && [ -n "$BOOKING_GROUP" ]; then
  if [ "$DEBUG" = true ]; then echo "Only create BOOKING GROUP ($MEMBER_GROUP)"; fi
  fail "BOOKING_GROUP_ONLY: not implemented" 4
fi
if [ -n "$ADMIN_GROUP" ] && [ -n "$BOOKING_GROUP" ]; then
  # Default mode for now
  if [ "$DEBUG" = true ]; then echo "Create both ADMIN GROUP ($ADMIN_GROUP) & BOOKING GROUP ($BOOKING_GROUP)"; fi
fi

# Ensure admin list and format it
if [ -z "$ADMIN_LIST" ]; then
  fail "Creating a GROUP without admins is not recommmended. Please specify the list of admin with '--admin-list'" 2
else
  ADMIN_LIST=$(echo "$ADMIN_LIST" | sed 's/[[:space:]]//g')
  if [ "$DEBUG" = true ]; then echo "  ADMIN_LIST=$ADMIN_LIST"; fi
  IFS=',' read -ra ADMIN_LIST_ARRAY <<< "$ADMIN_LIST"
fi

# Ensure member list
if [ -z "$MEMBER_LIST" ]; then
  fail "Creating a GROUP without members is not recommmended. Please specify the list of admin with '--member-list'" 2
else
  MEMBER_LIST=$(echo "$MEMBER_LIST" | sed 's/[[:space:]]//g')
  if [ "$DEBUG" = true ]; then echo "  MEMBER_LIST=$MEMBER_LIST"; echo ""; fi
fi

searchGroup () {
  SG=$(curl -s --request GET \
    --url "https://api.epfl.ch/v1/groups?name=$1" \
    --header "Accept: application/json" \
    --header "$AUTHORIZATION" | grep '"count":0')
  if $SG; then
    echo "$1 may exists!"
  else
    echo "$1 not found"
  fi
}

createGroup () {
  local _GROUP_NAME="$1"
  local _GROUP_DESCRIPTION="${2:-''}"
  response=$(curl -s --request POST \
    --url https://api.epfl.ch/v1/groups \
    --header 'accept: application/json' \
    --header "$AUTHORIZATION" \
    --header 'content-type: application/json' \
    --data "{
      \"access\": \"o\",
      \"candelete\": false,
      \"canedit\": false,
      \"canmanagemembers\": false,
      \"description\": \"$_GROUP_DESCRIPTION\",
      \"hidemembers\": false,
      \"iammember\": false,
      \"ldap\": true,
      \"lifetime\": 12,
      \"listext\": false,
      \"maillist\": false,
      \"name\": \"$_GROUP_NAME\",
      \"public\": true,
      \"registration\": \"f\",
      \"url\": \"\",
      \"visible\": true,
      \"visilist\": false
    }"
  )

  if [[ $response == *"\"id\""* ]]; then
    NEW_GROUP_ID=$(echo "$response" | grep -o '"id":"[^"]*' | sed 's/"id":"//')
    if [ "$DEBUG" = true ]; then
      echo "  - Group $ADMIN_GROUP created"
      echo "  - Group ID is $NEW_GROUP_ID"
      echo "  - Group link is https://groups.epfl.ch/#/home/$NEW_GROUP_ID"
    fi
  else
    echo "Erreur lors de la création des groupes"
    exit 1
  fi
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




if [ "$DEBUG" = true ]; then echo "--------------------------------------------------------------------"; fi
if [ "$DEBUG" = true ]; then echo "ADMIN_GROUP:"; fi
if [ "$DEBUG" = true ]; then echo "  - check if ´$ADMIN_GROUP´ exists"; fi
searchGroup "$ADMIN_GROUP"
if [ "$DEBUG" = true ]; then echo "  - create ´$ADMIN_GROUP´"; fi
createGroup "$ADMIN_GROUP" "Admins for the $GROUP_DESCRIPTION"
ADMIN_GROUP_ID=$NEW_GROUP_ID
if [ "$DEBUG" = true ]; then echo "  - add people in the admin list ($ADMIN_LIST) as member of ´$BOOKING_GROUP´"; fi
addMembersToGroup "$ADMIN_LIST,S36745" "$ADMIN_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add ´super_admin_reservations´ (S36745) to ´$ADMIN_GROUP´"; fi
addAdminToGroup "S36745" "$ADMIN_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add people in the admin list ($ADMIN_LIST) to the group ´$ADMIN_GROUP´"; fi
for _admin in "${ADMIN_LIST_ARRAY[@]}"; do
  if [ "$DEBUG" = true ]; then echo "    - adding ´$_admin´ to the group ´$ADMIN_GROUP´"; fi
  addAdminToGroup "$_admin" "$ADMIN_GROUP_ID"
done


if [ "$DEBUG" = true ]; then echo "BOOKING_GROUP:"; fi
if [ "$DEBUG" = true ]; then echo "  - check if ´$BOOKING_GROUP exists"; fi
searchGroup "$BOOKING_GROUP"
if [ "$DEBUG" = true ]; then echo "  - create ´$BOOKING_GROUP´"; fi
createGroup "$BOOKING_GROUP" "People allowed to book $GROUP_DESCRIPTION"
BOOKING_GROUP_ID=$NEW_GROUP_ID

if [ "$DEBUG" = true ]; then echo "  - add people in the member list ($MEMBER_LIST) as member of ´$BOOKING_GROUP´"; fi
addMembersToGroup "$MEMBER_LIST" "$BOOKING_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add people in the member list ($ADMIN_GROUP_ID) as member of ´$BOOKING_GROUP´"; fi
addMembersToGroup "$ADMIN_GROUP_ID" "$BOOKING_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add people in the member list (S36745) as member of ´$BOOKING_GROUP´"; fi
addMembersToGroup "S36745" "$BOOKING_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add people in the member list ($ADMIN_LIST) as member of ´$BOOKING_GROUP´"; fi
addMembersToGroup "$ADMIN_LIST" "$BOOKING_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add ´super_admin_reservations´ (S36745) to ´$BOOKING_GROUP´"; fi
addAdminToGroup "S36745" "$BOOKING_GROUP_ID"
if [ "$DEBUG" = true ]; then echo "  - add ´$ADMIN_GROUP´ ($ADMIN_GROUP_ID) to ´$BOOKING_GROUP´"; fi
addAdminToGroup "$ADMIN_GROUP_ID" "$BOOKING_GROUP_ID"

