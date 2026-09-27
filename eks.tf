resource "aws_eks_cluster" "pathnex" {
  name     = "Pathnex-Sep-2026"
  role_arn = "arn:aws:iam::174132708859:role/AmazonEKSClusterRole"
  version  = "1.34"

  upgrade_policy {
    support_type = "STANDARD"
  }

  vpc_config {
    subnet_ids = [
      "subnet-095c754c9a7d7b2b4",
      "subnet-023ef84fb12426b62",
      "subnet-04bef87cc676fb109"
    ]

    security_group_ids = [
      "sg-0680ef70a519ab38c"
    ]

    endpoint_public_access  = true
    endpoint_private_access = true

    public_access_cidrs = [
      "0.0.0.0/0"
    ]
  }
  zonal_shift_config {
         enabled = false
        }
}
