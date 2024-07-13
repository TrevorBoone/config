#!/bin/bash

####
# technically this script is intended to be idempotent so it can be run multiple times
# no guarantees though that any of this works (mostly should be pretty obvious whether ssh
# works in general or not but shoud put some extra effor to make sure Password authentication
# is really disabled so as not to leave that open to people getting in).
####

cd "$(dirname "$0")"

## add public key to authorized keys
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
grep -q -f trevor_id_rsa.pub ~/.ssh/authorized_keys
if [[ $? -ne 0 ]]
then
    echo "adding key to authorized keys"
    cat trevor_id_rsa.pub >> ~/.ssh/authorized_keys
else
    echo "key already exists in authorized keys"
fi

## disable password authentication

# not the easiest to maintain...
start_regexp='^[\t ]*#?[\t ]*'
keyword_target='PasswordAuthentication'
yes_no='[\t ]*([Yy][Ee][Ss]|[Nn][Oo])[\t ]*'
ending='[\t ]*(#.*)?$'

target=$start_regexp$keyword_target$yes_no$ending
# even if it's already disabled just overwrite it to keep it simple.
sudo grep -q -E "$target" /etc/ssh/sshd_config
    if [ $? -eq 0 ]
    then
        echo "changed to PasswordAuthentication no"
        sudo sed -i -E "s/$target/PasswordAuthentication no/" /etc/ssh/sshd_config
    else
        echo "added PasswordAuthentication no"
        echo "" >> /etc/ssh/sshd_config
        echo "# disabling password ssh" >> /etc/ssh/sshd_config
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi

## set ssh to run on startup and restart it to pick up new configuration
echo "setting ssh to run on startup and restarting to pick up config changes"
sudo systemctl restart ssh
sudo systemctl enable ssh