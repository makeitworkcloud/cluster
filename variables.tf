variable "cluster_host" {
  description = "The hostname:port for Kubernetes/OpenShift."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)+(:[0-9]{1,4})?$", var.cluster_host))
    error_message = "cluster_host must be in the form 'my.cluster.hostname.xyz:1234'"
  }
}
