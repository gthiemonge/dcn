#!/usr/bin/env bash

CIFMW=~/src/github.com/openstack-k8s-operators/ci-framework/

if [ "$#" -lt 2 ]; then
    echo "USAGE: $0 <NUM> <CEPH-OVERRIDE-FILE>"
    echo "<NUM> should be 100 for az0, 103 for az1, or 106 for az2"
    echo "      Assume compute-0's IP ends in 100, compute-3's IP ends in 103, ..."
    echo "<CEPH-OVERRIDE-FILE> should match ceph_az*.yaml"
    exit 1
fi

START=$1

pushd $CIFMW

export N=2
echo -e "localhost ansible_connection=local\n[computes]" > inventory.yml
for I in $(seq $START $((N+$START))); do
    echo compute-$((I-100)) ansible_host=192.168.122.${I} ansible_ssh_private_key_file=/home/zuul/.ssh/id_cifw >> inventory.yml
done
export ANSIBLE_REMOTE_USER=zuul
export ANSIBLE_SSH_PRIVATE_KEY=~/.ssh/id_cifw
export ANSIBLE_HOST_KEY_CHECKING=False

ansible -i inventory.yml -m ping computes
if [ $? -gt 0 ]; then
    echo "inventory problem"
    exit 1
fi
ln -fs ~/dcn/extra/ceph.yaml
ln -fs ~/dcn/extra/$2
# hci.yml must be copied from custom/hci.yaml of ci-framework
ln -fs ~/hci.yaml
ANSIBLE_GATHERING=implicit ansible-playbook playbooks/ceph.yml -e @hci.yaml -e @ceph.yaml -e @$2
popd
