# GitHub Actions for DigitalOcean Example

This repository contains an example workflow using the [GitHub Action for DigitalOcean](https://github.com/digitalocean/action-doctl) to build, tag, and deploy a container image to a DigitalOcean Kubernetes cluster.

## Workflow

The [example workflow](.github/workflows/workflow.yaml) will trigger on every push to this repo's `master` branch. For push, the workflow will:

* Build the image from [the included `Dockerfile`](Dockerfile)
* Tag and push the image to a private DigitalOcean container registry
* Retrieve the `kubeconfig` file for a DigitalOcean Kubernetes cluster
* Create a deployment using [config/deployment.yml](config/deployment.yml)

### Notes

* This example is using a Kubernetes cluster running v1.16.x with `action-doctl@v2`. (For older versions, see the [v1 tag](https://github.com/do-community/example-doctl-action/tree/v1).)
* This example uses `external-dns` [installed via Helm](https://github.com/helm/charts/tree/master/stable/external-dns). This is an optional requirement, but you will need to adjust your `config/deployment.yml` file it it is not in use.