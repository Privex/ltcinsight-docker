#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR"

em() {
    >&2 echo -e "$@"
}
hascmd() {
    command -v "$@" &> /dev/null
}

has_cmd() { hascmd "$@"; }

: ${LTC_ENV="${DIR}/.env"}
: ${LTC_ENV_EXM="${DIR}/example.env"}

: ${LTC_COMPOSE="${DIR}/docker-compose.yml"}
: ${LTC_COMPOSE_EXM="${DIR}/bin.docker-compose.yml"}

: ${LTC_CADDY="${DIR}/caddy/Caddyfile"}
: ${LTC_CADDY_EXM="${DIR}/caddy/example.Caddyfile"}

if ! [[ -f "$LTC_ENV" ]]; then
    em " [!!!] The env file '${LTC_ENV}' wasn't found. Copying example config '${LTC_ENV_EXM}'..."
    >&2 cp -v "$LTC_ENV_EXM" "${LTC_ENV}"
fi
if ! [[ -f "$LTC_COMPOSE" ]]; then
    em " [!!!] The docker compose file '${LTC_COMPOSE}' wasn't found. Copying binary image config '${LTC_COMPOSE_EXM}'..."
    >&2 cp -v "$LTC_COMPOSE_EXM" "${LTC_COMPOSE}"
fi

if ! [[ -f "$LTC_CADDY" ]]; then
    em " [!!!] The config file '${LTC_CADDY}' wasn't found. Copying example config '${LTC_CADDY_EXM}'..."
    >&2 cp -v "$LTC_CADDY_EXM" "${LTC_CADDY}"
fi

DST_TYPE="" PKG_MGR="" PKG_MGR_INS="" PKG_MGR_UP=""

hascmd apt-get && DST_TYPE="deb" PKG_MGR="apt-get"
[[ -z "$PKG_MGR" ]] && hascmd apt && DST_TYPE="deb" PKG_MGR="apt"
[[ -z "$PKG_MGR" ]] && hascmd dnf && DST_TYPE="rhel" PKG_MGR="dnf"
[[ -z "$PKG_MGR" ]] && hascmd yum && DST_TYPE="rhel" PKG_MGR="yum"
[[ -z "$PKG_MGR" ]] && hascmd apk && DST_TYPE="alp" PKG_MGR="apk"
[[ -z "$PKG_MGR" ]] && hascmd brew && DST_TYPE="osx" PKG_MGR="brew"

if [[ -n "$PKG_MGR" ]]; then
    if [[ "$DST_TYPE" == "deb" ]]; then
        PKG_MGR_INS="${PKG_MGR} install -qy"
        PKG_MGR_UP="${PKG_MGR} update -qy"
    elif [[ "$DST_TYPE" == "rhel" ]]; then
        PKG_MGR_INS="${PKG_MGR} install -y"
        PKG_MGR_UP="${PKG_MGR} makecache -y"
    elif [[ "$DST_TYPE" == "alp" ]]; then
        PKG_MGR_INS="${PKG_MGR} add"
        PKG_MGR_UP="${PKG_MGR} update"
    elif [[ "$DST_TYPE" == "osx" ]]; then
        PKG_MGR_INS="${PKG_MGR} install"
        PKG_MGR_UP="${PKG_MGR} update"
    else
        PKG_MGR=""
    fi
fi

PM_UPDATED=0

autoinst() {
    if hascmd "$1"; then
        return 0
    fi
    em " [...] Program '$1' not found. Installing package(s):" "${@:2}"

    if [[ -n "$PKG_MGR_UP" ]] && (( PM_UPDATED == 0 )); then
        eval "$PKG_MGR_UP"
        _ret=$?
        if (( _ret )); then
           em "     [!!!] Non-zero return code from '$PKG_MGR_UP' - code: $_ret"
           return $_ret
        fi
        em "    +++ Successfully updated package manager '${PKG_MGR}'"
        PM_UPDATED=1
    fi
    
    eval '$PKG_MGR_INS "${@:2}"'
    _ret=$?
    if (( _ret )); then
       em "     [!!!] Non-zero return code from '$PKG_MGR_INS' - code: $_ret"
       return $_ret
    fi
    em "     +++ Successfully installed packages:" "${@:2}"
    return 0
}

autoinst git git
autoinst wget wget
autoinst curl curl
autoinst jq jq

if ! hascmd docker; then
    em " [!!!] Command 'docker' not available. Installing Docker from https://get.docker.com"
    curl -fsS https://get.docker.com | sh
fi

autoinst docker-compose docker-compose

em " >>> Starting Insight Docker Containers using 'docker-compose up -d'"
docker-compose up -d
_ret=$?

exit $_ret


