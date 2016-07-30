# This file creates a container that runs X11 and SSH services
# The ssh is used to forward X11 and provide you encrypted data
# communication between the docker container and your local 
# machine.
#
# Xpra allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
# with disconnection and reconnection capabilities
#
# Xephyr allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
#
# Fluxbox and ROX-Filer creates a very minimalist way to 
# manages the windows and files.
#
# Original author: Roberto Gandolfo Hashioka
# Date: 07/28/2013
#
# Updates: justifiably

FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN echo exit 1 > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d

RUN apt-key update && apt-get update ; apt-get upgrade -y 

# Installing the environment required: xserver, xdm, flux box, roc-filer and ssh
RUN apt-get install -y xpra openssh-server \
    xserver-xephyr xvfb sudo \
    xterm 

# Util: (but pulls lost of python)
# RUN apt-get install -y pwgen

# For desktop
# RUN apt-get install -y xdm rox-filer fluxbox firefox

# Installing the apps: Firefox, flash player plugin, LibreOffice and xterm
# libreoffice-base installs libreoffice-java mentioned before
# RUN apt-get install -y libreoffice-base firefox libreoffice-gtk libreoffice-calc xterm
# RUN apt-get install -y xterm

# Configuring xdm to allow connections from any IP address and ssh to allow X11 Forwarding. 
RUN sed -i 's/DisplayManager.requestPort/!DisplayManager.requestPort/g' /etc/X11/xdm/xdm-config && \
    sed -i '/#any host/c\*' /etc/X11/xdm/Xaccess && \
    echo X11Forwarding yes >> /etc/ssh/ssh_config
# RUN ln -s /usr/bin/Xorg /usr/bin/X

# Fix PAM login issue with sshd
RUN sed -i 's/session    required     pam_loginuid.so/#session    required     pam_loginuid.so/g' /etc/pam.d/sshd

# Upstart and DBus have issues inside docker. We work around in order to install firefox.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# Installing fuse package (libreoffice-java dependency) and it's going to try to create
# a fuse device without success, due the container permissions. || : help us to ignore it. 
# Then we are going to delete the postinst fuse file and try to install it again!
# Thanks Jerome for helping me with this workaround solution! :)
# Now we are able to install the libreoffice-java package  
# RUN apt-get -y install fuse  || :
# RUN rm -rf /var/lib/dpkg/info/fuse.postinst
# RUN apt-get -y install fuse

# Set locale (this is what install-language-pack script does)
RUN /usr/sbin/locale-gen  --keep-existing en_GB.UTF-8 && \
    update-locale LANG=en_GB.UTF-8 LC_ALL=en_GB

# Copy the files into the container
ADD /src /src

EXPOSE 22
# Start xdm and ssh services.
CMD ["/bin/bash", "/src/startup.sh"]
