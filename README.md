# Example of Simple AWS Simple SNAT

This example shows the following things:

- Create a VPC and subnets using `vpc` module.
- Create a NAT instance using this module.
- Create an instance in the private subnet.
- Add terraform-key.pem to the both instances.

## Getting Started

Prerequisite: Generate key pair terraform-key in Tokyo - ap-northeast-1 through AWS Console, and replace terraform-key.pem with downloaded one.

Provision the stack.

```console
% terraform init
% terraform apply
...

Outputs:

nat_public_ip = 35.73.142.227
private_instance_id = i-01acdcda755b6736c
```

Test One - Verify the IP being exposed to internet is Nat instance's EIP only, and curl checkip.amazonaws.com to get the EIP via https only.

Make sure you have access to the instance in the private subnet.

```console
% aws ssm start-session --region ap-northeast-1 --target i-01acdcda755b6736c
```

```console
% curl https://checkip.amazonaws.com
35.73.142.227
% curl http://checkip.amazonaws.com
curl: (7) Failed to connect to checkip.amazonaws.com port 80 after 2053 ms: Connection refused
```

Test Two - Verify The Nat instance plays role of bastion server
In your desktop, try below command to see if the nat public ip is sshable
```console
% ssh -i terraform-key.pem 35.73.142.227
```

```console
% cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost6 localhost6.localdomain6
172.18.75.185 example-terraform-aws-nat-instance
```
Once enter the Nat instance, try below ssh to see if the private ip is sshable
```console
% ssh -i /tmp/terraform-key.pem ec2-user@example-terraform-aws-nat-instance
```
Check the ip of the Private instance. and confirm it only leverages internal ip and not routable via internet 
```console
% ifconfig
```



You can completely destroy the stack.

```console
% terraform destroy
```
