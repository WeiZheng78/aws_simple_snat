#!/bin/bash -x

iptables -A FORWARD -s 172.18.64.0/20 -p tcp ! --dport 443 -j REJECT

region="$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')"
eth1_addr="$(ip -f inet -o addr show dev eth1 | cut -d' ' -f 7 | cut -d/ -f 1)"

function get_instance_private_ip_by_name() {
  local name="$1"
  aws ec2 describe-instances \
    --region "$region" \
    --filters "Name=tag:Name,Values=$name" "Name=instance-state-name,Values=running" |
    jq -r .Reservations[0].Instances[0].PrivateIpAddress
}


function add_private_host(){
  echo "$(get_instance_private_ip_by_name ${ec2_name}) ${ec2_name}" >> /etc/hosts
}

add_private_host

