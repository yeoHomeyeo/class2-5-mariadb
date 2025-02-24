# class2-5-mariadb
Step 1: Create your RDS Database
Create database with the following parameters and leave all else as default:
● Choose a database creation method: Standard Create
● Engine: MySQL
● Templates: Free tier
● DB Instance Identifier: <your-name>-database
● Credential settings: Managed in AWS Secrets Manager (username leave it as
admin)
● Connectivity: Dont connect to EC2 resource
● DB subnet group: Choose the one that is associated with the private subnets of
the VPC.
● Public access: No
● VPC Security group: Create new (<yourname>-rds-sg)

You will be using this EC2 as a Bastion/Jump host to connect to the RDS. Therefore
ensure that you create this EC2 in a public subnet to be able to SSH into it. You can make
use of the Amazon Linux 2023 AMI to create your instance. (Note: You can use EC2
Instance Connect)
Once created, you can install the MySQL client on the EC2. Installing the MySQL
command-line client - Amazon Relational Database Service

Example command to install mysql client in AL2023 EC2:

sudo dnf install mariadb105

Example command to connect to your RDS from your EC2(Your RDS endpoint can be
retrieved from your database in the RDS console under the Connectivity & Security tab):
You will then be prompted to key in your database password (which you saw from
Secrets manager)

mysql -h YOUR-RDS-ENDPOINT -u admin -p



