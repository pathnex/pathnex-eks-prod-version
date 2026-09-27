#import {
#  to = aws_eks_cluster.pathnex
#  id = "Pathnex"
#}
#
#import {
#  to = aws_eks_node_group.pathnex
#  id = "Pathnex:pathnex-ng"
#}
#
#import {
#  to = aws_eks_addon.ebs_csi
#  id = "Pathnex:aws-ebs-csi-driver"
#}
#
#import {
#  to = aws_eks_addon.coredns
#  id = "Pathnex:coredns"
#}
#
#import {
#  to = aws_eks_addon.node_monitoring
#  id = "Pathnex:eks-node-monitoring-agent"
#}
#
#import {
#  to = aws_eks_addon.pod_identity
#  id = "Pathnex:eks-pod-identity-agent"
#}
#
#import {
#  to = aws_eks_addon.external_dns
#  id = "Pathnex:external-dns"
#}
#
#import {
#  to = aws_eks_addon.kube_proxy
#  id = "Pathnex:kube-proxy"
#}
#
#import {
#  to = aws_eks_addon.metrics_server
#  id = "Pathnex:metrics-server"
#}
#
#import {
#  to = aws_eks_addon.vpc_cni
#  id = "Pathnex:vpc-cni"
#}
#import {
#  to = aws_iam_role.ebs_csi
#  id = "pathnex-AmazonEKSPodIdentityAmazonEBSCSIDriverRole"
#}