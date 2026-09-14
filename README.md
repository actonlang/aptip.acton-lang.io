# APT repo for Acton tip releases

Acton tip releases are like nightlies but more up to date.

Install Acton tip releases via this apt repository:
```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo wget -q -O /etc/apt/keyrings/acton.asc https://aptip.acton-lang.io/acton.gpg
sudo chmod a+r /etc/apt/keyrings/acton.asc
echo "deb [signed-by=/etc/apt/keyrings/acton.asc] http://aptip.acton-lang.io/ tip main" | sudo tee /etc/apt/sources.list.d/acton.list
sudo apt-get update
sudo apt-get install -qy acton
```

The repository keeps the newest releases within a 9 GB budget.
Daily cleanup limits the files retained on `main`.
Each publication also checks the generated APT repository and removes the oldest
versions, including both architectures, until the published files fit. Publication
fails if the newest release alone cannot fit. Git history and the incoming `deb/`
copies are not published.
