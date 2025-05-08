data "sops_file" "secret_vars" {
  source_file = "${path.module}/secrets/secrets.yaml"
}
