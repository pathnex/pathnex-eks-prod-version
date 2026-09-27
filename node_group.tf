resource "aws_eks_node_group" "pathnex-NG" {
  cluster_name    = aws_eks_cluster.pathnex.name
  node_group_name = "pathnex-ng"

  node_role_arn = "arn:aws:iam::174132708859:role/AmazonEKSNodeRole"

  subnet_ids = [
    "subnet-095c754c9a7d7b2b4",
    "subnet-023ef84fb12426b62",
    "subnet-04bef87cc676fb109"
  ]

  version        = "1.34"
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "SPOT"
  instance_types = ["c7i-flex.large"]
  disk_size      = 20

  scaling_config {
    desired_size = 3
    min_size     = 1
    max_size     = 5
  }

  tags = {
  "k8s.io/cluster-autoscaler/enabled"          = "true"
  "k8s.io/cluster-autoscaler/Pathnex-Sep-2026" = "owned"
  }
  
  lifecycle {
  ignore_changes = [
    scaling_config[0].desired_size
  ]
  }



  update_config {
    max_unavailable = 1
    update_strategy = "DEFAULT"
  }

  remote_access {
    ec2_ssh_key = "Pathnex.pem"

    source_security_group_ids = [
      "sg-0680ef70a519ab38c"
    ]
  }
}
