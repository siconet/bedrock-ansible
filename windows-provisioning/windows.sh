#!/usr/bin/env bash
#
# Windows provisioner for bedrock-ansible

ANSIBLE_PLAYBOOK=site_windows.yml
ANSIBLE_HOSTS=hosts/development
TEMP_HOSTS="/tmp/ansible_hosts"

if [ ! -f /vagrant/$ANSIBLE_HOSTS ]; then
  echo "Ansible hosts not found."
  exit 2
fi

if [ $(dpkg-query -W -f='${Status}' ansible 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    echo "Add APT repositories"
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -qq software-properties-common &> /dev/null || exit 1
    apt-add-repository ppa:ansible/ansible &> /dev/null || exit 1

    apt-get update -qq

    echo "Installing Ansible"
    apt-get install -qq ansible &> /dev/null || exit 1
    echo "Ansible installed"
fi

cp /vagrant/${ANSIBLE_HOSTS} ${TEMP_HOSTS} && chmod -x ${TEMP_HOSTS}

cd /vagrant
echo "Running Ansible provisioner defined in Vagrantfile..."
ansible-playbook ${ANSIBLE_PLAYBOOK} --inventory-file=${TEMP_HOSTS} --sudo --user=vagrant --extra-vars "default_ssh_user=vagrant is_windows=true" --connection=local -vvvv