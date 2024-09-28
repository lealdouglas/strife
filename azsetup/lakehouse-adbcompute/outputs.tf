# Saída da URL do cluster
# Output the cluster URL
output "cluster_url" {
  value = databricks_cluster.this.url
}
