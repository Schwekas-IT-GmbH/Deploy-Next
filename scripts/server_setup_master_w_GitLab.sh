#!/bin/bash

echo -e "\e[92mJamStrapper: Running \e[1m\e[33mAPT UPDATE\e[92m\e[0m..."
apt update

echo -e "\e[92mJamStrapper: Running \e[1m\e[33mAPT UPGRADE\e[92m\e[0m...\e[39m"
apt upgrade -y

echo -e "\e[92mJamStrapper: Installing \e[1m\e[33mUtilities\e[92m\e[0m...\e[39m"
apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
sleep 5

echo -e "\e[92mJamStrapper: Adding \e[1m\e[33mGitLab Runner\e[92m\e[0m...\e[39m"
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

echo -e "\e[92mJamStrapper: Pinning \e[1m\e[33mGitLab Runner\e[92m\e[0m...\e[39m"
cat <<EOF | tee /etc/apt/preferences.d/pin-gitlab-runner.pref
Explanation: Prefer GitLab provided packages over the Debian native ones
Package: gitlab-runner
Pin: origin packages.gitlab.com
Pin-Priority: 1001
EOF

echo -e "\e[92mJamStrapper: Running \e[1m\e[33mAPT UPDATE\e[92m\e[0m...\e[39m"
apt update

echo -e "\e[92mJamStrapper: Installing \e[1m\e[33mGitLab Runner\e[92m\e[0m...\e[39m"
apt install gitlab-runner -y
echo -e "\e[92mJamStrapper: Done!"
sleep 5



echo -e "\e[92mJamStrapper: Adding \e[1m\e[33mDocker\e[92m\e[0m...\e[39m"
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null


echo -e "\e[92mJamStrapper: Running \e[1m\e[33mAPT UPDATE\e[92m\e[0m...\e[39m"
apt update

echo -e "\e[92mJamStrapper: Installing \e[1m\e[33mDocker\e[92m\e[0m...\e[39m"
apt install docker-ce docker-ce-cli containerd.io docker-compose -y

echo -e "\e[92mJamStrapper: Done!"
sleep 5





echo -e "\e[92mJamStrapper: Configuring \e[1m\e[33mPermissions\e[92m\e[0m...\e[39m"
usermod -aG docker $USER
usermod -aG docker gitlab-runner


echo -e "\e[92mJamStrapper: Configuring \e[1m\e[33mSystem Containers\e[92m\e[0m...\e[39m"
cd /
mkdir data
echo '{"data-root":"/data"}' > /etc/docker/daemon.json
docker network create nginx-proxy
cd data

echo -e "\e[92mJamStrapper: Writing \e[1m\e[33mNginx Template\e[92m\e[0m...\e[39m"
cat <<EOF | tee nginx.tmpl
{{ $CurrentContainer := where $ "ID" .Docker.CurrentContainerID | first }}

{{ $external_http_port := coalesce $.Env.HTTP_PORT "80" }}
{{ $external_https_port := coalesce $.Env.HTTPS_PORT "443" }}
{{ $debug_all := $.Env.DEBUG }}
{{ $sha1_upstream_name := parseBool (coalesce $.Env.SHA1_UPSTREAM_NAME "false") }}

{{ define "ssl_policy" }}
	{{ if eq .ssl_policy "Mozilla-Modern" }}
		ssl_protocols TLSv1.3;
		{{/* nginx currently lacks ability to choose ciphers in TLS 1.3 in configuration, see https://trac.nginx.org/nginx/ticket/1529 /*}}
		{{/* a possible workaround can be modify /etc/ssl/openssl.cnf to change it globally (see https://trac.nginx.org/nginx/ticket/1529#comment:12 ) /*}}
		{{/* explicitly set ngnix default value in order to allow single servers to override the global http value */}}
		ssl_ciphers HIGH:!aNULL:!MD5;
		ssl_prefer_server_ciphers off;
	{{ else if eq .ssl_policy "Mozilla-Intermediate" }}
		ssl_protocols TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
		ssl_prefer_server_ciphers off;
	{{ else if eq .ssl_policy "Mozilla-Old" }}
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA';
		ssl_prefer_server_ciphers on;
	{{ else if eq .ssl_policy "AWS-TLS-1-2-2017-01" }}
		ssl_protocols TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:AES128-GCM-SHA256:AES128-SHA256:AES256-GCM-SHA384:AES256-SHA256';
		ssl_prefer_server_ciphers on;
	{{ else if eq .ssl_policy "AWS-TLS-1-1-2017-01" }}
		ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA';
		ssl_prefer_server_ciphers on;
	{{ else if eq .ssl_policy "AWS-2016-08" }}
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA';
		ssl_prefer_server_ciphers on;
	{{ else if eq .ssl_policy "AWS-2015-05" }}
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA:DES-CBC3-SHA';
		ssl_prefer_server_ciphers on;
	{{ else if eq .ssl_policy "AWS-2015-03" }}
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA:DHE-DSS-AES128-SHA:DES-CBC3-SHA';
		ssl_prefer_server_ciphers on;
	{{ else if eq .ssl_policy "AWS-2015-02" }}
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
		ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA:DHE-DSS-AES128-SHA';
		ssl_prefer_server_ciphers on;
	{{ end }}
{{ end }}

