# Litecoin Insight (LTC-Insight) Easy Docker Setup

## Copyright Notice

```
+===================================================+
|                 © 2021 Privex Inc.                |
|               https://www.privex.io               |
+===================================================+
|                                                   |
|        LTC Insight Docker                         |
|        License: X11/MIT                           |
|                                                   |
|        Core Developer(s):                         |
|                                                   |
|          (+)  Chris (@someguy123) [Privex]        |
|          (+)  Kale (@kryogenic) [Privex]          |
|                                                   |
+===================================================+

LTC Insight Docker - A pre-configured and setup Docker environment for the Litecoin Insight 
explorer software, using docker-compose for provisioning, and Caddy as the default webserver.

Copyright (c) 2021    Privex Inc. ( https://www.privex.io )

```

**Interested in privacy focused server hosting, with competitive pricing that's often cheaper than certain well known VPS hosts?**

Check out Privex's website: https://www.privex.io

We offer fast + reliable VPS and Dedicated server hosting for highly affordable prices, with no personal information or KYC needed.

## Requirements

- A 64-bit Linux system (may also work on macOS). Designed to work on the following distros, and distros based on the below:
    - Ubuntu 20.04 (Focal) / Ubuntu 18.04 (Bionic)
    - Debian 10 (Buster)
    - Fedora 32
    - CentOS 8
    - Oracle Linux 8
    - Redhat Enterprise Linux 8 (RHEL 8)
    - Arch Linux
    - Alpine Linux (untested)
- A CPU that supports the AMD64 (x86_64) architecture - e.g. practically any Intel or AMD CPU produced in the past 15 years.
- As of Feb 2021, it's recommended to have at LEAST 100gb of disk space (preferably 200gb+)
- At least 2GB RAM

Software Requirements (auto-installed by `init.sh`):

- `git` to clone this repo
- [Docker](https://www.docker.com/get-started) to run the containers within
- Docker Compose (`docker-compose`) to manage the containers using the docker-compose.yml config
- The BASH shell - to be able to run `init.sh` / `deploy.sh` (BASH is standard on practically every Linux distro, and macOS)



## Quickstart

### Quickly deploy using `deploy.sh` oneliner

The `deploy.sh` script is a small BASH deployment script that will ensure `git`, `wget`, and `curl` are all installed,
then clone the repo into `$HOME/ltcinsight-docker` (unless you set `INS_DIR`), and run `init.sh`
to install Docker / copy the example files / start the Docker containers.

Using `curl`:

```sh
curl -fsS https://cdn.privex.io/github/ltcinsight-docker/deploy.sh | bash
```

Using `wget`:

```sh
wget -q -O - https://cdn.privex.io/github/ltcinsight-docker/deploy.sh | bash
```

### (Alternative) Clone the repo manually, and run init.sh

```sh
git clone https://github.com/Privex/ltcinsight-docker.git
cd ltcinsight-docker
./init.sh
```

### Info about deploy.sh / init.sh for auto-install + auto-start on Ubuntu/Debian/CentOS/Oracle/others

The `deploy.sh` script is designed for use in a one-liner, which will:

- Display a warning, explaining that `ltcinsight-docker` is going to be installed, along with Docker, and certain
  other related packages and dependencies.
- Inform you which Git repo is being cloned, and where on your filesystem that it will be cloned into (default: `$HOME/ltcinsight-docker`)
- Explain that you may press CTRL-C to abort the install if you ran the script by mistake, or noticed some errors.
- Wait for 10 seconds before starting, to give you a chance to read the information, and cancel the install if you have doubts.
- Installs basic deps such as `git` (to clone the repo), `curl`, and `wget`.
- Clones this repository into `$INS_DIR` (default: `$HOME/ltcinsight-docker`)
- Hands over execution to `init.sh` within the cloned repository.

Available ENV vars for deploy.sh:

```sh
INS_REPO - The Git repo to clone (default: https://github.com/Privex/ltcinsight-docker.git)
INS_DIR    - The directory to clone the repo into (default: $HOME/ltcinsight-docker)
INS_VER    - The branch / tag of the repo to clone (default: master)
WAITFOR    - The number of seconds to wait at the warning prompt, before starting the install process (default: 10)
```

--------------------------

The `init.sh` file will:

- Install any basic deps such as `curl`, `wget`, `jq`, and other important utils - if they're not already installed.

- If you don't already have config files at `docker-compose.yml`, `caddy/Caddyfile` and/or `.env`, then
  it will copy the example configs for you (for the compose file, it defaults to the binary image version).

- If you don't have Docker installed, then it will auto-install Docker using https://get.docker.com

- If you don't have `docker-compose` - will install `docker-compose` via `apt-get`, `dnf` / `yum`, `apk`, or `brew` - depending on which package manager
  is detected.

- Starts the Insight LiteCore system (API + WebUI + LTC Daemon) + Caddy webserver using `docker-compose up -d`


### Manual installation + copying example files + starting compose


```sh
# If you don't already have Docker / docker-compose
curl -fsS https://get.docker.com/ | sh

# For Ubuntu/Debian-based distros, you should be able to get docker-compose from apt
apt update -qy
apt install -qy docker-compose

# Clone the repo
git clone https://github.com/Privex/ltcinsight-docker.git
cd ltcinsight-docker

# Copy the example files to the real production files
cp -v example.env .env
cp -v caddy/example.Caddyfile caddy/Caddyfile
cp -v bin.docker-compose.yml docker-compose.yml

# Adjust .env and Caddyfile if desired - though the defaults in the example
# files should work out of the box.
nano .env
nano caddy/Caddyfile

# Start insight + caddy in the background
docker-compose up -d

# Check the logs for insight
docker-compose logs -f insight

# If you need to stop Insight + Caddy, use the 'down' command
docker-compose down
```

## Running the Docker image without compose

```sh
# Create a folder to hold the blockchain / database files etc.
mkdir ~/insight-data

# Run 'privex/ltcinsight' using 'docker run', mounting the volume /ltc/data,
# forwarding port 3001 to localhost, and 9333 (LTC p2p) to the internet.
docker run --name insight --rm -v "${HOME}/insight-data:/ltc/data" \
           -p 127.0.0.1:3001:3001 -p 0.0.0.0:9333:9333 -itd \
           privex/ltcinsight

# Check the logs
docker logs --tail=50 -f insight

# Point the webserver of your choice at 127.0.0.1:3001
# Or do it via Docker - whichever you prefer.


# When you're done, you can stop the container, and it'll be auto-removed
docker stop insight
```

## Checking version information and other important metadata about an Insight image

Inside each `ltcinsight` Docker image, is a file `/version.txt` which contains information about
when the container was built, which branch/tag it was built from, the closest matching Git tag
for the commit it was built from, and information about the latest commit that was in the repo
at the time the image was built.

You can access this file like so:

```sh
docker run --rm -it privex/ltcinsight cat /version.txt
```

Which will output something similar to this:

```
This container has been built with the following options:
----
Git Repository:              https://github.com/Privex/litecore-node.git
Git version/commit:          master
----
Closest Git Tag (version):   v3.1.2-33-gf19e191c

Last Git Commit:             2021-02-18 06:12:11 +0000  f19e191cbca25d546e0dbb7990530972ee085ded  Chris (Someguy123)  add alias for has_cmd

----
Built at: Thu Feb 18 07:29:29 UTC 2021
----
```


