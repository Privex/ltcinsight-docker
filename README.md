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


## Quickstart

### Using init.sh for auto-install + auto-start on Ubuntu/Debian/CentOS/Oracle/others

The `init.sh` file will:

- Install any basic deps such as `curl`, `wget`, `jq`, and other important utils - if they're not already installed.

- If you don't already have config files at `docker-compose.yml`, `caddy/Caddyfile` and/or `.env`, then
  it will copy the example configs for you (for the compose file, it defaults to the binary image version).

- If you don't have Docker installed, then it will auto-install Docker using https://get.docker.com

- If you don't have `docker-compose` - will install `docker-compose` via `apt-get`, `dnf` / `yum`, `apk`, or `brew` - depending on which package manager
  is detected.

- Starts the Insight LiteCore system (API + WebUI + LTC Daemon) + Caddy webserver using `docker-compose up -d`

```sh
git clone https://github.com/Privex/ltcinsight-docker.git
cd ltcinsight-docker
./init.sh
```

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


