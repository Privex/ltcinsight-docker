#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:${PATH}"
export PATH="${HOME}/.local/bin:/snap/bin:${PATH}"

cd "$DIR"

em() {
    >&2 echo -e "$@"
}
hascmd() {
    command -v "$@" &> /dev/null
}

has_cmd() { hascmd "$@"; }

autosudo() {
    all_args=("$@")
    first_el="${all_args[0]}"
    last_els=("${all_args[@]:1:${#all_args[@]}}")
    last_els_str="$(printf "%q " "${last_els[@]}")"

    if (( EUID != 0 )); then
        if hascmd sudo; then
            sudo -- "$@"
            _ret=$?
        elif hascmd su; then
            su -c "$first_el ${last_els_str}"
            _ret=$?
        else
            em " [!!!] You're not root, and neither 'sudo' nor 'su' are available."
            em " [!!!] Cannot run command: $first_el $last_els_str "
            return 2
        fi
    else
        env -- "$@"
        _ret=$?
    fi
    return $_ret
}

: ${LTC_ENV="${DIR}/.env"}
: ${LTC_ENV_EXM="${DIR}/example.env"}

: ${LTC_COMPOSE="${DIR}/docker-compose.yml"}
: ${LTC_COMPOSE_EXM="${DIR}/bin.docker-compose.yml"}

