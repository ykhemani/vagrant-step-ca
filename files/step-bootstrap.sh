#!/bin/bash

# This script updates the OS and installs the packes listed below.

sleep 30
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
  gnupg \
  openssl \
  jq \
  unzip \
  htop \
  avahi-daemon \
  libnss-mdns

step_version=${step_version:-0.15.7}
step_ca_version=${step_ca_version:-0.15.8}

src_dir=${src_dir:-/data/src}
install_dir=${install_dir:-/usr/local/bin}
step_homedir=${step_homedir:-/etc/step-ca}
step_user=${step_user:-step}

# step ca init parameters
password_length=${password_length:-32}
provisioner=${provisioner:-root@ca.local}
step_ca_name=${step_ca_name:-HashiCafe_CA}

#step_url=${step_url:-https://github.com/smallstep/cli/releases/download/v0.15.7/step_linux_0.15.7_amd64.tar.gz}
#step_ca_url=${step_ca_url:-https://github.com/smallstep/certificates/releases/download/v0.15.8/step-certificates_linux_0.15.8_amd64.tar.gz}

step_url="https://github.com/smallstep/cli/releases/download/v${step_version}/step_linux_${step_version}_amd64.tar.gz"

step_ca_url="https://github.com/smallstep/certificates/releases/download/v${step_ca_version}/step-certificates_linux_${step_ca_version}_amd64.tar.gz"

#step_ca_systemd_url=${step_ca_systemd_url:-https://raw.githubusercontent.com/smallstep/certificates/master/systemd/step-ca.service}

step_ca_systemd=${step_ca_systemd:-/etc/systemd/system/step-ca.service}

password_url=${password_url:-https://github.com/ykhemani/password/releases/download/v0.1/password-linux-amd64.zip}

mkdir -p ${src_dir}

cd ${src_dir}

curl \
  --silent \
  --location \
  ${step_url} \
  --output step_linux_${step_version}_amd64.tar.gz

curl \
  --silent \
  --location \
  ${step_ca_url} \
  --output step-certificates_linux_${step_ca_version}_amd64.tar.gz

#curl \
#  --silent \
#  --location \
#  ${step_ca_systemd_url} \
#  --output step-ca.service

curl \
  --silent \
  --location \
  ${password_url} \
  --output password-linux-amd64.zip

tar xvfz step_linux_${step_version}_amd64.tar.gz
tar xvfz step-certificates_linux_${step_ca_version}_amd64.tar.gz

unzip -q -d ${install_dir} password-linux-amd64.zip

cp step-certificates_${step_ca_version}/bin/step-ca ${install_dir}
cp step_${step_version}/bin/step ${install_dir}
#cp step-ca.service ${step_ca_systemd}

cat << EOF > ${step_ca_systemd}
[Unit]
Description=step-ca service
Documentation=https://smallstep.com/docs/step-ca
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=30
StartLimitBurst=3
ConditionFileNotEmpty=${step_homedir}/config/ca.json
ConditionFileNotEmpty=${step_homedir}/password.txt

[Service]
Type=simple
User=${step_user}
Group=${step_user}
Environment=STEPPATH=${step_homedir}
WorkingDirectory=${step_homedir}
ExecStart=${install_dir}/step-ca ${step_homedir}/config/ca.json --password-file ${step_homedir}/password.txt
ExecReload=/bin/kill --signal HUP \$MAINPID
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=30
StartLimitBurst=3

AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
SecureBits=keep-caps
NoNewPrivileges=yes

ReadWriteDirectories=${step_homedir}/db

[Install]
WantedBy=multi-user.target
EOF

useradd \
  --system \
  --home ${step_homedir} \
  --shell /bin/false \
  ${step_user}

setcap CAP_NET_BIND_SERVICE=+eip ${install_dir}/step-ca

mkdir -p ${step_homedir}/db

${install_dir}/password \
  -length ${password_length} \
  -allow_repeat true \
  > ${step_homedir}/password.txt

chmod 0640 ${step_homedir}/password.txt

export STEPPATH=${step_homedir}

chown -R ${step_user}:${step_user} ${step_homedir}

su \
  -l ${step_user} \
  -s /bin/bash \
  -c "STEPPATH=${step_homedir} \
        ${install_dir}/step ca \
          init \
          --name '${step_ca_name}' \
          --password-file password.txt \
          --dns ca.local,${ip},127.0.0.1 \
          --address :443 \
          --provisioner ${provisioner}"

systemctl daemon-reload
systemctl enable --now step-ca
