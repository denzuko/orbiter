#!/bin/bash

provider=${MACHINE_DRIVER:-"virtualbox"}
provider_ops=${MACHINE_OPS:-"--engine-storage-driver overlay2"}
maxnodes=${NODES:-3}

echo "### Init Servers ###"

seq 1 ${maxnodes} | xargs -I{} -P${maxnodes} docker-machine create -d "${provider}" ${MACHINE_OPS} sw{}
wait

echo "### Configurate cluster ###"

MANAGER_IP=$(docker-machine ip sw1)
docker-machine ssh sw1 docker swarm init --advertise-addr ${MANAGER_IP}
TOKEN=$(docker-machine ssh sw1 docker swarm join-token -q worker)
for x in seq 2 ${maxnodes}; do
  ADDR=$(docker-machine ip sw${x})
  
  docker-machine ssh sw${x} docker swarm join --token ${TOKEN} --listen-addr ${ADDR} --advertise-addr ${ADDR} ${MANAGER_IP}:2377
done

# Information
echo ""
echo "CLUSTER INFORMATION"
echo "discovery token: ${TOKEN}"
echo "Environment variables to connect trough docker cli"
docker-machine env sw1
