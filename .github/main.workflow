workflow "Build and Deploy" {
  on = "push"
  resolves = [
    "Verify deployment",
  ]
}

action "Deploy branch filter" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "Add commit SHA" {
  uses = "actions/bin/sh@master"
  args = ["echo $GITHUB_SHA > $GITHUB_WORKSPACE/site/_meta"]
}

action "Build Docker image" {
  needs = ["Add commit SHA"]
  uses = "actions/docker/cli@master"
  env = {
    DOCKER_USERNAME = "andrewsomething"
    APPLICATION_NAME = "static-example"
  }
  args = ["build", "-t", "$DOCKER_USERNAME/$APPLICATION_NAME:$(echo $GITHUB_SHA | head -c7)", "."]
}

action "Docker Login" {
  uses = "actions/docker/login@master"
  secrets = ["DOCKER_USERNAME", "DOCKER_PASSWORD"]
}

action "Push image to Docker Hub" {
  needs = ["Docker Login", "Build Docker image"]
  uses = "actions/docker/cli@master"
  env = {
    DOCKER_USERNAME = "andrewsomething"
    APPLICATION_NAME = "static-example"
  }
  args = ["push", "$DOCKER_USERNAME/$APPLICATION_NAME"]
}

action "Update deployment file" {
  needs = ["Push image to Docker Hub"]
  uses = "actions/bin/sh@master"
  env = {
    DOCKER_USERNAME = "andrewsomething"
    APPLICATION_NAME = "static-example"
  }
  args = ["TAG=$(echo $GITHUB_SHA | head -c7) && sed -i 's|<IMAGE>|'${DOCKER_USERNAME}'/'${APPLICATION_NAME}':'${TAG}'|' $GITHUB_WORKSPACE/config/deployment.yml"]
}

action "Save DigitalOcean kubeconfig" {
  needs = ["Push image to Docker Hub"]
  uses = "digitalocean/actions/doctl@master"
  secrets = ["DIGITALOCEAN_ACCESS_TOKEN"]
  env = {
    CLUSTER_NAME = "actions-example"
  }
  args = ["kubernetes cluster kubeconfig show $CLUSTER_NAME > $HOME/.kubeconfig"]
}

action "Deploy to DigitalOcean Kubernetes" {
  needs = ["Save DigitalOcean kubeconfig", "Update deployment file"]
  uses = "docker://lachlanevenson/k8s-kubectl"
  runs = "sh -l -c"
  args = ["kubectl --kubeconfig=$HOME/.kubeconfig apply -f $GITHUB_WORKSPACE/config/deployment.yml"]
}

action "Verify deployment" {
  needs = ["Deploy to DigitalOcean Kubernetes"]
  uses = "docker://lachlanevenson/k8s-kubectl"
  env = {
    DEPLOYMENT = "static-example"
  }
  runs = "sh -l -c"
  args = ["kubectl --kubeconfig=$HOME/.kubeconfig rollout status deployment/$DEPLOYMENT"]
}
