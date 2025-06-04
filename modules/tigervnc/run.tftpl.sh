#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

function example_admonition {
	cat <<-EOH
		‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
		‼️‼️‼️‼️ This is an example module to be used as a starting point ‼️‼️‼️‼️
		‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
	EOH
}

function error { echo "💀 ERROR: $1" >&2; example_admonition; exit 1; }
function warn  { echo "⚠️ WARNING: $1" >&2; }
function info  { echo "💁 INFO: $1"; }
function debug { if [[ "${DEBUG}" == "true" ]]; then echo "👷 DEBUG: $1"; fi; }

example_admonition

# Function to check if vncserver is already installed
check_installed() {
  if command -v vncserver &> /dev/null; then
    info "vncserver is already installed."
    return 0 # Don't exit, just indicate it's installed
  else
    return 1 # Indicates not installed
  fi
}

# Function to download a file using wget, curl, or busybox as a fallback
download_file() {
  local url="$1"
  local output="$2"
  local download_tool

  if command -v curl &> /dev/null; then
    # shellcheck disable=SC2034
    download_tool=(curl -fsSL)
  elif command -v wget &> /dev/null; then
    # shellcheck disable=SC2034
    download_tool=(wget -q -O-)
  elif command -v busybox &> /dev/null; then
    # shellcheck disable=SC2034
    download_tool=(busybox wget -O-)
  else
    error "No download tool available (curl, wget, or busybox required)"
  fi

  # shellcheck disable=SC2288
  "$${download_tool[@]}" "$url" > "$output" || {
    error "Failed to download $url"
  }
}

# Function to install TigerVNC server for debian-based distros
install_deb() {
  CACHE_DIR="/var/lib/apt/lists/partial"
  # Check if the directory exists and was modified in the last 60 minutes
  if [[ ! -d "$CACHE_DIR" ]] || ! find "$CACHE_DIR" -mmin -60 -print -quit &> /dev/null; then
    debug "Stale package cache, updating..."
    # Update package cache with a 300-second timeout for dpkg lock
    sudo apt-get -o DPkg::Lock::Timeout=300 -qq update
  fi
  info "Installing TigerVNC using apt-get..."

  DEBIAN_FRONTEND=noninteractive sudo apt-get -o DPkg::Lock::Timeout=300 install \
    --yes --no-install-recommends --no-install-suggests \
    tigervnc-standalone-server tigervnc-common tigervnc-tools websockify 2>&1

  if [ $? -ne 0 ]; then
    error "Failed to install TigerVNC packages"
  fi
}

# Function to install tigervncserver for rpm-based distros
install_rpm() {
  local tigerpkg="tigervnc-server"
  local package_manager

  if command -v dnf &> /dev/null; then
    # shellcheck disable=SC2034
    package_manager=(dnf -y)
  elif command -v zypper &> /dev/null; then
    # shellcheck disable=SC2034
    package_manager=(zypper install -y)
  elif command -v yum &> /dev/null; then
    # shellcheck disable=SC2034
    package_manager=(yum -y)
  elif command -v rpm &> /dev/null; then
    # Do we need to manually handle missing dependencies?
    # shellcheck disable=SC2034
    package_manager=(rpm -i)
  else
    error "No supported package manager available (dnf, zypper, yum, or rpm required)"
  fi

  # shellcheck disable=SC2288
  sudo "$${package_manager[@]}" $tigerpkg || {
    error "Failed to install $tigerpkg"
  }
}

# Function to install tigervncserver for Alpine Linux
install_alpine() {
  local tigerpkg=tigervnc

  apk add $tigerpkg || {
    error "Failed to install $tigerpkg"
  }
}

# Detect system information
if [[ ! -f /etc/os-release ]]; then
  error "Cannot detect OS: /etc/os-release not found"
fi

# shellcheck disable=SC1091
source /etc/os-release
distro="$ID"
distro_version="$VERSION_ID"
codename="$VERSION_CODENAME"
arch="$(uname -m)"
if [[ "$ID" == "ol" ]]; then
  distro="oracle"
  distro_version="$${distro_version%%.*}"
elif [[ "$ID" == "fedora" ]]; then
  distro_version="$(grep -oP '\(\K[\w ]+' /etc/fedora-release | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
fi

echo "🕵️‍♀️ Inspecting system information..."
echo "  🫆 Detected Distribution: $distro"
echo "  🫆 Detected Version: $distro_version"
echo "  🫆 Detected Codename: $codename"
echo "  🫆 Detected Architecture: $arch"

