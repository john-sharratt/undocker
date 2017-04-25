#!/bin/bash -e

if [ -z "$1" ]; then
  echo "You must provide an image name" 1>&2
  exit 1
fi
if [ -z "$2" ]; then
  echo "Your must provide a tag" 1>&2
  exit 1
fi
if [ -z "$3" ]; then
  echo "Your must provide an output folder" 1>&2
  exit 1
fi

# Grab a token
echo -n "Acquiring a login token..."
token="$(curl -sL -o /dev/null -D- -H 'X-Docker-Token: true' "https://index.docker.io/v1/repositories/$1/images" | tr -d '\r' | awk -F ': *' '$1 == "X-Docker-Token" { print $2 }')"
echo "Done"

# Attempt to read the ID of the container
echo -n "Reading image ID..."
registry='https://registry-1.docker.io/v1'
id="$(curl -sL -H "Authorization: Token $token" "$registry/repositories/$1/tags/$2" | sed 's/"//g')"
if [[ "${#id}" -ne 64 ]]; then

  # If it fails then return all the tags
  echo "Failed"
  echo "Could not locate image $1:$2... trying to list tags"
  curl -sL -H "Authorization: Token $token" "$registry/repositories/$1/tags" | jq -M .
  exit 1
fi
echo $id

# Now loop loading all the images
echo "extracting image $1:$2 ($id)"
ancestry="$(curl -sL -H "Authorization: Token $token" "$registry/images/$id/ancestry")"
IFS=',' && ancestry=(${ancestry//[\[\] \"]/}) && IFS=' \n\t' && mkdir -p $3
for id in "${ancestry[@]}"; do
  echo "extracting layer $id"
  curl -#L -H "Authorization: Token $token" "$registry/images/$id/layer" | tar -xvz
done

# Success
echo "Undocker complete!"
exit 0
