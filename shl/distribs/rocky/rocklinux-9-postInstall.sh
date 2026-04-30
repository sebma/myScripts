#!/usr/bin/env bash

nvidiaDriverVersion=580-open

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

$sudo localectl set-x11-keymap fr pc105 latin9
localectl set-locale LANG=en_US.UTF-8
$sudo localectl set-locale LANG=en_US.UTF-8
[ -e $HOME/.Xauthority ] || touch $HOME/.Xauthority

$sudo dnf install chrony -y
grep server /etc/chrony.conf -w -q || echo 'server DC01.domain.lan iburst' | sudo tee -a /etc/chrony.conf
$sudo systemctl restart chronyd.service
$sudo timedatectl set-local-rtc 0
timedatectl status | grep Time.zone:.Europe/Paris -q || $sudo timedatectl set-timezone Europe/Paris

#Creation du swap
swapSize=32.6GiB # car / trop petit pour le moment
dataDir=/data
swapFilePath=$dataDir/swapfile
if [ ! -e $swapFilePath ];then
	$sudo mkdir -p $dataDir
	$sudo fallocate -l $swapSize $swapFilePath
	$sudo chmod 0600 $swapFilePath
	$sudo mkswap $swapFilePath
	$sudo swapon $swapFilePath
	grep $swapFilePath /etc/fstab -q || echo "$swapFilePath none swap sw 0 0" | $sudo tee -a /etc/fstab
	$sudo systemctl daemon-reload
fi

$sudo dnf install realmd krb5-workstation -y
realm list
#$sudo realm join -U T2-USER domain.LAN
$sudo grep %admin_linux /etc/sudoers.d/t2admin -q || printf "%%admin_linux ALL=(ALL) ALL" | $sudo tee -a /etc/sudoers.d/t2admin

$sudo mkdir -p /var/log/journal # Pour que la log de systemd-journald ne soit pas volatile
lspci -nnd ::0300
$sudo update-pciids -q
lspci -nnd ::0300
[ -d /sys/firmware/efi ] && echo 'Session EFI' || echo 'Session non-EFI'
mokutil --sb-state | grep SecureBoot

dnf repolist | grep epel -w -q || $sudo dnf install epel-release -y
# Pour gerer l'entropy
# Avant l'install de "haveged"
sysctl kernel.random.entropy_avail
cat /proc/sys/kernel/random/entropy_avail
$sudo dnf install haveged -y
$sudo systemctl enable --now haveged.service
# Apres l'install de "haveged"
sysctl kernel.random.entropy_avail
cat /proc/sys/kernel/random/entropy_avail

$sudo dnf install dnf-plugins-core -y
dnf repolist | grep crb -w -q || $sudo dnf config-manager --set-enabled crb
dnf repolist | grep docker-ce -q || $sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

rhelMajorVersion=$(source /etc/os-release;echo ${VERSION_ID/.*})
dnf repolist | grep cuda-rhel -q || $sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel$rhelMajorVersion/$(uname -i)/cuda-rhel$rhelMajorVersion.repo

dnf clean expire-cache
if dnf module list nvidia-driver | grep $nvidiaDriverVersion -q;then
	$sudo dnf clean expire-cache
	$sudo dnf module enable nvidia-driver:$nvidiaDriverVersion -y
	$sudo dnf install nvidia-open kmod-nvidia-open-dkms nvidia-driver-cuda -y --allowerasing
	$sudo dnf install docker-ce docker-compose-plugin -y
	$sudo systemctl enable --now docker.service
	$sudo dnf install nvidia-container-toolkit -y
	$sudo systemctl restart docker.service
else
	echo "=> There is no $nvidiaDriverVersion available in the nvidia-driver DNF modules list." >&2
	exit 2
fi

if ! grep -r vm.max_map_count /etc/sysctl.conf /etc/sysctl.d/ -q 2>/dev/null;then
	echo "vm.max_map_count = $((2**18))" | $sudo tee -a /etc/sysctl.d/98-comfyui.conf >/dev/null
	$sudo systemctl restart systemd-sysctl.service
	sysctl vm.max_map_count
	cat /proc/sys/vm/max_map_count
fi

$sudo sed -i.bak -r '/#\s*greeter-show-manual-login\s*=\s*\w+$/s/^.*$/greeter-show-manual-login = true/' /etc/lightdm/lightdm.conf
$sudo systemctl restart lightdm.service

which nvidia-smi &>/dev/null && dnf module list nvidia-driver | grep -F '[e]'

dnf repolist | grep puppet -q || $sudo dnf install https://yum.puppet.com/puppet-release-el-$rhelMajorVersion.noarch.rpm -y
rpm -q puppet-agent || $sudo dnf install puppet-agent -y
#$sudo systemctl enable --now puppet.service # car va contacter https://puppet:8140 par default
puppet=$(find /opt/puppetlabs/ -type l -name puppet -executable | grep bin/ -m1)
$puppet agent -h
echo "=> $puppet agent -t" # Attention ca va contacter https://puppet:8140 par default
