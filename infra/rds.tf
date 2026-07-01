resource "aws_security_group" "rds" {
  name        = "oficina-mecanica-rds-sg"
  description = "Allow inbound PostgreSQL traffic from VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "oficina-mecanica-rds-sg"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "oficina-mecanica-rds-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "oficina-mecanica-rds-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "oficina-mecanica-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  db_name                = "oficina_mecanica_production"
  username               = "postgres"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "oficina-mecanica-rds"
  }
}
