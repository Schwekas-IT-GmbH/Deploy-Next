#!/bin/bash

echo -e "\e[92mDeploy-Next: Running \e[1m\e[33mAPT UPDATE\e[92m\e[0m..."
apt update

echo -e "\e[92mDeploy-Next: Running \e[1m\e[33mAPT UPGRADE\e[92m\e[0m...\e[39m"
apt upgrade -y

echo -e "\e[92mDeploy-Next: Installing \e[1m\e[33mUtilities\e[92m\e[0m...\e[39m"
apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
sleep 5

echo -e "\e[92mDeploy-Next: Adding \e[1m\e[33mGitLab Runner\e[92m\e[0m...\e[39m"
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

echo -e "\e[92mDeploy-Next: Pinning \e[1m\e[33mGitLab Runner\e[92m\e[0m...\e[39m"
cat <<EOF | tee /etc/apt/preferences.d/pin-gitlab-runner.pref
Explanation: Prefer GitLab provided packages over the Debian native ones
Package: gitlab-runner
Pin: origin packages.gitlab.com
Pin-Priority: 1001
EOF

echo -e "\e[92mDeploy-Next: Running \e[1m\e[33mAPT UPDATE\e[92m\e[0m...\e[39m"
apt update

echo -e "\e[92mDeploy-Next: Installing \e[1m\e[33mGitLab Runner\e[92m\e[0m...\e[39m"
apt install gitlab-runner -y
echo -e "\e[92mDeploy-Next: Done!"
sleep 5



echo -e "\e[92mDeploy-Next: Adding \e[1m\e[33mDocker\e[92m\e[0m...\e[39m"
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null


echo -e "\e[92mDeploy-Next: Running \e[1m\e[33mAPT UPDATE\e[92m\e[0m...\e[39m"
apt update

echo -e "\e[92mDeploy-Next: Installing \e[1m\e[33mDocker\e[92m\e[0m...\e[39m"
apt install docker-ce docker-ce-cli containerd.io docker-compose -y

echo -e "\e[92mDeploy-Next: Done!"
sleep 5





echo -e "\e[92mDeploy-Next: Configuring \e[1m\e[33mPermissions\e[92m\e[0m...\e[39m"
usermod -aG docker $USER
usermod -aG docker gitlab-runner


echo -e "\e[92mDeploy-Next: Configuring \e[1m\e[33mSystem Containers\e[92m\e[0m...\e[39m"
cd /
mkdir data
echo '{"data-root":"/data"}' > /etc/docker/daemon.json
docker network create traefik
cd data

echo -e "\e[92mDeploy-Next: Writing \e[1m\e[33mCompose File\e[92m\e[0m...\e[39m"
cat <<EOF | tee ./docker-compose.yml
version: "3.4"

networks:
    traefik:
        external: true

volumes:
    letsencrypt:
    certs:
    portainer:
    duplicati:
    config:
    logs:
    data:

