# ~/.bashrc: executed by bash(1) for non-login shells.
#
# Scripted By: Andrew Haskell (aka WardenDrew)
# Last Updated: 2025.Jan.11
# MIT License

# If not running interactively, don't do anything
case $- in
	*i*) ;;
	  *) return;;
esac

# # # # # # # # # # # # # # # #
# Housekeeping Setup for Bash #
# # # # # # # # # # # # # # # #

printf "\e[m\n\e[90m#\e[m now \e[90m$(date -u +"%Y-%m-%dT%H:%M:%SZ") UTC";
printf "\e[m\n\e[90m#\e[m Scanning Versions, wait a moment...\e[m\n";

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth;

# append to the history file, don't overwrite it
shopt -s histappend;

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000;
HISTFILESIZE=2000;

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize;

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)";

# # # # # # # # # # # # # # # # # # # #
# Setup SDK's and other Path changes  #
# # # # # # # # # # # # # # # # # # # #

# We do this here so that we can get versions and include them in our prompt below

# Node Version Manager
export NVM_DIR="$HOME/.nvm";
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";  # This loads nvm bash_completion

# Rust Paths
. "$HOME/.cargo/env";

# Dotnet Versioning
export DOTNET_ROOT="$HOME/.dotnet";
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools";


# # # # # # # # # # #
# Bash Prompt Setup #
# # # # # # # # # # #

# Get the dotnet version
dotnet_version=$({ dotnet --version 2>/dev/null || echo; } | cut -d. -f1);

# Get the node version
node_version=$({ node --version 2>/dev/null || echo; } | cut -d. -f1 | sed 's/v//');

# Get the java version
java_version=$({ java --version 2>/dev/null || echo; } | head -n 1 | cut -d' ' -f2 | cut -d. -f1);

# Kube Version
kube_version=$(kubectl version | cut -d$'\n' -f1 | cut -d' ' -f3 | cut -d. -f1-2 | sed 's/v//');

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot);
fi

# Determine if we are the same user as the user that owns the TTY
whoami_user=$(whoami);
logname_user=$(logname);
print_user=; [[ "$whoami_user" == "$logname_user" ]] || print_user=0;

# Determine if we are in an SSH Session
print_host=; [[ -z "$SSH_TTY" ]] || { print_host=0 && print_user=0; }

# Load the Git Prompt Script used in the prompt below as __git_ps1
source ~/.git-prompt.sh;

function __git_status {
	local branch;
	branch=$(git branch --show-current 2>/dev/null);
	if [ $? -ne 0 ]; then
		return;
	fi

	printf "\e[m\n\e[90m#\e[m git ";
	printf "\e[1;35m$(__git_ps1 %s)\e[m";

	untracked=$(git status --porcelain | grep -c '^??');
	tracked=$(git status --porcelain | grep -c -v '^??');

	if [[ $untracked -gt 0 ]]; then
		printf "\e[90m|\e[1;31m${untracked}-dirty\e[m";
	fi

	if [[ $tracked -gt 0 ]]; then
		printf "\e[90m|\e[1;33m${tracked}-edits\e[m";
	fi

	local originUrl;
	originUrl=$(git config --get remote.origin.url 2>/dev/null);
	if [ $? -eq 0 ]; then
		printf "\e[90m from origin \e[m\e[4;34m$originUrl\e[m";
	fi;
}

# Start Building the Bash Prompt
ANSI_RESET="\[\e[m\]";
PS1_NEW_LINE="\n";
PS1_NEW_LINE+="\[\e[90m\]";
PS1_NEW_LINE+="#";
PS1_NEW_LINE+="$ANSI_RESET";

PS1="$ANSI_RESET";

