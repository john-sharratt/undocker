#!/bin/bash -e

RUNDIR=$(pwd)
if [ -z "$1" ]; then
  echo "you must provide an image name" 1>&2
  exit 1
fi
if [ -z "$2" ]; then
  tag="latest"
else
  tag=$2
fi
name=$1

# Grab a token
echo -n "acquiring a login token..."
token=$(curl -G -sL https://auth.docker.io/token --data-urlencode "service=registry.docker.io" --data-urlencode "scope=repository:$name:pull" | jq .token | xargs)
echo "Done"

# Attempt to read all the layers for this image
echo -n "reading image ID..."
registry='https://index.docker.io/v2'
layers=$(curl -s -H "Authorization: Bearer $token" $registry/$name/manifests/$tag | jq -M .fsLayers[].blobSum | sed 's|"||g')
if [ -z "$layers" ]; then

  # If it fails then return all the tags
  echo "Failed"
  echo "Could not locate image $name [tag=$tag]"
  exit 1
fi
echo "Ok"

# Now loop loading all the images
echo "extracting image $name [tag=$tag]"
for layer in $layers; do
  echo "extracting layer $layer"

  curl -sL -H "Authorization: Bearer $token" $registry/$name/blobs/$layer | tar -xz
  find . -type f -name ".wh.*" | sed 's|/.wh.||g' | xargs rm -f
  find . -type f -name ".wh.*" | xargs rm -f
done

# Success
echo "Undocker complete!"
exit 0