services:
    traefik:
        image: "traefik:v2.6"
        container_name: "traefik"
        command:
            - "--providers.docker=true"
            - "--api.insecure=true"
            - "--providers.docker.exposedbydefault=false"
            - "--entrypoints.in_http.address=:80"
            - "--entrypoints.in_https.address=:443"
            - "--certificatesresolvers.acme_cfdns.acme.dnschallenge=true"
            - "--certificatesresolvers.acme_cfdns.acme.dnschallenge.provider=cloudflare"
            - "--certificatesresolvers.acme_cfdns.acme.email=[CHANGE_ME]"
            - "--certificatesresolvers.acme_cfdns.acme.storage=/letsencrypt/acme.json"
            - "--certificatesresolvers.acme_http.acme.httpchallenge=true"
            - "--certificatesresolvers.acme_http.acme.httpchallenge.entrypoint=in_http"
            - "--certificatesresolvers.acme_http.acme.email=[CHANGE_ME]"
            - "--certificatesresolvers.acme_http.acme.storage=/letsencrypt/acme.json"
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.dashboard.entrypoints=in_https"
            - "traefik.http.routers.dashboard.tls.certresolver=acme_cfdns"
            - "traefik.http.routers.dashboard.rule=Host(`[CHANGE_ME]`)"
            - "traefik.http.routers.dashboard.service=api@internal"
            - "traefik.http.routers.dashboard.middlewares=auth"
            - "traefik.http.middlewares.auth.basicauth.users=[CHANGE_ME]"
        ports:
            - "80:80"
            - "443:443"
        environment:
            - "CF_API_EMAIL=[CHANGE_ME]"
            - "CF_API_KEY=[CHANGE_ME]"
        volumes:
            - letsencrypt:/letsencrypt
            - "/var/run/docker.sock:/var/run/docker.sock:ro"
        networks:
            - traefik

    portainer:
        image: portainer/portainer-ce
        container_name: portainer
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.portainer.rule=Host(`[CHANGE_ME]`)"
            - "traefik.http.routers.portainer.entrypoints=in_https"
            - "traefik.http.routers.portainer.tls.certresolver=acme_cfdns"
            - "traefik.http.routers.portainer.service=portainer_srv"
            - "traefik.http.services.portainer_srv.loadbalancer.server.port=9000"
        expose:
            - 9000
        restart: always
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - portainer:/data
        networks:
            - traefik

    gitlab:
        image: "gitlab/gitlab-ce:latest"
        container_name: gitlab
        restart: always
        hostname: "[CHANGE_ME]"
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.gitlab.rule=Host(`[CHANGE_ME]`)"
            - "traefik.http.routers.gitlab.entrypoints=in_https"
            - "traefik.http.routers.gitlab.tls.certresolver=acme_cfdns"
            - "traefik.http.routers.gitlab.service=gitlab_srv"
            - "traefik.http.services.gitlab_srv.loadbalancer.server.port=80"
        environment:
            GITLAB_OMNIBUS_CONFIG: |
                external_url '[CHANGE_ME]'
                gitlab_rails['gitlab_shell_ssh_port'] = [CHANGE_ME]
                letsencrypt['enable'] = false
                nginx['listen_port'] = 80
                nginx['listen_https'] = false
        expose:
            - 80
        ports:
            - "[CHANGE_ME]:22"
        volumes:
            - certs:/etc/gitlab/ssl/
            - letsencrypt:/letsencrypt:ro
            - config:/etc/gitlab
            - logs:/var/log/gitlab
            - data:/var/opt/gitlab
        networks:
            - traefik

    duplicati:
        image: lscr.io/linuxserver/duplicati:latest
        container_name: duplicati
        environment:
            - PUID=0
            - PGID=0
            - TZ=Europe/Berlin
        volumes:
            - duplicati:/config
            - /data:/data
        ports:
          - 8200:8200
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.duplicati.rule=Host(`[CHANGE_ME]`)"
            - "traefik.http.routers.duplicati.entrypoints=in_https,in_http"
            - "traefik.http.routers.duplicati.tls.certresolver=acme_cfdns"
            - "traefik.http.routers.duplicati.service=duplicati_srv"
            - "traefik.http.services.duplicati_srv.loadbalancer.server.port=[CHANGE_ME]"
        restart: unless-stopped
        networks:
            - traefik
EOF

echo -e "\e[92mDeploy-Next: Starting \e[1m\e[33mSystem Containers\e[92m\e[0m...\e[39m"
docker-compose up -d --build

echo -e ""
echo -e ""
echo -e ""
echo -e ""
echo -e "\e[92m#########################\e[39m"
echo -e "\e[92m# Server Setup Finished #\e[39m"
echo -e "\e[92m#########################\e[39m"
echo -e ""
echo -e "\e[92mNecessary Packages have been installed, configs have been written!\e[39m"
echo -e ""
echo -e "\e[1mFurther Steps:\e[39m"
echo -e ""
echo -e "  1. Register the GitLab Runner on this Server by running \e[33m$ gitlab-runner register\e[39m"
echo -e "  2. Go to \e[33mhttp://$( curl -s http://whatismyip.akamai.com/ ):42069\e[39m to setup initial user for Portainer"
echo -e "  3. Open the docker-compose.yml in /data and replace all [CHANGE_ME] tags with your actual setup"
echo -e ""
echo -e "\e[91Note#1: Please dont forget to setup Portainer, otherwise someone could setup their own Admin-Account and steal Data!\e[39m"
echo -e "Note#2: If you want GitLab Runner to run simultaneous Tasks, run register again and update \e[33mconcurrent=X\e[39m in \e[33m/etc/gitlab-runner/config.toml\e[39m"
echo -e ""
echo -e "\e[1mGitLab Runner Setup Configuration (For Reference):\e[39m"
echo -e "";
echo -e "  1. \e[33mURL\e[39m: Your Instance URL"
echo -e "  2. \e[33mToken\e[39m: Get it from \e[33mGitLab -> [Any Group] -> Settings -> CI/CD -> Runners\e[39m"
echo -e "  3. \e[33mName\e[39m: Name of the Runner as shown in GitLab after registration. We recommend the ServerIP with underliens: Eg. 1_1_1_1"
echo -e "  4. \e[33mTags\e[39m: This defines, which Jobs get deployed here. To deploy a project here, the tag has to equal the specific CI Variable"
echo -e "  5. \e[33mExecutor\e[39m: You have to specify \e[33mshell\e[39m"
echo -e ""
echo -e "\e[92m-> For more Information read the README.md"

echo -e "\e[92mDeploy-Next: Running \e[1m\e[33mRunner Register\e[92m\e[0m now..."
echo -e "If you want to do this later you can abort the setup at this point with \e[33mCTRL+C\e[39m"
gitlab-runner register

