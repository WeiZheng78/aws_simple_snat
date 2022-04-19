provider "aws" {
  region = "ap-northeast-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "example"
  cidr                 = "172.18.0.0/16"
  azs                  = ["ap-northeast-1a"]
  private_subnets      = ["172.18.64.0/20"]
  public_subnets       = ["172.18.128.0/20"]
  enable_dns_hostnames = true
}

module "nat" {
  source = "int128/nat-instance/aws"

  name                        = "example"
  vpc_id                      = module.vpc.vpc_id
  public_subnet               = module.vpc.public_subnets[0]
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = module.vpc.private_route_table_ids
  key_name                    = "terraform-key"

  # enable port forwarding (optional)
  user_data_write_files = [
    {
      path : "/opt/nat/forward.sh",
      content : templatefile("./forward.sh", { ec2_name = "example-terraform-aws-nat-instance" }),
      permissions : "0755",
    },
    {
      path: "/tmp/terraform-key.pem",
      content: file("./terraform-key.pem"),
    },
  ]
  user_data_runcmd = [
    ["yum", "install", "-y", "jq"],
    ["/opt/nat/forward.sh"],
  ]
  instance_types = [
    "t2.micro"
  ]
}

resource "aws_eip" "nat" {
  network_interface = module.nat.eni_id
  tags = {
    "Name" = "nat-instance-example"
  }
}

# IAM policy for port forwarding (optional)
resource "aws_iam_role_policy" "snat_service" {
  role   = module.nat.iam_role_name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_security_group_rule" "nat_ssh" {
  security_group_id = module.nat.sg_id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}
