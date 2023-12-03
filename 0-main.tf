provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "my-order-rds" {
  vpc_id      = "${data.aws_vpc.default.id}"
  name        = "my-order-rds"
  description = "Allow all inbound for Postgres"
ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "testDb" {
  identifier         = "my-order-rds"
  allocated_storage  = 20
  storage_type       = "gp2"
  engine             = "postgres"
  engine_version     = "12.17"
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.my-order-rds.id]
  instance_class     = "db.t2.micro"
  username           = "moiz"
  password = var.db_password
}


output "aws_db_url" {
  value = aws_db_instance.testDb.address
}