# Check if the environment supports color
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)

	# LINE: Location
	PS1+="${PS1_NEW_LINE} loc ";

	# Build the chroot string
	PS1_CHROOT="\[\e[1;97;41\]";        # ANSI Bold + Bright-White Foreground + Red Background
	PS1_CHROOT+="($debian_chroot)";		# The chroot
	PS1_CHROOT+="$ANSI_RESET";
	PS1+="${debian_chroot:+$PS1_CHROOT}";

	# Build the user string if were not the tty owning user
	PS1_USER="\[\e[1;31m\]";
	PS1_USER+="$whoami_user";
	PS1_USER+="$ANSI_RESET";
	PS1+="${print_user:+$PS1_USER}";

	# Build the host string if we're in an SSH tty
	PS1_HOST="\[\e[1;5;41;97m\]";
	PS1_HOST+="@";
	PS1_HOST+="$ANSI_RESET";
	PS1_HOST+="\[\e[1;31m\]";
	PS1_HOST+="\H";
	PS1_HOST+="$ANSI_RESET";
	PS1+="${print_host:+$PS1_HOST}";

	PS1+="\[\e[1;31m\]";
	PS1+=":";
	PS1+="\[\e[37m\]";			# ANSI Blue Foreground
	PS1+="\w";				    # Working Directory
	PS1+="$ANSI_RESET";			# ANSI CSI Reset

	# LINE: VER
	PS1_RUN="";

	# Build the dotnet version string
	PS1_DOTNET=" \[\e[38;5;231;48;5;18m\]";
	PS1_DOTNET+="dotnet";
	PS1_DOTNET+="\[\e[1m\]";
	PS1_DOTNET+="$dotnet_version";
	PS1_DOTNET+="$ANSI_RESET";
	PS1_RUN+="${dotnet_version:+$PS1_DOTNET}";

	# Build the NodeJs version string
	PS1_NODEJS=" \[\e[38;5;231;48;5;22m\]";
	PS1_NODEJS+="node";
	PS1_NODEJS+="\[\e[1m\]";
	PS1_NODEJS+="$node_version";
	PS1_NODEJS+="$ANSI_RESET";
	PS1_RUN+="${node_version:+$PS1_NODEJS}";

	# Build the Java version string
	PS1_JAVA=" \[\e[38;5;231;48;5;208m\]";
	PS1_JAVA+="java";
	PS1_JAVA+="\[\e[1m\]";
	PS1_JAVA+="$java_version";
	PS1_JAVA+="$ANSI_RESET";
	PS1_RUN+="${java_version:+$PS1_JAVA}";

	# Build the Kube version string
	PS1_KUBE=" \[\e[38;5;231;48;5;92m\]";
	PS1_KUBE+="kube";
	PS1_KUBE+="\[\e[1m\]";
	PS1_KUBE+="$kube_version";
	PS1_KUBE+="$ANSI_RESET";
	PS1_RUN+="${kube_version:+$PS1_KUBE}";

	# If we have deps versions, add them to the start of the prompt
	PS1+="${PS1_RUN:+${PS1_NEW_LINE} ver$PS1_RUN}";

	# Function lines
	PS1+="\$(__git_status)";

	# LINE: RUN
	PS1+="${PS1_NEW_LINE}   ";
	PS1+="\[\e[1m\]";
	PS1+="$ ";
	PS1+="$ANSI_RESET";

else
	# No Color support RIP
	PS1+="${debian_chroot:+($debian_chroot)}";	# Optional chroot if present
	PS1+="\u";				# Username
	PS1+="@";				# Literal @
	PS1+="\h";				# Short Hostname
	PS1+=":";				# Literal :
	PS1+="\w";				# Working Directory
	PS1+="\$(__git_status)";# Optional git branch name with literal | preceding it
	PS1+="\$ ";				# Literal $ with a space following
fi

# If this is an xterm set the Icon Name and Windows Title
case "$TERM" in
xterm*|rxvt*)
	XTERM_TITLE="\[";		# Begin nesting the escape sequences
	XTERM_TITLE+="\e]0;"; 	# XTerm Escape: Set Icon Name and Window Title
	XTERM_TITLE+="${debian_chroot:+CHROOT}";	# Optional literal CHROOT if chrooted
	XTERM_TITLE+="\u";		# Username
	XTERM_TITLE+="@";		# Literal @
	XTERM_TITLE+="\h";		# Short Hostname
	XTERM_TITLE+=":";		# Literal :
	XTERM_TITLE+="\w";		# Working Directory
	#XTERM_TITLE+="\$(__git_status)";	# Optional git branch name with literal | preceding it
	XTERM_TITLE+="\a";		# ASCII BEL interpreted as XTerm End Escape Sequence 
	XTERM_TITLE+="\]";		# End nesting escape sequences

	# Insert XTerm title before Bash Prompt
	PS1="$XTERM_TITLE$PS1";

	# Cleanup
	unset XTERM_TITLE;
	;;
*)
	# We're not xterm so dont set the title
	;;
esac

# # # # # # # # # # # #
# Setup Bash Aliasing #
# # # # # # # # # # # #


# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	#alias dir='dir --color=auto'
	#alias vdir='vdir --color=auto'

	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -alF'
#alias la='ls -A'
#alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
  fi
fi

printf "\e[m\e[90m# ---------------------------------------- #\e[m";

# KEEP AT END
function PreCommand() {
	if [ -z "$AT_PROMPT" ]; then
		return;
	fi
	unset AT_PROMPT;

	printf "\e[m\e[90m# $(date -u +"%Y-%m-%dT%H:%M:%SZ") UTC\e[m\n";
	LAST_START_TIME=$(date +%s);
}
trap "PreCommand" DEBUG;

FIRST_PROMPT=1;
function PostCommand() {
	AT_PROMPT=1;

	if [ -n "$FIRST_PROMPT" ]; then
		unset FIRST_PROMPT;
		return;
	fi

	LAST_END_TIME=$(date +%s);
	LAST_TIME_DIFF=$((LAST_END_TIME-LAST_START_TIME));

	if [[ $LAST_TIME_DIFF -gt 0 ]]; then
		printf "\e[m\n\e[90m# ${LAST_TIME_DIFF}-sec";
		printf "\e[m\n\e[90m# ---------------------------------------- #\e[m";
	fi
}
PROMPT_COMMAND="PostCommand";

