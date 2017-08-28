#!/bin/bash

initArgs() {

	START="pm2"

	for arg in "$@"; do
		shift
		case "$arg" in
			"--") shift ; break ;;
			"--env") set -- "$@" "-e" ;;
			"--url") set -- "$@" "-h" ;;
			"--credential-secret") set -- "$@" "-s" ;;
			"--docker") set -- "$@" "-d";;
			*) set -- "$@" "$arg" ;;
		esac
	done

	local OPTIND=1
	PORT=1880

	SOURCE="$(dirname "${BASH_SOURCE[0]}")"
	CUR_DIR="`pwd`"
	cd "$SOURCE"
	SOURCE="`pwd`"
	cd "$CUR_DIR"

	while getopts p:e:h:s:d option
	do
		case "$option" in
			p) PORT="${OPTARG}";;
			e) ENV="${OPTARG}";;
			h) HOST="${OPTARG}";;
			s) CREDENTIAL_SECRET="${OPTARG}";;
			d) START="pm2-docker";;
	 		:)
	      		echo "Option -$OPTARG requires an argument." >&2
	      		exit 1
	     		;;
		esac
	done
	 
	shift $(($OPTIND - 1))

	APP="$1"
	NAME=""

	if [ $START == "pm2" ]
	then
		NAME="--name $APP"
	fi
}

checkArgs() {
	if [ -z "$APP" ] || [ -z "$ENV" ]
	then

		bold=$(tput bold)
		normal=$(tput sgr0)

		echo $bold"usage : bash start.sh [ -p port ] [ --url http://url ] [ --docker ] --env [ dev|quali|prod ] [ --credential-secret passphrase ] app"$normal
		exit 1
	fi
}

initArgs "$@"
checkArgs


if [ -z "$(ls -A $CUR_DIR)" ]
then
	bash "$SOURCE/create_template.sh"
fi

NODE_ENV=$ENV \
NODE_TLS_REJECT_UNAUTHORIZED=0 \
CONFIG_PATH="$CUR_DIR/conf/config.js" \
FRAMEWORK_ROOT="$SOURCE" \
HOST="$HOST" \
PORT=$PORT \
BOT_ROOT=$CUR_DIR \
CREDENTIAL_SECRET=$CREDENTIAL_SECRET \
$START \
start \
"$SOURCE"/node_modules/node-red/red.js $NAME -- -s "$SOURCE"/conf/node-red-config.js