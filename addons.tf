resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.63.1-eksbuild.1"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi,
    aws_eks_cluster.pathnex,
    aws_eks_addon.pod_identity,
    helm_release.cluster_autoscaler
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "coredns"
  addon_version = "v1.13.2-eksbuild.1"
  depends_on = [aws_eks_cluster.pathnex,
    helm_release.cluster_autoscaler
  ]
}

resource "aws_eks_addon" "node_monitoring" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "eks-node-monitoring-agent"
  addon_version = "v1.7.0-eksbuild.1"
  depends_on = [aws_eks_cluster.pathnex,
  helm_release.cluster_autoscaler]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.3"
  depends_on    = [aws_eks_cluster.pathnex]
}

resource "aws_eks_addon" "external_dns" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "external-dns"
  addon_version = "v0.21.0-eksbuild.6"
  depends_on = [aws_eks_cluster.pathnex,
  helm_release.cluster_autoscaler]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "kube-proxy"
  addon_version = "v1.34.3-eksbuild.2"
  depends_on = [aws_eks_cluster.pathnex,
  helm_release.cluster_autoscaler]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "metrics-server"
  addon_version = "v0.9.0-eksbuild.5"
  depends_on = [aws_eks_cluster.pathnex,
  helm_release.cluster_autoscaler]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.pathnex.name
  addon_name    = "vpc-cni"
  addon_version = "v1.22.4-eksbuild.3"
  depends_on = [aws_eks_cluster.pathnex,
  helm_release.cluster_autoscaler]
}

resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.21.0"

  namespace        = "keda"
  create_namespace = true

  depends_on = [
    aws_eks_cluster.pathnex,
    aws_eks_addon.pod_identity
  ]
}



resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "base"
  version    = "1.31.0"

  namespace        = "istio-system"
  create_namespace = true

  depends_on = [
    aws_eks_cluster.pathnex
  ]
}



resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "istiod"
  version    = "1.31.0"

  namespace = "istio-system"

  depends_on = [
    helm_release.istio_base
  ]
}



resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "gateway"
  version    = "1.31.0"

  namespace        = "istio-ingress"
  create_namespace = true

  depends_on = [
    helm_release.istiod
  ]
}



data "aws_caller_identity" "karpenter" {}
data "aws_partition" "karpenter" {}

resource "aws_iam_role" "karpenter" {
  name = "${aws_eks_cluster.pathnex.name}-KarpenterController"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = {
        StringEquals = {
          "aws:RequestTag/eks-cluster-name"           = aws_eks_cluster.pathnex.name
          "aws:RequestTag/kubernetes-namespace"       = "karpenter"
          "aws:RequestTag/kubernetes-service-account" = "karpenter"
        }
      }
    }]
  })
}

