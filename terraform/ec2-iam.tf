resource "aws_iam_instance_profile" "host_profile" {
  name = "host-profile"
  role = aws_iam_role.iam_role.name
}


resource "aws_iam_role" "iam_role" {
  name               = var.iam_role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_policy" {
  role = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}







# resource "aws_iam_instance_profile" "host_profile" {
#   name = "host-profile"
#   role = aws_iam_role.host_role.name
# }

# resource "aws_iam_role" "host_role" {
#   name = "host-role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "host_policy" {
#   role       = aws_iam_role.host_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

