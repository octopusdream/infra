resource "aws_security_group" "http" {
    vpc_id = var.vpc_id
    name = "allow_http"
    description = "Allow  http inbound traffic"

    # tags = {
    #   "Name" = "${var.alltag}-allow-http"
    # }
  tags = "kubernetes.io/cluster/jordy, owned|shared"
}

resource "aws_security_group_rule" "allow_custom_ingress" {
    type              = "ingress"
    from_port         = 0
    to_port           = 65535
    protocol          = "4"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "Custom Protocol from VPC"
}

resource "aws_security_group_rule" "allow_http_ingress" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description       = "http form VPC"
}

resource "aws_security_group_rule" "allow_ssh_ingress" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description       = "ssh from VPC"
}

resource "aws_security_group_rule" "allow_icmp_ingress" {
    type              = "ingress"
    from_port         = -1
    to_port           = -1
    protocol          = "icmp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "icmp from VPC"
}
########### kubernetes 컴포넌트(ex, kubelet, kube-apiserver) 간 통신을 위해 EC2 인스턴스와 연결을 위한 포트 허용 #######
# kube-apiserver
resource "aws_security_group_rule" "allow_kube_apiserver1_ingress" {
    type              = "ingress"
    from_port         = 6443
    to_port           = 6443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "kube_apiserver from VPC"
}

resource "aws_security_group_rule" "allow_kubelet_apiserver1_ingress" {
    type              = "ingress"
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "kubelet_apiserver from VPC"
}


resource "aws_security_group_rule" "allow_kube_apiserver2_ingress" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "kube_apiserver from VPC"
}

# kubelet
resource "aws_security_group_rule" "allow_kubelet_ingress" {
    type              = "ingress"
    from_port         = 10250
    to_port           = 10250
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "kubelet from VPC"
}

# efs
resource "aws_security_group_rule" "allow_efs_ingress" {
    type              = "ingress"
    from_port         = 2049
    to_port           = 2049
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "efs from VPC"
}

# etcd
resource "aws_security_group_rule" "allow_etcd_ingress" {
    type              = "ingress"
    from_port         = 2379
    to_port           = 2380
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "etcd datastore from VPC"
}

# Calico networking
resource "aws_security_group_rule" "allow_bgp_ingress" {
    type              = "ingress"
    from_port         = 179
    to_port           = 179
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "Calico networking(bgp) from VPC"
}

resource "aws_security_group_rule" "allow_vxlan_ingress" {
    type              = "ingress"
    from_port         = 4789
    to_port           = 4789
    protocol          = "udp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "Calico networking with vxlan from VPC"
}

resource "aws_security_group_rule" "allow_typha_ingress" {
    type              = "ingress"
    from_port         = 5473
    to_port           = 5473
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "Calico networking with Typha enabled from VPC"
}

resource "aws_security_group_rule" "allow_ipv4_wireguard_ingress" {
    type              = "ingress"
    from_port         = 51820
    to_port           = 51820
    protocol          = "udp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "Calico networking with IPv4 Wireguard enabled from VPC"
}

#resource "aws_security_group_rule" "allow_ipv6_wireguard_ingress" {
#    type              = "ingress"
#    from_port         = 51821
#    to_port           = 51821
#    protocol          = "udp"
#    cidr_blocks       = ["0.0.0.0/0"]
#    security_group_id = aws_security_group.http.id
#    description = "Calico networking with IPv6 Wireguard enabled from VPC"
#}


####################   
resource "aws_security_group_rule" "allow_http_egress" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.http.id
    description = "http from VPC"
}