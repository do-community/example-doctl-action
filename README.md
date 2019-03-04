# GitHub Actions for DigitalOcean Example

This repository contains an example workflow using the [GitHub Action for DigitalOcean](https://github.com/digitalocean/action) to build, tag, and deploy a container image to a DigitalOcean Kubernetes cluster.

## Workflow

The [example workflow](.github/main.workflow) will trigger on every push to this repo's `master` branch. For push, the workflow will:

* Build the image from [the included `Dockerfile`](Dockerfile)
* Tag and push the image to Docker Hub
* Retrieve the `kubeconfig` file for a DigitalOcean Kubernetes cluster
* Create a deployment using [config/deployment.yml](config/deployment.yml)
