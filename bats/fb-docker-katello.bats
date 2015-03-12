#!/usr/bin/env bats
# vim: ft=sh:sw=2:et:tw=100

hammer -u admin -p changeme organization create --name DOrg

@test "create a product" {
  hammer -u admin -p changeme product create --organization="DOrg" \
    --name="DProd" | grep -q "Product created"
}

@test "create Docker repository" {
  hammer -u admin -p changeme repository create --organization="DOrg" \
    --product="DProd" --content-type="docker" --name "busybox" \
    --url https://registry.hub.docker.com --docker-upstream-name busybox | \
    grep -q "Repository created"
}

@test "sync Docker repository" {
  hammer -u admin -p changeme repository synchronize --organization="DOrg" \
    --product="DProd" --name="busybox"
}

@test "create lifecycle environment" {
  hammer -u admin -p changeme lifecycle-environment create --organization="DOrg" \
    --prior="Library" --name="Dev" | grep -q "Environment created"
}

@test "create content view" {
  hammer -u admin -p changeme content-view create --organization="DOrg" \
    --name="DCV" | grep -q "Content view created"
}

@test "add repo to content view" {
  repo_id=$(hammer -u admin -p changeme repository list --organization="DOrg" \
    | grep busybox | cut -d\| -f1 | egrep -i '[0-9]+')
  hammer -u admin -p changeme content-view add-repository --organization="DOrg" \
    --name="DCV" --repository-id=$repo_id | grep -q "The repository has been associated"
}

@test "publish content view" {
  hammer -u admin -p changeme content-view publish --organization="DOrg" \
        --name="DCV"
}

@test "promote content view" {
  hammer -u admin -p changeme content-view version promote  --organization="DOrg" \
        --content-view="DCV" --to-lifecycle-environment="Dev" --version 1
}

@test "docker tag list" {
  skip # skip due to http://projects.theforeman.org/issues/9689
  hammer -u admin -p changeme docker tag list --organization="DOrg" \
        --content-view="DCV" --environment="Dev" | grep -q "latest"
}

@test "docker image list" {
  skip # skip due to http://projects.theforeman.org/issues/9689
  count=$(hammer -u admin -p changeme docker image list --organization="DOrg" \
          --content-view="DCV" --environment="Dev" | wc -l)
  [ $count -gt 1 ]
}

@test "create docker compute resource" {
  hammer -u admin -p changeme compute-resource create --name DockerCP --provider Docker \
         --url "http://localhost:2375"
}

# create a container from docker hub
@test "create a container from docker hub" {
  hammer -u admin -p changeme docker container create --name crafty_turing --command bash \
    --repository_name centos --tag latest --compute-resource DockerCP
}

@test "destroy docker hub container" {
  hammer -u admin -p changeme docker container delete --name crafty_turing
}

# create a container from our busybox repo
@test "create a busybox:latest container" {
  hammer -u admin -p changeme docker container create --name shady_collier --command bash \
    --repository-name dorg-dev-dcv-dprod-busybox --tag latest --compute-resource DockerCP
}

# pull from busybox

@test "destroy compute resource" {
  hammer -u admin -changeme compute-resource destroy --name DockerCP
}