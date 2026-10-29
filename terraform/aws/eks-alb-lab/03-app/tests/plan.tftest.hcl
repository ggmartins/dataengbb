mock_provider "aws" {}
mock_provider "kubernetes" {}

override_data {
  target = data.terraform_remote_state.infra

  values = {
    outputs = {
      name              = "eks-alb-lab"
      region            = "us-east-1"
      vpc_id            = "vpc-0123456789abcdef0"
      allowed_cidr      = "203.0.113.10/32"
      public_subnet_ids = [
        "subnet-0123456789abcdef0",
        "subnet-0123456789abcdef1",
      ]
      endpoint   = "https://eks.example.invalid"
      cluster_ca = base64encode("mock-ca")
    }
  }
}

run "app_preview" {
  command = plan

  /*variables {
    tls_mode           = "off"
    create_trust_store = false
    target_type        = "ip"
  }*/


  variables {
    tls_mode           = "verify"
    create_trust_store = true
    target_type        = "ip"
  }

}