# If we receive X-Forwarded-Proto, pass it through; otherwise, pass along the
# scheme used to connect to this server
map $http_x_forwarded_proto $proxy_x_forwarded_proto {
  default $http_x_forwarded_proto;
  ''      $scheme;
}

# If we receive X-Forwarded-Port, pass it through; otherwise, pass along the
# server port the client connected to
map $http_x_forwarded_port $proxy_x_forwarded_port {
  default $http_x_forwarded_port;
  ''      $server_port;
}

# If we receive Upgrade, set Connection to "upgrade"; otherwise, delete any
# Connection header that may have been passed to this server
map $http_upgrade $proxy_connection {
  default upgrade;
  '' close;
}

# Apply fix for very long server names
server_names_hash_bucket_size 128;

# Default dhparam
{{ if (exists "/etc/nginx/dhparam/dhparam.pem") }}
ssl_dhparam /etc/nginx/dhparam/dhparam.pem;
{{ end }}

# Set appropriate X-Forwarded-Ssl header based on $proxy_x_forwarded_proto
map $proxy_x_forwarded_proto $proxy_x_forwarded_ssl {
  default off;
  https on;
}

gzip_types text/plain text/css application/javascript application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

log_format vhost '$host $remote_addr - $remote_user [$time_local] '
                 '"$request" $status $body_bytes_sent '
                 '"$http_referer" "$http_user_agent" '
                 '"$upstream_addr"';

access_log off;

{{/* Get the SSL_POLICY defined by this container, falling back to "Mozilla-Intermediate" */}}
{{ $ssl_policy := or ($.Env.SSL_POLICY) "Mozilla-Intermediate" }}
{{ template "ssl_policy" (dict "ssl_policy" $ssl_policy) }}

{{ if $.Env.RESOLVERS }}
resolver {{ $.Env.RESOLVERS }};
{{ end }}

{{ if (exists "/etc/nginx/proxy.conf") }}
include /etc/nginx/proxy.conf;
{{ else }}
# HTTP 1.1 support
proxy_http_version 1.1;
proxy_buffering off;
proxy_set_header Host $http_host;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $proxy_connection;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
proxy_set_header X-Forwarded-Ssl $proxy_x_forwarded_ssl;
proxy_set_header X-Forwarded-Port $proxy_x_forwarded_port;

# Mitigate httpoxy attack (see README for details)
proxy_set_header Proxy "";
{{ end }}

{{ $access_log := (or (and (not $.Env.DISABLE_ACCESS_LOGS) "access_log /var/log/nginx/access.log vhost;") "") }}

{{ $enable_ipv6 := eq (or ($.Env.ENABLE_IPV6) "") "true" }}
server {
	server_name _; # This is just an invalid value which will never trigger on a real hostname.
	server_tokens off;
	listen {{ $external_http_port }};
	{{ if $enable_ipv6 }}
	listen [::]:{{ $external_http_port }};
	{{ end }}
	{{ $access_log }}
	return 503;
}

{{ if (and (exists "/etc/nginx/certs/default.crt") (exists "/etc/nginx/certs/default.key")) }}
server {
	server_name _; # This is just an invalid value which will never trigger on a real hostname.
	server_tokens off;
	listen {{ $external_https_port }} ssl http2;
	{{ if $enable_ipv6 }}
	listen [::]:{{ $external_https_port }} ssl http2;
	{{ end }}
	{{ $access_log }}
	return 503;

	ssl_session_cache shared:SSL:50m;
	ssl_session_tickets off;
	ssl_certificate /etc/nginx/certs/default.crt;
	ssl_certificate_key /etc/nginx/certs/default.key;
}
{{ end }}

