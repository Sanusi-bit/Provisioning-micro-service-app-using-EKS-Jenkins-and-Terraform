#Setting up K8s cluster
#VPC

data "aws_iam_user" "user" {
    user_name = "Altschool-project"
}


module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name = local.name
  cluster_endpoint_public_access = true
  cluster_version = "1.24"
  
  cluster_addons = {
    coredns= {
        most_recent=true

        timeouts= {
            create="10m"
            delete="10m"
        }
    }
    kube-proxy={
        most_recent=true
    }
    vpc-cni ={
        most_recent=true
    }
  }

  #Encryption
  create_kms_key = false
  cluster_encryption_config = {
    resources= ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports={
        description = "Allow communication of nodes"
        from_port = 1025
        to_port = 65535
        protocol = "tcp"
        type = "ingress"
        security_node_security_group = true
        source_security_group_id = aws_security_group.sanusibit-sg.id
    }

    ingress_nodes_ephemeral_ports_tcp = {
        description = "Allow communication of nodes"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        type = "ingress"
        source_security_group_id = aws_security_group.sanusibit-sg.id  
    }
  }

  #Extending node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
        description = "node to node all ports and protocols"
        protocol = "-1"
        from_port = 0
        to_port = 0
        type = "ingress"
        self = true
    }

    ingress_source_security_group = {
        description = "Allow ingress from other computed security group"
        protocol = "tcp"
        from_port = 22
        to_port = 22
        type = "ingress"
        source_security_group_id = aws_security_group.sanusibit-sg.id
    }
  }

#Creating Nodes in EKS Cluster
  eks_managed_node_groups = {
    node1 = {
        min_size = 1
        max_size = 6
        desired_size = 5
        instance_types = ["t3.medium"]
        dsik_size = 20
    }

    node2 = {
        min_size = 1
        max_size = 5
        desired_size = 4
        instance_types = ["t2.medium"]
        dsik_size = 20
        labels = {
            Environment = "test"
        }
        taints = {
            deidcation = {
                key = "dedicated"
                value = "gpuGroup"
                effect = "NO_SCHEDULE"
            }
        }
    }
  }

  manage_aws_auth_configmap =  true

  /*aws_auth_node_iam_role_arns_non_windows = [
    module.eks.eks_managed_node_groups.iam_role_arn,
  ]*/

  aws_auth_roles = [
    {
        #rolearn = module.eks.eks_managed_node_groups.iam_role_arn
        username = "system:node{{EC2PrivateDNSName}}"
        groups = [
            "system:bootstrappers",
            "systeemnodes"
        ]
    },
  ]

  aws_auth_users = [
    {
        userarn = data.aws_iam_user.user.arn
        username = data.aws_iam_user.user.user_name
        groups = [
            "system:masters"
        ]
    }
  ]

  aws_auth_accounts = [
    {
        account_id = data.aws_caller_identity.current.account_id
        role_name = "admin"
    }
  ]

}

#VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs = local.azs
  private_subnets = [for k, v in local.azs: cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets = [for k, v in local.azs: cidrsubnet(local.vpc_cidr, 8, k+48)]
  intra_subnets = [for k, v in local.azs: cidrsubnet(local.vpc_cidr, 8, k+52)]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames =    true

  enable_flow_log = false

  tags = {
    "kubernetes.io/cluster/sanusibit-eks-cluster" = "shared"
  }
  
  public_subnet_tags = {
    "kubernetes.io/cluster/sanusibit-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/sanusibit-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_security_group" "sanusibit-sg" {
  name_prefix = "sanusibit-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
        "10.0.0.0/8",
        "172.16.0.0/21",
        "192.168.0.0/16"
    ]
  }
}

resource "aws_iam_policy" "sanusibit" {
  name = "${local.name}-sanusibit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = [
                "ec2:Describe*",
            ]
            Effect = "Allow"
            Resource = "*"
        },
    ]
  })
}

resource "aws_iam_policy" "worker_policy" {
  name        = "worker-policy"
  description = "Worker policy for the ALB Ingress"

  policy = file("iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.worker_policy.arn
  role       = each.value.iam_role_name

}


module "kms" {
  source = "terraform-aws-modules/kms/aws"
  version = "1.5.0"

  aliases = ["eks/${local.name}"]
  description = "KMS Key for EKS Cluster"
  key_owners = [data.aws_caller_identity.current.arn]
  enable_default_policy = true
}
