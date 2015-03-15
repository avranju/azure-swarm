#!/bin/sh

export DOCKER_HOST="0.0.0.0:2375"

# install docker
curl -sSL https://get.docker.com/ubuntu/ | sudo sh

# reconfigure docker upstart service to listen on tcp
sudo sh -c "echo DOCKER_OPTS=\\\"-H=$DOCKER_HOST\\\" >> /etc/default/docker"

# restart docker service
sudo service docker restart

# pull swarm image
sudo docker -H=$DOCKER_HOST pull swarm