{{ range $host, $containers := groupByMulti $ "Env.VIRTUAL_HOST" "," }}

{{ $host := trim $host }}
{{ $is_regexp := hasPrefix "~" $host }}
{{ $upstream_name := when (or $is_regexp $sha1_upstream_name) (sha1 $host) $host }}

# {{ $host }}
upstream {{ $upstream_name }} {

{{ $server_found := "false" }}
{{ range $container := $containers }}
	{{ $debug := (eq (coalesce $container.Env.DEBUG $debug_all "false") "true") }}
	{{/* If only 1 port exposed, use that as a default, else 80 */}}
	{{ $defaultPort := (when (eq (len $container.Addresses) 1) (first $container.Addresses) (dict "Port" "80")).Port }}
	{{ $port := (coalesce $container.Env.VIRTUAL_PORT $defaultPort) }}
	{{ $address := where $container.Addresses "Port" $port | first }}
	{{ if $debug }}
	# Exposed ports: {{ $container.Addresses }}
	# Default virtual port: {{ $defaultPort }}
	# VIRTUAL_PORT: {{ $container.Env.VIRTUAL_PORT }}
		{{ if not $address }}
	# /!\ Virtual port not exposed
		{{ end }}
	{{ end }}
	{{ range $knownNetwork := $CurrentContainer.Networks }}
		{{ range $containerNetwork := $container.Networks }}
			{{ if (and (ne $containerNetwork.Name "ingress") (or (eq $knownNetwork.Name $containerNetwork.Name) (eq $knownNetwork.Name "host"))) }}
	## Can be connected with "{{ $containerNetwork.Name }}" network
				{{ if $address }}
					{{/* If we got the containers from swarm and this container's port is published to host, use host IP:PORT */}}
					{{ if and $container.Node.ID $address.HostPort }}
						{{ $server_found = "true" }}
	# {{ $container.Node.Name }}/{{ $container.Name }}
	server {{ $container.Node.Address.IP }}:{{ $address.HostPort }};
					{{/* If there is no swarm node or the port is not published on host, use container's IP:PORT */}}
					{{ else if $containerNetwork }}
						{{ $server_found = "true" }}
	# {{ $container.Name }}
	server {{ $containerNetwork.IP }}:{{ $address.Port }};
					{{ end }}
				{{ else if $containerNetwork }}
	# {{ $container.Name }}
					{{ if $containerNetwork.IP }}
						{{ $server_found = "true" }}
	server {{ $containerNetwork.IP }}:{{ $port }};
					{{ else }}
	# /!\ No IP for this network!
					{{ end }}
				{{ end }}
			{{ else }}
	# Cannot connect to network '{{ $containerNetwork.Name }}' of this container
			{{ end }}
		{{ end }}
	{{ end }}
{{ end }}
{{/* nginx-proxy/nginx-proxy#1105 */}}
{{ if (eq $server_found "false") }}
	# Fallback entry
	server 127.0.0.1 down;
{{ end }}
}

{{ $default_host := or ($.Env.DEFAULT_HOST) "" }}
{{ $default_server := index (dict $host "" $default_host "default_server") $host }}

{{/* Get the VIRTUAL_PROTO defined by containers w/ the same vhost, falling back to "http" */}}
{{ $proto := trim (or (first (groupByKeys $containers "Env.VIRTUAL_PROTO")) "http") }}

{{/* Get the SERVER_TOKENS defined by containers w/ the same vhost, falling back to "" */}}
{{ $server_tokens := trim (or (first (groupByKeys $containers "Env.SERVER_TOKENS")) "") }}

{{/* Get the NETWORK_ACCESS defined by containers w/ the same vhost, falling back to "external" */}}
{{ $network_tag := or (first (groupByKeys $containers "Env.NETWORK_ACCESS")) "external" }}

{{/* Get the HTTPS_METHOD defined by containers w/ the same vhost, falling back to "redirect" */}}
{{ $https_method := or (first (groupByKeys $containers "Env.HTTPS_METHOD")) (or $.Env.HTTPS_METHOD "redirect") }}

{{/* Get the SSL_POLICY defined by containers w/ the same vhost, falling back to empty string (use default) */}}
{{ $ssl_policy := or (first (groupByKeys $containers "Env.SSL_POLICY")) "" }}