# Map arch to package arch
case "$arch" in
  x86_64)
    if [[ "$distro" =~ ^(ubuntu|debian|kali)$ ]]; then
      arch="amd64"
    fi
    ;;
  aarch64)
    if [[ "$distro" =~ ^(ubuntu|debian|kali)$ ]]; then
      arch="arm64"
    fi
    ;;
  arm64)
    : # This is a noop
    ;;
  amd64)
    : # This is a noop
    ;;
  *)
    error "Unsupported architecture: $arch"
    ;;
esac

# Check if vncserver is installed, and install if not
if ! check_installed; then
  # Check for NOPASSWD sudo (required)
  if ! command -v sudo &> /dev/null || ! sudo -n true 2> /dev/null; then
    error "sudo NOPASSWD access required!"
  fi

  case $distro in
    ubuntu | debian | kali)
      install_deb
      ;;
    oracle | fedora | opensuse)
      install_rpm
      ;;
    alpine)
      install_alpine
      ;;
    *)
      echo "Unsupported distribution: $distro"
      ;;
  esac
else
  echo "vncserver already installed. Skipping installation."
fi

# Create an empty Xauthority file if one doesn't already exist
touch /home/coder/.Xauthority

mkdir -p "$HOME/.vnc/noVNC"
if [[ ! -d "$HOME/.vnc" ]]; then
  error "Failed to create $HOME/.vnc directory"
fi

# This password is not used since we start the server without auth.
# The server is protected via the Coder session token / tunnel
# and does not listen publicly
printf "password\npassword\n" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

VNC_LOG="/tmp/tigervncserver.log"

# Start the VNC server with the specified desktop environment. It is not
# necessary to explicitly background it with '&' because it forks after starting.
printf "🚀 Starting TigerVNC server...\n"

set +eu  # Temporarily disable undefined variable checks and
vncserver \
  -localhost \
  -SecurityTypes None \
  -rfbunixpath "$HOME/.vnc/vnc.sock" \
  -xstartup
RETVAL=$?
set -eu  # Re-enable strict mode

if [[ $RETVAL -ne 0 ]]; then
  echo "Failed to start TigerVNC server. Return code: $RETVAL"
    if [[ -f "$VNC_LOG" ]]; then
      # This state can not leverage the 'error' function because it needs to
      #  compose the error text and optionally print the log file contents.
      echo "Full logs:"
      cat "$VNC_LOG"
      exit 1
    fi
    error "Log file not found: $VNC_LOG"
fi

download_file https://github.com/novnc/noVNC/archive/refs/tags/v1.6.0.tar.gz /tmp/novnc.tar.gz

# Untar and remove the first path component in the tarball because it contains
# the version number
tar -xzf /tmp/novnc.tar.gz -C $HOME/.vnc/noVNC --strip-components=1

# Clean up the downloaded tarball
rm -f /tmp/novnc.tar.gz

# This function patches the noVNC web application files to support path-sharing
# by creating a symlink to the path_vnc.html file.
patch_novnc_http_files(){
    local httpdir="$HOME/.vnc/noVNC"
    if [[ ! -d "$httpdir" ]]; then
      error "$httpdir is not a directory"
    fi

    pushd "$httpdir" > /dev/null

    # Create the path_vnc.html file with the necessary content passed directly
    # in from Terraform using the PATH_VNC_HTML variable. Note that this is not
    # a Bash variable, but a Terraform variable that is passed in via templating.
    cat <<'EOH' > /tmp/path_vnc.html
${PATH_VNC_HTML}
EOH

    # Move the file to the current directory
    $SUDO mv /tmp/path_vnc.html .

    # Link the path_vnc.html file to index.html so that the bounce page is served
    # when the user accesses the VNC server via the path.
    $SUDO ln -s -f path_vnc.html index.html

    popd > /dev/null
}

if [[ "${SUBDOMAIN}" == "false" ]]; then
  echo "🩹 Patching up webserver files to support path-sharing..."
  patch_novnc_http_files
else
  ln -sf "$HOME/.vnc/noVNC/vnc.html" "$HOME/.vnc/noVNC/index.html"
fi

set +eu
# Start the websockify server
websockify \
  --web "$HOME/.vnc/noVNC" \
  --unix-target "$HOME/.vnc/vnc.sock" \
  --log-file "$VNC_LOG" \
  --daemon \
  127.0.0.1:6800
RETVAL=$?
set -eu

if [[ $RETVAL -ne 0 ]]; then
  error "Failed to start websockify process. Return code: $RETVAL"
    if [[ -f "$VNC_LOG" ]]; then
    echo "Full logs:"
    cat "$VNC_LOG"
  else
    error "Log file not found: $VNC_LOG"
  fi
  exit 1
fi

echo "🚀 TigerVNC server started successfully!"
example_admonition
