FROM node:8-buster

LABEL maintainer="Chris @ Privex Inc. https://www.privex.io [ support at privex dot io ]"
LABEL description="A standalone Docker image containing a pre-setup Litecoin Insight block explorer instance. \
For persistence, make sure to mount a local folder from the host system as a volume onto /ltc/data \
which will store both the blockchain / chainstate data for the integrated litecoind node, as well as the \
indexed database created by Insight as it builds a database from litecoind's blockchain data. \
Official repo: https://github.com/Privex/ltcinsight-docker \
Original Litecore (LTC Insight) used: https://github.com/litecoin-project/litecore-node \
Privex Litecore Fork: https://github.com/Privex/litecore-node"
LABEL repo="https://github.com/Privex/ltcinsight-docker"

RUN apt-get update -qy && \
    apt-get install -qy git build-essential make gcc g++ cmake bison m4 libzmq3-dev net-tools bsdmainutils && \
    apt-get clean -qy

WORKDIR /root

ARG VERSION="master"
ENV VERSION ${VERSION}

#ARG PKG_SRC="https://github.com/Privex/litecore-node/archive/${VERSION}.tar.gz"
ARG PKG_SRC="https://github.com/Privex/litecore-node.git"
ENV PKG_SRC ${PKG_SRC}

#RUN git clone https://github.com/Privex/litecore-node.git -b develop && \
#    cd litecore-node && \
#RUN npm install -g https://github.com/Privex/litecore-node/archive/develop.zip
RUN git clone "$PKG_SRC" -b "$VERSION" litecore-node && \
    cd litecore-node && \
    git log --color=always --date=iso --pretty="format:%cd||%H||%an||%s" | head -n1 | column -s '||' -t > /repo_ver.txt && \
    git describe --tags > /repo_tag.txt && \
    cd .. && echo " >>> Tarring up litecore-node into lnode.tar ..." && \
    tar cvf /root/lnode.tar litecore-node && \
    echo " >>> Removing old litecore-node folder ..." && \
    rm -rvf litecore-node && \
    echo " >>> Installing /root/lnode.tar using 'npm install --unsafe-perm -g /root/lnode.tar'" && \
    npm install --unsafe-perm -g /root/lnode.tar && \
    echo " >>> Removing old tar file..." && rm -rvf /root/lnode.tar

#    cd .. && \
#    rm -rf litecore-node

# RUN npm install -g litecore-node@latest

RUN cd / && litecore-node create ltc

WORKDIR /ltc

RUN cd /ltc && \
    litecore-node install insight-lite-api && \
    litecore-node install insight-lite-ui

ARG ltc_ver="0.13.2"
ENV ltc_ver ${ltc_ver}

COPY ./bin/litecoin-cli ./bin/entry.sh /usr/bin/
RUN chmod +x /usr/bin/litecoin-cli /usr/bin/entry.sh

RUN echo "This container has been built with the following options:" >> /version.txt && \
    echo "----" >> /version.txt && \
    echo "Git Repository:              ${PKG_SRC}" >> /version.txt && \
    echo "Git version/commit:          ${VERSION}\n----" >> /version.txt && \
    echo "Closest Git Tag (version):   $(cat /repo_tag.txt)\n" >> /version.txt && \
    echo "Last Git Commit:             $(cat /repo_ver.txt)\n" >> /version.txt && \
    echo "----\nBuilt at: $(date)\n----" >> /version.txt

VOLUME /ltc/data

# Insight web server port
# Serves insight webui at http://<ip>:3001/insight/
EXPOSE 3001
# P2P Port for litecoind
EXPOSE 9333

ENTRYPOINT [ "/usr/bin/entry.sh" ]