{{/* Get the HSTS defined by containers w/ the same vhost, falling back to "max-age=31536000" */}}
{{ $hsts := or (first (groupByKeys $containers "Env.HSTS")) (or $.Env.HSTS "max-age=31536000") }}

{{/* Get the VIRTUAL_ROOT By containers w/ use fastcgi root */}}
{{ $vhost_root := or (first (groupByKeys $containers "Env.VIRTUAL_ROOT")) "/var/www/public" }}


{{/* Get the first cert name defined by containers w/ the same vhost */}}
{{ $certName := (first (groupByKeys $containers "Env.CERT_NAME")) }}

{{/* Get the best matching cert  by name for the vhost. */}}
{{ $vhostCert := (closest (dir "/etc/nginx/certs") (printf "%s.crt" $host))}}

{{/* vhostCert is actually a filename so remove any suffixes since they are added later */}}
{{ $vhostCert := trimSuffix ".crt" $vhostCert }}
{{ $vhostCert := trimSuffix ".key" $vhostCert }}

{{/* Use the cert specified on the container or fallback to the best vhost match */}}
{{ $cert := (coalesce $certName $vhostCert) }}

{{ $is_https := (and (ne $https_method "nohttps") (ne $cert "") (exists (printf "/etc/nginx/certs/%s.crt" $cert)) (exists (printf "/etc/nginx/certs/%s.key" $cert))) }}

{{ if $is_https }}

{{ if eq $https_method "redirect" }}
server {
	server_name {{ $host }};
	{{ if $server_tokens }}
	server_tokens {{ $server_tokens }};
	{{ end }}
	listen {{ $external_http_port }} {{ $default_server }};
	{{ if $enable_ipv6 }}
	listen [::]:{{ $external_http_port }} {{ $default_server }};
	{{ end }}
	{{ $access_log }}
	
	# Do not HTTPS redirect Let'sEncrypt ACME challenge
	location ^~ /.well-known/acme-challenge/ {
		auth_basic off;
		auth_request off;
		allow all;
		root /usr/share/nginx/html;
		try_files $uri =404;
		break;
	}
	
	location / {
		{{ if eq $external_https_port "443" }}
		return 301 https://$host$request_uri;
		{{ else }}
		return 301 https://$host:{{ $external_https_port }}$request_uri;
		{{ end }}
	}
}
{{ end }}

server {
	server_name {{ $host }};
	{{ if $server_tokens }}
	server_tokens {{ $server_tokens }};
	{{ end }}
	listen {{ $external_https_port }} ssl http2 {{ $default_server }};
	{{ if $enable_ipv6 }}
	listen [::]:{{ $external_https_port }} ssl http2 {{ $default_server }};
	{{ end }}
	{{ $access_log }}

	{{ if eq $network_tag "internal" }}
	# Only allow traffic from internal clients
	include /etc/nginx/network_internal.conf;
	{{ end }}

	{{ template "ssl_policy" (dict "ssl_policy" $ssl_policy) }}

	ssl_session_timeout 5m;
	ssl_session_cache shared:SSL:50m;
	ssl_session_tickets off;

	ssl_certificate /etc/nginx/certs/{{ (printf "%s.crt" $cert) }};
	ssl_certificate_key /etc/nginx/certs/{{ (printf "%s.key" $cert) }};

	{{ if (exists (printf "/etc/nginx/certs/%s.dhparam.pem" $cert)) }}
	ssl_dhparam {{ printf "/etc/nginx/certs/%s.dhparam.pem" $cert }};
	{{ end }}

	{{ if (exists (printf "/etc/nginx/certs/%s.chain.pem" $cert)) }}
	ssl_stapling on;
	ssl_stapling_verify on;
	ssl_trusted_certificate {{ printf "/etc/nginx/certs/%s.chain.pem" $cert }};
	{{ end }}

	{{ if (not (or (eq $https_method "noredirect") (eq $hsts "off"))) }}
	add_header Strict-Transport-Security "{{ trim $hsts }}" always;
	{{ end }}

	{{ if (exists (printf "/etc/nginx/vhost.d/%s" $host)) }}
	include {{ printf "/etc/nginx/vhost.d/%s" $host }};
	{{ else if (exists "/etc/nginx/vhost.d/default") }}
	include /etc/nginx/vhost.d/default;
	{{ end }}

	location / {
		{{ if eq $proto "uwsgi" }}
		include uwsgi_params;
		uwsgi_pass {{ trim $proto }}://{{ trim $upstream_name }};
		{{ else if eq $proto "fastcgi" }}
		root   {{ trim $vhost_root }};
		include fastcgi_params;
		fastcgi_pass {{ trim $upstream_name }};
		{{ else if eq $proto "grpc" }}
		grpc_pass {{ trim $proto }}://{{ trim $upstream_name }};
		{{ else }}
		proxy_pass {{ trim $proto }}://{{ trim $upstream_name }};
		{{ end }}

		{{ if (exists (printf "/etc/nginx/htpasswd/%s" $host)) }}
		auth_basic	"Restricted {{ $host }}";
		auth_basic_user_file	{{ (printf "/etc/nginx/htpasswd/%s" $host) }};
		{{ end }}
		{{ if (exists (printf "/etc/nginx/vhost.d/%s_location" $host)) }}
		include {{ printf "/etc/nginx/vhost.d/%s_location" $host}};
		{{ else if (exists "/etc/nginx/vhost.d/default_location") }}
		include /etc/nginx/vhost.d/default_location;
		{{ end }}
	}
}

