resource "aws_security_group" "kakao_http" {
    vpc_id = aws_vpc.kakao_vpc.id
    name = "allow_http"
    description = "Allow  http inbound traffic"

    tags = {
      "Name" = "allow-http"
    }
}    

resource "aws_security_group_rule" "allow_http_ingress" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "http form VPC"
}

resource "aws_security_group_rule" "allow_ssh_ingress" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "ssh from VPC"
}

resource "aws_security_group_rule" "allow_icmp_ingress" {
    type              = "ingress"
    from_port         = -1
    to_port           = -1
    protocol          = "icmp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "icmp from VPC"
}
########### kubernetes 컴포넌트(ex, kubelet, kube-apiserver) 간 통신을 위해 EC2 인스턴스와 연결을 위한 포트 허용 #######
# kube-apiserver
resource "aws_security_group_rule" "allow_kube_apiserver_ingress" {
    type              = "ingress"
    from_port         = 6443
    to_port           = 6443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "kube_apiserver from VPC"
}

# kubelet
resource "aws_security_group_rule" "allow_kubelet_ingress" {
    type              = "ingress"
    from_port         = 10250
    to_port           = 10250
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "kubelet from VPC"
}

# etcd
resource "aws_security_group_rule" "allow_etcd_ingress" {
    type              = "ingress"
    from_port         = 2379
    to_port           = 2380
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "etcd from VPC"
}





####################   
resource "aws_security_group_rule" "allow_http_egress" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kakao_http.id
    description = "http from VPC"
}    


    


