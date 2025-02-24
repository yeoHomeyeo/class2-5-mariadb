### RDS - > mariaDB 
### Exercise for hands on 2.5, not assignment

resource "random_password" "rds_password" {
  length  = 16
  special = true
}


resource "aws_db_subnet_group" "chrisy_private_subnet_group" {
  name = "chrisy-private-subnet-group"
  subnet_ids = [
    aws_subnet.chrisy_private_subnet_a.id,
    aws_subnet.chrisy_private_subnet_b.id
  ]
  description = "Subnet group for RDS instance"
}

resource "aws_security_group" "chrisy_vpc_db_secgrp" {
  name        = "chrisy-vpc-db-secgrp"
  vpc_id      = aws_vpc.chrisy-vpc.id # hardcoded vpc id
  description = "Security group for RDS database"

  # Inbound rules (customize as needed)
  # Example: Allow access from a specific IP range
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with your allowed CIDR block(s)
    security_groups = [aws_security_group.allow_ssh.id]
  }

  # Outbound rule (allow all outbound traffic by default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "chrisymysqlrds" {
  allocated_storage    = 20                    # Minimum for free tier
  db_name              = "chrisyass25database" # name of the database within the RDS instance
  engine               = "mysql"
  engine_version       = "8.0"                       #  
  instance_class       = "db.t3.micro"               # Free tier eligible
  identifier           = "chrisy-mysql-rds-database" # RDS instance identifier: part of the RDS instance's ARN
  username             = "admin"
  password             = random_password.rds_password.result # See random_password resource below
  parameter_group_name = "default.mysql8.0"                  # Or create a custom parameter group

  db_subnet_group_name   = aws_db_subnet_group.chrisy_private_subnet_group.name
  vpc_security_group_ids = [aws_security_group.chrisy_vpc_db_secgrp.id]

  publicly_accessible = false
  skip_final_snapshot = true # Important for quick deletion in free tier

  # Optional but recommended for production:
  # multi_az             = false # For high availability (not free tier)
  # backup_retention_period = 0 # Disable automated backups in free tier to save space

  lifecycle {
    create_before_destroy = true # Important for avoiding data loss during updates
  }

  #arn = aws_db_instance.aws_db_instance.chrisymysqlrds.arn # Output the ARN of the RDS instance
}

resource "aws_secretsmanager_secret" "rds_xxx_secret" {
  name                    = "rds-cred-${aws_db_instance.chrisymysqlrds.identifier}"
  description             = "Credentials for RDS instance ${aws_db_instance.chrisymysqlrds.identifier}"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_xxx_secret.id
  secret_string = jsonencode({
    username = aws_db_instance.chrisymysqlrds.username,
    password = random_password.rds_password.result,
    host     = aws_db_instance.chrisymysqlrds.endpoint,
    port     = aws_db_instance.chrisymysqlrds.port,
    dbname   = aws_db_instance.chrisymysqlrds.db_name,
    arn      = aws_db_instance.chrisymysqlrds.arn
  })
}

output "secret_name" {
  value = aws_secretsmanager_secret.rds_xxx_secret.name
}

output "rds_arn" {
  value = aws_db_instance.chrisymysqlrds.arn
}

# output "password_access" {
#   value     = random_password.rds_password
#   sensitive = false
# }