{{ end }}

{{ if or (not $is_https) (eq $https_method "noredirect") }}

server {
	server_name {{ $host }};
	{{ if $server_tokens }}
	server_tokens {{ $server_tokens }};
	{{ end }}
	listen {{ $external_http_port }} {{ $default_server }};
	{{ if $enable_ipv6 }}
	listen [::]:80 {{ $default_server }};
	{{ end }}
	{{ $access_log }}

	{{ if eq $network_tag "internal" }}
	# Only allow traffic from internal clients
	include /etc/nginx/network_internal.conf;
	{{ end }}

	{{ if (exists (printf "/etc/nginx/vhost.d/%s" $host)) }}
	include {{ printf "/etc/nginx/vhost.d/%s" $host }};
	{{ else if (exists "/etc/nginx/vhost.d/default") }}
	include /etc/nginx/vhost.d/default;
	{{ end }}

	location / {
		{{ if eq $proto "uwsgi" }}
		include uwsgi_params;
		uwsgi_pass {{ trim $proto }}://{{ trim $upstream_name }};
		{{ else if eq $proto "fastcgi" }}
		root   {{ trim $vhost_root }};
		include fastcgi_params;
		fastcgi_pass {{ trim $upstream_name }};
		{{ else if eq $proto "grpc" }}
		grpc_pass {{ trim $proto }}://{{ trim $upstream_name }};
		{{ else }}
		proxy_pass {{ trim $proto }}://{{ trim $upstream_name }};
		{{ end }}
		{{ if (exists (printf "/etc/nginx/htpasswd/%s" $host)) }}
		auth_basic	"Restricted {{ $host }}";
		auth_basic_user_file	{{ (printf "/etc/nginx/htpasswd/%s" $host) }};
		{{ end }}
		{{ if (exists (printf "/etc/nginx/vhost.d/%s_location" $host)) }}
		include {{ printf "/etc/nginx/vhost.d/%s_location" $host}};
		{{ else if (exists "/etc/nginx/vhost.d/default_location") }}
		include /etc/nginx/vhost.d/default_location;
		{{ end }}
	}
}

{{ if (and (not $is_https) (exists "/etc/nginx/certs/default.crt") (exists "/etc/nginx/certs/default.key")) }}
server {
	server_name {{ $host }};
	{{ if $server_tokens }}
	server_tokens {{ $server_tokens }};
	{{ end }}
	listen {{ $external_https_port }} ssl http2 {{ $default_server }};
	{{ if $enable_ipv6 }}
	listen [::]:{{ $external_https_port }} ssl http2 {{ $default_server }};
	{{ end }}
	{{ $access_log }}
	return 500;

	ssl_certificate /etc/nginx/certs/default.crt;
	ssl_certificate_key /etc/nginx/certs/default.key;
}
{{ end }}

{{ end }}
{{ end }}
EOF

echo -e "\e[92mJamStrapper: Writing \e[1m\e[33mCompose File\e[92m\e[0m...\e[39m"
cat <<EOF | tee ./docker-compose.yml
version: "3"

networks:
    nginx-proxy:
        external: true