: ${LTC_CADDY="${DIR}/caddy/Caddyfile"}
: ${LTC_CADDY_EXM="${DIR}/caddy/example.Caddyfile"}
: ${COMPOSE_VER="1.28.3"}
: ${COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-Linux-x86_64"}

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

source "${LTC_ENV}"

DST_TYPE="" PKG_MGR="" PKG_MGR_INS="" PKG_MGR_UP=""

hascmd apt-get && DST_TYPE="deb" PKG_MGR="apt-get"
[[ -z "$PKG_MGR" ]] && hascmd apt && DST_TYPE="deb" PKG_MGR="apt"
[[ -z "$PKG_MGR" ]] && hascmd dnf && DST_TYPE="rhel" PKG_MGR="dnf"
[[ -z "$PKG_MGR" ]] && hascmd yum && DST_TYPE="rhel" PKG_MGR="yum"
[[ -z "$PKG_MGR" ]] && hascmd pacman && DST_TYPE="arch" PKG_MGR="pacman"
[[ -z "$PKG_MGR" ]] && hascmd apk && DST_TYPE="alp" PKG_MGR="apk"
[[ -z "$PKG_MGR" ]] && hascmd brew && DST_TYPE="osx" PKG_MGR="brew"

if [[ -n "$PKG_MGR" ]]; then
    if [[ "$DST_TYPE" == "deb" ]]; then
        PKG_MGR_INS="${PKG_MGR} install -qy" PKG_MGR_UP="${PKG_MGR} update -qy"
    elif [[ "$DST_TYPE" == "rhel" ]]; then
        PKG_MGR_INS="${PKG_MGR} install -y" PKG_MGR_UP="${PKG_MGR} makecache -y"
    elif [[ "$DST_TYPE" == "alp" ]]; then
        PKG_MGR_INS="${PKG_MGR} add" PKG_MGR_UP="${PKG_MGR} update"
    elif [[ "$DST_TYPE" == "arch" ]]; then
        PKG_MGR_INS="${PKG_MGR} -S --noconfirm" PKG_MGR_UP="${PKG_MGR} -Sy --noconfirm"
    elif [[ "$DST_TYPE" == "osx" ]]; then
        PKG_MGR_INS="${PKG_MGR} install" PKG_MGR_UP="${PKG_MGR} update"
    else
        PKG_MGR=""
    fi
fi

PM_UPDATED=0

_instpkg() {
    if [[ -n "$PKG_MGR_UP" ]] && (( PM_UPDATED == 0 )); then
        autosudo $PKG_MGR_UP
        _ret=$?
        if (( _ret )); then
           em "     [!!!] Non-zero return code from '$PKG_MGR_UP' - code: $_ret"
           return $_ret
        fi
        em "    +++ Successfully updated package manager '${PKG_MGR}'"
        PM_UPDATED=1
    fi
    
    autosudo $PKG_MGR_INS "$@"

    _ret=$?
    if (( _ret )); then
       em "     [!!!] Non-zero return code from '$PKG_MGR_INS' - code: $_ret"
       return $_ret
    fi
    em "     +++ Successfully installed packages:" "$@"
    return 0
}

instpkg() {
    rets=0
    for p in "$@"; do
        _instpkg "$p"
        _ret=$?
        if (( _ret )); then
            rets=$_ret
        fi
    done
    return $rets
}

instpkg-all() {
    _instpkg "$@"
}


autoinst() {
    if hascmd "$1"; then
        return 0
    fi
    em " [...] Program '$1' not found. Installing package(s):" "${@:2}"
    instpkg "${@:2}"
}

autoinst git git
[[ "$(uname -s)" == "Linux" ]] && autoinst netstat net-tools
autoinst wget wget
autoinst curl curl
autoinst jq jq
[[ "$(uname -s)" == "Linux" ]] && autoinst iptables iptables || true
[[ "$DST_TYPE" == "arch" ]] && instpkg-all extra/fuse3 community/fuse-overlayfs bridge-utils

hascmd systemctl && autosudo systemctl daemon-reload
if ! hascmd docker; then
    em " [!!!] Command 'docker' not available. Installing Docker from https://get.docker.com"
    curl -fsS https://get.docker.com | sh
    _ret=$?

    if (( _ret )) || ! hascmd docker; then
        em " [!!!] ERROR: Command 'docker' is still not available. Falling back to installing Docker via package manager (if possible)"
        if autoinst docker docker.io; then
            em " [+++] Successfully installed Docker via package 'docker.io'"
        else
            em " [!!!] ERROR: Failed to install package 'docker.io'. Possibly your system's repos list it under 'docker'..."
            em " [!!!] Falling back to package name 'docker'..."
            if autoinst docker docker; then
                em " [+++] Successfully installed Docker via package 'docker'"
            else
                em " [!!!] CRITICAL ERROR !!!"
                em " [!!!] We failed to install Docker via both Docker's auto-install script ( https://get.docker.com )"
                em " [!!!] AND via your OS's package manager..."
                em " [!!!] Please go to https://www.docker.com/get-started and lookup your operating system."
                em " [!!!] You'll need to manually install Docker for your OS, and then re-run this script to try"
                em " [!!!] setting up + installing + running Insight LTC via Docker for you."
                em " NOTE: If you're not sure where this script is, it's located at: $0"
                em "       Full path: ${DIR}/$0"
                em
                exit 20
            fi
        fi
    else
        em " [+++] Successfully installed Docker via the official auto-installer script :)"
    fi
fi



install() {
    local is_verb=0
    if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
        is_verb=1
        shift
    fi
    all_args=("$@")

    first_els=("${all_args[@]::${#all_args[@]}-1}")
    last_el="${all_args[-1]}"

    autosudo cp -Rv "${first_els[@]}" "$last_el"

    # If the last arg is a folder, then we need to get the file/folder names of
    # the first arguments, then prepend them to the last argument (the dest. folder),
    # so that we can chmod the files in the new location.
    if [[ -d "$last_el" ]]; then
        el_names=()
        for f in "${first_els}"; do
            el_names+=("${last_el%/}/$(basename "$f")")
        done
        autosudo chmod -Rv 755 "${el_names[@]}"
    else
        autosudo chmod -v 755 "$last_el"
    fi
}

ins-compose() {
    em " >>> Downloading docker-compose from URL: $COMPOSE_URL"
    wget -O /tmp/docker-compose "$COMPOSE_URL"
    em " >>> Attempting to install docker-compose into /usr/local/bin"
    install /tmp/docker-compose /usr/local/bin/docker-compose
    _ret=$?
    [[ -f "/tmp/docker-compose" ]] && rm -f /tmp/docker-compose
    return $_ret
}

if ! autoinst docker-compose docker-compose; then
    em " >>> Detected error while installing docker-compose. Will attempt to install manually."
    ins-compose
    _ret=$?
    if (( _ret == 0 )); then
        em " [+++] Got successful return code (0) from ins-compose. Docker-compose should be installed."
    else
        em " [!!!] Got non-zero code from ins-compose (code: ${_ret}) - install may have errored..."
    fi
fi

hascmd systemctl && autosudo systemctl daemon-reload
if [[ "$DST_TYPE" == "arch" ]]; then
    em " >>> Arch Linux detected..."
    em " >>> Stopping docker service..."
    autosudo systemctl stop docker
    em " >>> Waiting 10 seconds for Docker to fully shutdown and cleanup..."
    sleep 10
    em " >>> Reloading systemd"
    autosudo systemctl daemon-reload
    em " >>> Starting Docker service"
    autosudo systemctl start docker
    em " >>> Waiting 10 seconds for Docker to fully start up."
    sleep 10
    em " +++ Docker should now be ready."
    em "\n\n"
    em " # !!! !!! !!! !!!"
    em " # !!! WARNING: On Arch Linux, Docker may not be able to automatically install and load the kernel"
    em " # !!! modules that it requires to function after first being installed."
    em " # !!!"
    em " # !!! If you see a bunch of errors when this script tries to start the containers, then you likely"
    em " # !!! need to upgrade your system (inc. kernel) using 'pacman -Syu' - and then reboot."
    em " # !!!"
    em " # !!! After rebooting, Docker's service should then be able to run just fine."
    em " # !!! !!! !!! !!!\n\n"
    sleep 5
fi


if hascmd systemctl; then
    if autosudo systemctl status docker | head -n20 | grep -Eiq 'active:[ \t]+active( \(running\))?'; then
        em " [+++] Service 'docker' appears to be active and running :)"
    else
        em " [!!!] Service 'docker doesn't appear to be running... Attempting to enable and start it..."
        autosudo systemctl daemon-reload
        autosudo systemctl enable docker
        autosudo systemctl restart docker
        em " [...] Waiting 5 seconds for docker service to start up..."
        sleep 5
    fi
elif hascmd service; then
    em " [!!!] Warning: Your system doesn't have systemctl, but instead has 'service'. We may not be able to reliably check whether or not Docker is running."
    em " [!!!] If you see errors while the script starts the Docker containers, check 'service docker status' to see if Docker is running."
    em " [!!!] If the 'docker' service isn't running, try running 'service restart docker' and then run this script again."
    em
    if autosudo service docker status | grep -Eiq "active|running"; then
        em " [+++] Service 'docker' appears to be active and running :) (fallback check via 'service' command)"
    else
        em " [!!!] Service 'docker doesn't appear to be running... Attempting to start it..."
        autosudo service docker restart
        em " [...] Waiting 5 seconds for docker service to start up..."
        sleep 5
    fi
else
    em " [!!!] Warning: Your system doesn't have systemctl, nor 'service'. We cannot check whether or not Docker is running."
    em " [!!!] If you see errors while the script starts the Docker containers, please ensure the 'docker' service is running,"
    em " [!!!] using whatever service management tool your OS uses...\n"
fi

em " >>> Starting Insight Docker Containers using 'docker-compose up -d'"
autosudo docker-compose up -d
_ret=$?

exit $_ret


