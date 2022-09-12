# define IAM role

resource "aws_iam_role" "access_ec2" {
  name        = "ssm-role"
  description = "Enables access to EC2 instances"
  # policy that grants ec2 instances permission to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect    = "Allow"
        Principal = { "Service" : "ec2.amazonaws.com" }
      }
    ]
  })
  tags = {
    stack = "ssm-role"
  }
}

# Create an IAM policy to allow SSH connections through Session Manager 

resource "aws_iam_policy" "ssm_ssh" {
  name        = "ssm_ssh"
  description = "IAM policy to allow SSH connections through Session Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:StartSession",
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:ec2:*:*:instance/*", "arn:aws:ssm:*:*:document/AWS-StartSSHSession"]
      },
    ]
  })
}

locals {
  iam_policies = {
    policy1 = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    policy2 = aws_iam_policy.ssm_ssh.arn,
  }
}

# assign IAM policies to role

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  for_each   = local.iam_policies
  role       = aws_iam_role.access_ec2.name
  policy_arn = each.value
}

# instance profile is used to pass IAM role to the EC2 instances.

resource "aws_iam_instance_profile" "ssm_iam_profile" {
  name = "ec2_profile"
  role = aws_iam_role.access_ec2.name
}