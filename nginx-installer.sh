#!/bin/bash

isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "Please run this script with root permissions..."
        echo "Try typing sudo ./nginx-installer.sh"
		exit 1
	fi
}

match_sig () {
  sig = `gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg`
  valid = 'pub rsa2048 2011-08-19 [SC] [expires: 2024-06-14] 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 uid nginx signing key <signing-key@nginx.com>'
  if [[ "$sig" != "$valid" ]]; then
      echo -$'\n\nSignature mismatch, please try again later...'
      exit 1
  fi
}

stable() {
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
}

mainline () {
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
}

#############################################################################

isRoot
echo "Installer for debian systems only"
echo "Press ctrl+c if you are not sure if your system is debian"
sleep 3
echo "We will proceed with installation then..."

echo "Which version of nginx do you want? (1 or 2)"
echo "1. Stable (Older but very well tested - might not have the latest features)"
echo "2. Mainline (Newer, latest features, relatively less tested - still good)"
ver=?

echo "Do you want nginx to start on boot? (yes/no)"
startonboot='?'

sudo apt install curl gnupg2 ca-certificates lsb-release debian-archive-keyring
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
match_sig

if (ver==1) {stable}
if (ver==2) {mainline}

echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx

sudo apt update
sudo apt install nginx

if (startonboot==true) {sudo systemctl enable --now nginx}

sudo systemctl start nginx

echo "DONE!"
sleep 1
systemctl status nginx
