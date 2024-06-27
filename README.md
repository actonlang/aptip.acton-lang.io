# APT repo for Acton tip releases

Acton tip releases are like nightlies but more up to date.

Install Acton tip releases via this apt repository:
```sh
wget -q -O - https://aptip.acton-lang.io/acton.gpg | sudo apt-key add -
echo "deb http://aptip.acton-lang.io/ tip main" | sudo tee /etc/apt/sources.list.d/acton.list
sudo apt-get update
sudo apt-get install -qy acton
```
