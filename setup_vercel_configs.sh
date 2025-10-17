#!/bin/zsh

BASE_DIR="$(pwd)"

for PROJECT in $(ls -d */); do
  PROJECT_NAME=$(basename "$PROJECT")
  CONFIG_FILE="$BASE_DIR/$PROJECT_NAME/vercel.json"

  [[ "$PROJECT_NAME" == "docs" || "$PROJECT_NAME" == "scripts" ]] && continue

  echo "Setting up $PROJECT_NAME ..."

  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<EOF
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "rootDirectory": "$PROJECT_NAME"
}
EOF
    echo "Created $CONFIG_FILE"
  else
    echo "Existing $CONFIG_FILE found, skipped."
  fi
done

echo "All configs ready."
