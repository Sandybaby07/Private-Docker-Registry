#!/bin/bash
read -p "Please input image name: " name
read -p "Please input image version (tag): " tag
read -p "Please input the path to ca cert file: " cacert

# get config digest and layers digest
read config_digest layers_digest < <(echo $(curl -u testuser:testpassword --cacert ${cacert} https://sandy.registry.com:443/v2/${name}/manifests/${tag} \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" | \jq --raw-output '.config.digest, [.layers[].digest]'))

# how many layers
layers=$(echo $layers_digest | jq '.| length')

# get image config
curl -u testuser:testpassword https://sandy.registry.com:443/v2/${name}/blobs/${config_digest} \
  -L \
  -o config.json \
  --cacert ${cacert}

result=$(cat config.json | jq '.errors')

# add a mabifest.json
echo "[{\"Config\":\"config.json\",\"RepoTags\":[\"${name}:${tag}\"],\"Layers\": []}]" >manifest.json

if [ -f "./config.json" ] && [ "$result" == "null" ]; then
  for ((i = 0; i < $layers; i++)); do
    echo $i
    digest=$(echo $layers_digest | jq --raw-output ".[$i]")
    echo $digest
    # download layers
    curl -u testuser:testpassword https://sandy.registry.com:443/v2/${name}/blobs/${digest} \
      -L \
      -o layer${i}.tar.gz \
      --cacert ${cacert}
    # add layers to manifest
    if [ -f "./layer${i}.tar.gz" ] && [ -f "./manifest.json" ]; then
      echo $(jq ".[].Layers += [\"layer${i}.tar.gz\"]" ./manifest.json) >manifest.json
    else
      echo "layer${i}.tar.gz error!"
      exit 0
    fi
  done
  #load image
  tar -cvf ${name}.tar *
  docker load <${name}.tar
else
  echo "exit!"
  exit 0
fi