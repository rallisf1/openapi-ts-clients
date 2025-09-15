#!/bin/bash

# Load current versions
if [ -f versions.json ]; then
  versions=$(cat versions.json)
else
  versions="{}"
fi

# Read APIs from apis.json
apis=$(cat apis.json)

# Use jq to iterate over APIs
for api in $(echo "$apis" | jq -c '.[]'); do
  name=$(echo "$api" | jq -r '.name')
  url=$(echo "$api" | jq -r '.url')
  echo "Checking $name at $url"

  # Fetch schema content
  if ! schema_content=$(curl -s --fail --max-time 30 "$url"); then
    echo "Failed to fetch schema for $name from $url"
    continue
  fi

  if [ -z "$schema_content" ]; then
    echo "Empty schema content for $name"
    continue
  fi

  # Extract version: try JSON first, then YAML
  version=$(echo "$schema_content" | jq -r '.info.version' 2>/dev/null)
  if [ -z "$version" ] || [ "$version" = "null" ]; then
    version=$(echo "$schema_content" | yq e '.info.version' - 2>/dev/null)
  fi

  if [ -z "$version" ] || [ "$version" = "null" ]; then
    echo "Failed to extract version for $name"
    continue
  fi

  # Get last published version from versions.json
  last_version=$(echo "$versions" | jq -r ".[\"$url\"]")
  if [ "$last_version" = "$version" ]; then
    echo "Version $version for $name is unchanged. Skipping."
    continue
  fi

  echo "New version $version for $name. Generating client."

  # Create temporary directory
  mkdir -p "clients/$name"
  cd "clients/$name"

  # Determine schema format and save file
  if echo "$schema_content" | jq . >/dev/null 2>&1; then
    echo "$schema_content" > openapi.json
    schema_file="openapi.json"
  else
    echo "$schema_content" > openapi.yaml
  if ! npx openapi-typescript@latest "$schema_file" -o client.ts; then
    echo "Failed to generate TypeScript client for $name"
    cd ../..
    continue
  fi

  if [ ! -f client.ts ]; then
    echo "Generated client file not found for $name"
    cd ../..
    continue
  fi
  fi

  # Generate client
  npx openapi-typescript@latest "$schema_file" -o client.ts

  # Create package.json
  cat > package.json << EOF
{
  "name": "@rallisf1/ts-client-$name",
  "main": "client.ts",
  "types": "client.ts",
  "version": "$version",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/rallisf1/openapi-ts-clients.git"
  }
}
EOF

  # Publish to GitHub Packages
  if ! npm publish --dry-run; then
    echo "npm publish dry-run failed for $name@$version"
    cd ../..
    continue
  fi

  if ! npm publish; then
    echo "Failed to publish package for $name@$version"
    cd ../..
    continue
  fi

  echo "Successfully published @rallisf1/ts-client-$name@$version"

  # Return to root directory
  cd ../..

  # Update versions.json
  versions=$(echo "$versions" | jq ".[\"$url\"] = \"$version\"")
done

# Save updated versions
echo "$versions" > versions.json