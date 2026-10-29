# Replace the real Helm provider with a mock.
mock_provider "helm" {}

# Supply infrastructure outputs without reading applied state.
override_data {
  target = data.terraform_remote_state.infra

  values = {
    outputs = {
      name                = "eks-alb-lab"
      region              = "us-east-1"
      vpc_id              = "vpc-0123456789abcdef0"
      endpoint            = "https://eks.example.invalid"
      cluster_ca          = base64encode("mock-ca")
      controller_role_arn = "arn:aws:iam::123456789012:role/eks-alb-lab-lbc"
    }
  }
}

run "controller_preview" {
  command = plan
}