volumes:
    sys_nginx_certs:
    sys_nginx_conf:
    sys_nginx_vhost:
    sys_nginx_html:
    sys_nginx_dhparam:
    sys_ssl_acme:
    sys_docker_portainer:
    sys_gitlab_config:
    sys_gitlab_logs:
    sys_gitlab_data:

services:
    nginx-proxy-container:
        image: nginxproxy/nginx-proxy
        container_name: nginx-proxy-container
        ports:
            - "80:80"
            - "443:443"
        restart: always
        volumes:
            - sys_nginx_conf:/etc/nginx/conf.d
            - sys_nginx_vhost:/etc/nginx/vhost.d
            - sys_nginx_html:/usr/share/nginx/html
            - sys_nginx_dhparam:/etc/nginx/dhparam
            - sys_nginx_certs:/etc/nginx/certs:ro
            - /var/run/docker.sock:/tmp/docker.sock:ro
        networks:
            - nginx-proxy

    nginx-proxy-gen:
        image: nginxproxy/docker-gen
        container_name: nginx-proxy-gen
        command: -notify-sighup nginx-proxy -watch /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
        volumes:
            - /data/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro
            - /var/run/docker.sock:/tmp/docker.sock:ro
            - sys_nginx_certs:/etc/nginx/certs
            - sys_nginx_conf:/etc/nginx/conf.d
        networks:
            - nginx-proxy

    nginx-proxy-acme:
        image: nginxproxy/acme-companion
        container_name: nginx-proxy-acme
        restart: always
        environment:
            NGINX_PROXY_CONTAINER: nginx-proxy
            NGINX_DOCKER_GEN_CONTAINER: nginx-proxy-gen
        volumes:
            - sys_nginx_certs:/etc/nginx/certs:rw
            - sys_ssl_acme:/etc/acme.sh
            - sys_nginx_vhost:/etc/nginx/vhost.d:rw
            - sys_nginx_html:/usr/share/nginx/html:rw
            - sys_nginx_dhparam:/etc/nginx/dhparam:rw
            - /var/run/docker.sock:/var/run/docker.sock:ro
        networks:
            - nginx-proxy

    portainer:
        image: portainer/portainer-ce
        container_name: portainer
        ports:
            - "8000:8000"
            - "42069:9000"
        restart: always
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - sys_docker_portainer:/data

    gitlab:
        image: 'gitlab/gitlab-ce:latest'
        container_name: gitlab
        restart: always
        hostname: '${GIT_SERVER_DOMAIN}'
        environment:
            VIRTUAL_HOST: ${GIT_SERVER_DOMAIN}
            LETSENCRYPT_HOST: ${GIT_SERVER_DOMAIN}
            GITLAB_OMNIBUS_CONFIG: |
                external_url 'https://${GIT_SERVER_DOMAIN}'
                gitlab_rails['gitlab_shell_ssh_port'] = 1152
                registry_external_url 'https://${GIT_SERVER_DOMAIN}:5050'
                registry_nginx['ssl_certificate'] = "/etc/nginx/certs/${GIT_SERVER_DOMAIN}/fullchain.pem"
                registry_nginx['ssl_certificate_key'] = "/etc/nginx/certs/${GIT_SERVER_DOMAIN}/key.pem"
                letsencrypt['enable'] = false
                nginx['ssl_certificate'] = "/etc/nginx/certs/${GIT_SERVER_DOMAIN}/fullchain.pem"
                nginx['ssl_certificate_key'] = "/etc/nginx/certs/${GIT_SERVER_DOMAIN}/key.pem"
                nginx['listen_port'] = 80
                nginx['listen_https'] = false
        expose:
            - "80"
        ports:
            - "1152:22"
        volumes:
            - sys_nginx_certs:/etc/nginx/certs:ro
            - sys_gitlab_config:/etc/gitlab
            - sys_gitlab_logs:/var/log/gitlab
            - sys_gitlab_data:/var/opt/gitlab
        networks:
            - nginx-proxy
EOF

echo -e "\e[92mJamStrapper: Starting \e[1m\e[33mSystem Containers\e[92m\e[0m...\e[39m"
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

echo -e "\e[92mJamStrapper: Running \e[1m\e[33mRunner Register\e[92m\e[0m now..."
echo -e "If you want to do this later you can abort the setup at this point with \e[33mCTRL+C\e[39m"
gitlab-runner register

