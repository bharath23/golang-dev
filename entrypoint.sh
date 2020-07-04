#!/bin/bash
set -e

# docker should be run as root
if [[ $EUID -ne 0 ]]; then
	echo "docker should be started as root"
	exit 1
fi

# test if all environment variables are set
if [ -z "$DOCKER_GID" ]; then
	echo "DOCKER_GID not set"
	exit 1
fi

if [ -z "$USER_GID" ]; then
	echo "USER_GID not set"
	exit 1
fi

if [ -z "$USER_UID" ]; then
	echo "USER_UID not set"
	exit 1
fi

if [ -z "$USER_LOGIN" ]; then
	echo "USER_LOGIN not set"
	exit 1
fi

if [ -z "$USER_SSH_KEY" ]; then
	echo "USER_SSH_KEY not set"
	exit 1
fi

# create docker group
groupadd -g $DOCKER_GID docker

# create user and enable sudo
groupadd -g $USER_GID $USER_LOGIN
useradd -l -m -g $USER_GID -G adm,docker -u $USER_UID -s /bin/bash $USER_LOGIN > /dev/null 2>&1
echo "$USER_LOGIN    ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/90-$USER_LOGIN
chmod 440 /etc/sudoers.d/90-$USER_LOGIN
chown $USER_LOGIN:$USER_LOGIN /home/$USER_LOGIN

# drop user into tmux and make ssh auth socket static
mkdir -p /home/$USER_LOGIN/.ssh
echo 'command="TERM=xterm-256color tmux new-session -A -s docker"' $USER_SSH_KEY >> /home/$USER_LOGIN/.ssh/authorized_keys
echo '# fix ssh auth socket symlink
if [  -S ${SSH_AUTH_SOCK} ]; then
	ln -sf ${SSH_AUTH_SOCK} $HOME/.ssh/ssh_auth_sock
fi

# add X11 cookies, taken from sshd(8) manpage
if read proto cookie && [ -n "$DISPLAY" ]; then
	if [ "echo $DISPLAY | cut -c1-10" = "localhost:" ]; then
		# X11UseLocalHost=yes
		echo add unix:"echo $DISPLAY | cut -c11-" $proto $cookie
	else
		echo add $DISPLAY $proto $cookie
	fi | xauth -q -
fi' >> /home/${USER_LOGIN}/.ssh/rc
chown -R $USER_LOGIN:$USER_LOGIN /home/$USER_LOGIN/.ssh
chmod 700 /home/$USER_LOGIN/.ssh

exec "$@"
