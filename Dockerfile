##############################################################
# FROM must be the first command in a dockerfile
# Specify Ubuntu digest to pull from
##############################################################

FROM accretechsbs/ubuntu:22.04

##############################################################
# Use DEBIAN_FRONTEND=noninteractive to avoid image build
# hang waiting for a default confirmation [Y/n] at some configurations.
##############################################################
ENV DEBIAN_FRONTEND="noninteractive" TZ="US/Pacific"

##############################################################
# Install dependencies
##############################################################

RUN apt-get update && apt upgrade -y

RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata

##############################################################
# Bitbake and Petalinux Dependencies
##############################################################

RUN DEBIAN_FRONTEND=noninteractive apt install -y --fix-missing \
  software-properties-common openssh-client gawk wget git diffstat unzip \
  texinfo file tar gcc-multilib build-essential chrpath git-lfs socat cpio \
  python3 python3-pip python3-pexpect expect xz-utils debianutils \
  iputils-ping python3-jinja2 libegl1-mesa libsdl1.2-dev \
  xterm rsync curl locales apt-utils sudo vim bash-completion screen \
  python3-subunit mesa-common-dev zstd liblz4-tool zstd net-tools \
  ca-certificates less nano bc jq bison qemu-system-arm tree libtinfo5 \
  autoconf libncurses5-dev libncursesw5-dev zlib1g-dev tftpd libtool 

RUN dpkg --add-architecture i386 && apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  zlib1g:i386 libc6-dev:i386 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository universe && \
  apt-get update && apt install -y libtinfo5 

###############################################################
# Map Host user to container
##############################################################

ARG DOCKER_USER=petalinux
ARG U_ID=1000
ARG G_ID=1000

RUN groupadd -g ${G_ID} host-users 2> /dev/null && \
    useradd ${DOCKER_USER} -u ${U_ID} -g ${G_ID} -s /bin/bash && \
    echo "${DOCKER_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

##############################################################
# Install additional utilities not available through apt
##############################################################

# https://docs.yoctoproject.org/4.0.11/ref-manual/system-requirements.html?highlight=pylint#ubuntu-and-debian
RUN pip3 install GitPython pylint

# Install the google repo utility
RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo 
RUN chmod a+x /usr/local/bin/repo

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the source command
# needed for setting up Yocto build environments. Use bash as an alias for sh.
RUN which dash &> /dev/null && (\
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash) || \
    echo "Skipping dash reconfigure (not applicable)"

# Generate locales
RUN locale-gen en_US.UTF-8

# Define the locale we will use
ENV LANG en_US.UTF-8

# Enable improved syntax highlighting for nano (including .bb bitbake files)
RUN cd /usr/share/nano \
    && wget https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -O- | sh \
    && git clone https://github.com/saizen408/bitbake_nanorc.git /tmp/bitbake_nanorc \
    && cp /tmp/bitbake_nanorc/bb.nanorc /usr/share/nano/

ENV MICRO_CONFIG_HOME="/etc/micro"

# Install micro text editor and move the bb.yaml file into the micro config folder
RUN cd /usr/bin \
    && curl https://getmic.ro | bash \
    && mkdir -p ${MICRO_CONFIG_HOME}/syntax \
    && cp /tmp/bitbake_nanorc/bb.yaml ${MICRO_CONFIG_HOME}/syntax

##############################################################
# Install Petalinux 
# Source: https://github.com/carlesfernandez/docker-petalinux
##############################################################

# the HTTP server to retrieve the files from.
ARG HTTP_SERV=http://172.17.0.1:8000/installers
ARG PETA_RUN_FILE=petalinux-v2023.1-05012318-installer.run

COPY accept-eula.sh /

# run the Petalinux installer
RUN cd / && wget -q ${HTTP_SERV}/${PETA_RUN_FILE} && \
  chmod a+rx /${PETA_RUN_FILE} && \
  chmod a+rx /accept-eula.sh && \
  mkdir -p /opt/Xilinx && \
  chmod 777 /tmp /opt/Xilinx && \
  cd /tmp && \
  sudo -u ${DOCKER_USER} -i /accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux && \
  rm -f /${PETA_RUN_FILE} /accept-eula.sh

# source petalinux upon each login of the container
RUN echo ". /opt/Xilinx/petalinux/settings.sh" >> /etc/profile && \
    echo "/usr/sbin/in.tftpd --foreground --listen --address [::]:69 --secure /tftpboot" >> /etc/profile && \
    echo ". /etc/profile" >> /root/.profile

# Set up user environment
ENV TERM=xterm-256color


#Todo: Add tftp support
EXPOSE 69/udp

# Switch to work directory
RUN mkdir -p /yocto && \
    chmod 755 /yocto
    
WORKDIR /yocto

USER ${DOCKER_USER}

ENTRYPOINT ["/bin/bash", "-l"]