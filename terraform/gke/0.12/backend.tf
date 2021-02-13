# https://stackoverflow.com/questions/59053993/failed-to-get-existing-workspaces-querying-cloud-storage-failed-storage-bucke
#TODO move to ../../../stage/services/gke-cluster/
terraform {
  backend "gcs" {
    bucket  = "odp-test-storage-3ffa"
    prefix  = "stage/odp"
  }
}