# define IAM role

resource "aws_iam_role" "access_ec2" {
  name        = "ssm-role"
  description = "Enables access to EC2 instances"
  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": {
        "Effect": "Allow",
        "Principal": {"Service": "ec2.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }
  }
  EOF
  tags = {
    stack = "ssm-role"
  }
}

# assign IAM policy to role

resource "aws_iam_role_policy_attachment" "ssm-policy" {
  role       = aws_iam_role.access_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# instance profile is used to pass IAM role to the EC2 instances.

resource "aws_iam_instance_profile" "ssm-iam-profile" {
  name = "ec2_profile"
  role = aws_iam_role.access_ec2.name
}