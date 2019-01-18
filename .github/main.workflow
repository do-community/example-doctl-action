workflow "Build and Deploy" {
  on = "push"
  resolves = [
    "Verify deployment",
  ]
}

action "Add commit SHA" {
  uses = "actions/bin/sh@master"
  args = ["echo $GITHUB_SHA > $GITHUB_WORKSPACE/site/_meta"]
}

action "Build Docker image" {
  needs = ["Add commit SHA"]
  uses = "actions/docker/cli@master"
  args = ["build", "-t", "static-example", "."]
}

action "Deploy branch filter" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "Tag Docker image" {
  needs = ["Build Docker image"]
  uses = "actions/docker/tag@master"
  env = {
    DOCKER_USERNAME = "andrewsomething"
    APPLICATION_NAME = "static-example"
  }
  args = ["static-example", "$DOCKER_USERNAME/$APPLICATION_NAME"]
}

action "Docker Login" {
  uses = "actions/docker/login@master"
  secrets = ["DOCKER_USERNAME", "DOCKER_PASSWORD"]
}

action "Push image to Docker Hub" {
  needs = ["Docker Login", "Tag Docker image"]
  uses = "actions/docker/cli@master"
  env = {
    DOCKER_USERNAME = "andrewsomething"
    APPLICATION_NAME = "static-example"
  }
  args = ["push", "$DOCKER_USERNAME/$APPLICATION_NAME"]
}

action "Save DigitalOcean kubeconfig" {
  needs = ["Push image to Docker Hub"]
  uses = "andrewsomething/digitalocean-action/doctl@master"
  secrets = ["DIGITALOCEAN_ACCESS_TOKEN"]
  env = {
    CLUSTER_NAME = "actions-example"
  }
  args = ["kubernetes", "cluster", "kubeconfig", "save", "$CLUSTER_NAME"]
}

action "Set kubeconfig context" {
  needs = ["Save DigitalOcean kubeconfig"]
  uses = "docker://lachlanevenson/k8s-kubectl"
  runs = "sh -l -c"
  args = ["kubectl config use-context $(cat $HOME/.kube/config | grep -m 1 name | cut -d ':' -f 2)"]
}

action "Deploy to DigitalOcean Kubernetes" {
  needs = ["Set kubeconfig context"]
  uses = "docker://lachlanevenson/k8s-kubectl"
  env = {
    DOCKER_USERNAME = "andrewsomething"
    APPLICATION_NAME = "static-example"
  }
  runs = "sh -l -c"
  args = ["SHORT_REF=$(echo ${GITHUB_SHA} | head -c7) && cat $GITHUB_WORKSPACE/config/deployment.yml | sed 's/DOCKER_USERNAME/'\"$DOCKER_USERNAME\"'/' | sed 's/APPLICATION_NAME/'\"$APPLICATION_NAME\"'/' | sed 's/TAG/'\"$SHORT_REF\"'/' | kubectl apply -f - "]
}

action "Verify deployment" {
  needs = ["Deploy to DigitalOcean Kubernetes"]
  uses = "docker://lachlanevenson/k8s-kubectl"
  env = {
    DEPLOYMENT = "static-example"
  }
  runs = "sh -l -c"
  args = ["kubectl rollout status deployment/$DEPLOYMENT"]
}
