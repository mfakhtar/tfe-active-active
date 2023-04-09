resource "aws_elasticache_subnet_group" "test" {
  name       = "tfe-redis"
  subnet_ids = aws_subnet.fawaz-tfe-es-pri-sub[*].id
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "tfe-redis-fawaz"
  engine               = "redis"
  node_type            = "cache.t3.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  security_group_ids   = [aws_security_group.guide-tfe-es-sg-redis.id]
  subnet_group_name    = aws_elasticache_subnet_group.test.name
}

resource "aws_security_group" "guide-tfe-es-sg-redis" {
  name   = "tfe-guide-es-sg-redis"
  vpc_id = aws_vpc.guide-tfe-es-vpc.id
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.guide-tfe-es-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}