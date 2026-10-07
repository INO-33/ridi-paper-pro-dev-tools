FROM ubuntu:16.04

ARG BISON_VERSION=2:3.0.4.dfsg-1

LABEL org.opencontainers.image.title="chromium-m58-build" \
      org.opencontainers.image.description="Reproducible Ubuntu Xenial host for Chromium 58 Android x86" \
      chromium.source.commit="ea0431421ddfe47264648f03189763cf4bafa9ea" \
      chromium.bison.version="3.0.4" \
      chromium.python.version="2.7" \
      chromium.java.version="8"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HOME=/tmp/m58-home

# Ubuntu Xenial is EOL. This environment still serves Xenial from the main
# archive, while old-releases.ubuntu.com returns 404, so keep the endpoint
# normalization and expired Release-file workaround inside the image.
RUN sed -i \
      -e 's|http://old-releases.ubuntu.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' \
      -e 's|http://security.ubuntu.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' \
      /etc/apt/sources.list \
 && printf '%s\n' \
      'Acquire::Check-Valid-Until "false";' \
      'Acquire::Retries "3";' \
      > /etc/apt/apt.conf.d/99xenial-archive \
 && dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      curl \
      debconf-utils \
      file \
      lsb-release \
      sudo \
      wget \
 && rm -rf /var/lib/apt/lists/*

# This package set follows M58 build/install-build-deps.sh plus the Android
# additions in build/install-build-deps-android.sh. The explicit Bison pin is
# required by M58's historical rule_bison.py on Xenial.
RUN apt-get update \
 && echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true' | debconf-set-selections \
 && apt-get install -y --no-install-recommends \
      apache2-bin \
      ant \
      autoconf \
      bison=${BISON_VERSION} \
      bsdiff \
      build-essential \
      cdbs \
      cmake \
      flex \
      fonts-ipafont \
      fonts-indic \
      fonts-thai-tlwg \
      gawk \
      gperf \
      git \
      git-svn \
      g++-5-multilib \
      lib32gcc1 \
      lib32stdc++6 \
      lib32z1 \
      libc6-i386 \
      libasound2-dev \
      libav-tools \
      libbluetooth-dev \
      libbrlapi-dev \
      libbz2-dev \
      libcairo2-dev \
      libcap-dev \
      libcups2-dev \
      libcurl4-gnutls-dev \
      libdrm-dev \
      libelf-dev \
      libffi-dev \
      libgbm-dev \
      libgconf2-dev \
      libglib2.0-dev \
      libglu1-mesa-dev \
      libgl1-mesa-dev \
      libgles2-mesa-dev \
      libgnome-keyring-dev \
      libgtk-3-dev \
      libgtk2.0-dev \
      libapache2-mod-php7.0 \
      libjpeg-dev \
      libkrb5-dev \
      libncurses5:i386 \
      libnspr4-dev \
      libnss3-dev \
      libpam0g-dev \
      libpci-dev \
      libpulse-dev \
      libsctp-dev \
      libspeechd-dev \
      libsqlite3-dev \
      libssl-dev \
      libstdc++6:i386 \
      libudev-dev \
      libwww-perl \
      libx11-dev \
      libxkbcommon-dev \
      libxslt1-dev \
      libxss-dev \
      libxt-dev \
      libxtst-dev \
      linux-libc-dev:i386 \
      m4 \
      mesa-common-dev \
      ninja-build \
      openbox \
      openjdk-8-jdk \
      openjdk-8-jre \
      patch \
      perl \
      php7.0-cgi \
      pkg-config \
      python \
      python-cherrypy3 \
      python-crypto \
      python-dev \
      python-numpy \
      python-opencv \
      python-openssl \
      python-pexpect \
      python-psutil \
      python-yaml \
      realpath \
      rpm \
      ruby \
      subversion \
      ttf-dejavu-core \
      ttf-mscorefonts-installer \
      unzip \
      wdiff \
      x11-utils \
      xcompmgr \
      xutils-dev \
      xvfb \
      zip \
      zlib1g:i386 \
 && update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java \
 && update-alternatives --set javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac \
 && mkdir -p /tmp/m58-home \
 && chmod 1777 /tmp/m58-home \
 && python --version 2>&1 | grep -F '2.7.' \
 && java -version 2>&1 | grep -F '1.8.0' \
 && javac -version 2>&1 | grep -F '1.8.0' \
 && bison --version | grep -F '3.0.4'

# install-build-deps-android.sh adds lighttpd after the base dependency pass.
RUN apt-get install -y --no-install-recommends lighttpd

COPY build_in_container.sh /usr/local/bin/build-m58-xenial-x86
RUN chmod 0755 /usr/local/bin/build-m58-xenial-x86

WORKDIR /work/src
ENTRYPOINT ["/usr/local/bin/build-m58-xenial-x86"]
