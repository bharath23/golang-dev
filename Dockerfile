FROM golang:1.14.4-buster

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
EXPOSE 22

# copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# install required packages
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
	apt-transport-https \
	bash-completion \
	bind9-host \
	diffutils \
	exuberant-ctags \
	file \
	fonts-inconsolata \
	gnupg2 \
	jq \
	less \
	libcanberra-gtk-module \
	libcanberra-gtk3-module \
	locales \
	ncurses-term \
	netcat \
	net-tools \
	openssh-server \
	software-properties-common \
	sudo \
	tmux \
	unzip \
	vim-gtk3 \
	xauth \
	xclip \
	xtail \
	zip

# generate appropriate locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

# install docker cli
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
	&& add-apt-repository "deb https://download.docker.com/linux/debian buster stable" \
	&& apt-get update \
	&& apt-get install --no-install-recommends --yes docker-ce-cli

# install docker-compose
RUN curl -Ls https://github.com/docker/compose/releases/download/1.26.0/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose \
	&& echo "ff6816932a57eab448798105926adbe4363b82f217802b105ade2edad95706cb  /usr/local/bin/docker-compose" | sha256sum --check --quiet --status \
	&& chmod +x /usr/local/bin/docker-compose

# /run/sshd needs to exist for sshd to start
RUN mkdir /run/sshd && echo "AddressFamily inet" >> /etc/ssh/sshd_config