# Based on the upstream v1.6.0 getting-started CloudFormation controller policy.
# Interruption queue permissions are omitted because no queue is configured.
# PassRole is limited to the existing EKS node role; use it in EC2NodeClass.spec.role.
resource "aws_iam_policy" "karpenter" {
  name = "${aws_eks_cluster.pathnex.name}-KarpenterController"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowScopedEC2InstanceAccessActions",
        "Effect" : "Allow",
        "Resource" : [
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}::image/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}::snapshot/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:security-group/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:subnet/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:capacity-reservation/*"
        ],
        "Action" : [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
      },
      {
        "Sid" : "AllowScopedEC2LaunchTemplateAccessActions",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:launch-template/*",
        "Action" : [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedEC2InstanceActionsWithTags",
        "Effect" : "Allow",
        "Resource" : [
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:fleet/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:instance/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:volume/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:network-interface/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:launch-template/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:spot-instances-request/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:capacity-reservation/*"
        ],
        "Action" : [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned",
            "aws:RequestTag/eks:eks-cluster-name" : "${aws_eks_cluster.pathnex.name}"
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedResourceCreationTagging",
        "Effect" : "Allow",
        "Resource" : [
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:fleet/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:instance/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:volume/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:network-interface/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:launch-template/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:spot-instances-request/*"
        ],
        "Action" : "ec2:CreateTags",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned",
            "aws:RequestTag/eks:eks-cluster-name" : "${aws_eks_cluster.pathnex.name}",
            "ec2:CreateAction" : [
              "RunInstances",
              "CreateFleet",
              "CreateLaunchTemplate"
            ]
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedResourceTagging",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:instance/*",
        "Action" : "ec2:CreateTags",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.sh/nodepool" : "*"
          },
          "StringEqualsIfExists" : {
            "aws:RequestTag/eks:eks-cluster-name" : "${aws_eks_cluster.pathnex.name}"
          },
          "ForAllValues:StringEquals" : {
            "aws:TagKeys" : [
              "eks:eks-cluster-name",
              "karpenter.sh/nodeclaim",
              "Name"
            ]
          }
        }
      },
      {
        "Sid" : "AllowScopedDeletion",
        "Effect" : "Allow",
        "Resource" : [
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:instance/*",
          "arn:${data.aws_partition.karpenter.partition}:ec2:${var.aws_region}:*:launch-template/*"
        ],
        "Action" : [
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid" : "AllowRegionalReadActions",
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : [
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestedRegion" : "${var.aws_region}"
          }
        }
      },
      {
        "Sid" : "AllowSSMReadActions",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:ssm:${var.aws_region}::parameter/aws/service/*",
        "Action" : "ssm:GetParameter"
      },
      {
        "Sid" : "AllowPricingReadActions",
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : "pricing:GetProducts"
      },
      {
        "Sid" : "AllowPassingInstanceRole",
        "Effect" : "Allow",
        "Resource" : "${aws_eks_node_group.pathnex-NG.node_role_arn}",
        "Action" : "iam:PassRole",
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileCreationActions",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:iam::${data.aws_caller_identity.karpenter.account_id}:instance-profile/*",
        "Action" : [
          "iam:CreateInstanceProfile"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned",
            "aws:RequestTag/eks:eks-cluster-name" : "${aws_eks_cluster.pathnex.name}",
            "aws:RequestTag/topology.kubernetes.io/region" : "${var.aws_region}"
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileTagActions",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:iam::${data.aws_caller_identity.karpenter.account_id}:instance-profile/*",
        "Action" : [
          "iam:TagInstanceProfile"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "${var.aws_region}",
            "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned",
            "aws:RequestTag/eks:eks-cluster-name" : "${aws_eks_cluster.pathnex.name}",
            "aws:RequestTag/topology.kubernetes.io/region" : "${var.aws_region}"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileActions",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:iam::${data.aws_caller_identity.karpenter.account_id}:instance-profile/*",
        "Action" : [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.pathnex.name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "${var.aws_region}"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowInstanceProfileReadActions",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:iam::${data.aws_caller_identity.karpenter.account_id}:instance-profile/*",
        "Action" : "iam:GetInstanceProfile"
      },
      {
        "Sid" : "AllowAPIServerEndpointDiscovery",
        "Effect" : "Allow",
        "Resource" : "arn:${data.aws_partition.karpenter.partition}:eks:${var.aws_region}:${data.aws_caller_identity.karpenter.account_id}:cluster/${aws_eks_cluster.pathnex.name}",
        "Action" : "eks:DescribeCluster"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  role       = aws_iam_role.karpenter.name
  policy_arn = aws_iam_policy.karpenter.arn
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = aws_eks_cluster.pathnex.name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter.arn

  depends_on = [
    aws_eks_addon.pod_identity,
    aws_iam_role_policy_attachment.karpenter
  ]
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "karpenter"
  create_namespace = true

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"

  version = "1.6.0"

  # Avoid relying on EC2 instance metadata for region discovery from the pod.
  values = [yamlencode({
    serviceAccount = {
      name = "karpenter"
    }
    # Recreate existing pods after associating their service account with IAM.
    podAnnotations = {
      "pathnex.io/pod-identity-association" = aws_eks_pod_identity_association.karpenter.association_id
    }
    controller = {
      env = [{
        name  = "AWS_REGION"
        value = var.aws_region
      }]
    }
  })]

  set = [
    {
      name  = "settings.clusterName"
      value = aws_eks_cluster.pathnex.name
    }
  ]

  depends_on = [
    aws_eks_cluster.pathnex,
    aws_eks_addon.pod_identity
  ]
}
