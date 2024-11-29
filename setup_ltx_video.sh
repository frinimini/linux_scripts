#!/bin/bash

# Exit script on error
set -e

# Variables
REPO_PATH="ComfyUI-Manager-Setup/ComfyUI/custom_nodes/LTX-Video"
MODEL_PATH="$REPO_PATH/models/ltx_video"

# Step 1: Clone the repository
echo "Cloning LTX-Video repository..."
git clone https://github.com/Lightricks/LTX-Video.git $REPO_PATH

# Step 2: Navigate to the repository
cd $REPO_PATH

# Step 3: Install dependencies
echo "Installing dependencies..."
python3 -m pip install -e .[inference-script]

# Step 4: Install huggingface_hub
echo "Installing huggingface_hub..."
pip install huggingface_hub

# Step 5: Download model into the specified directory
echo "Downloading model to $MODEL_PATH..."
mkdir -p $MODEL_PATH
python3 - <<EOF
from huggingface_hub import snapshot_download

model_path = "$MODEL_PATH"
snapshot_download(
    "Lightricks/LTX-Video",
    local_dir=model_path,
    local_dir_use_symlinks=False,
    repo_type='model'
)
EOF

# Completion message
echo "LTX-Video setup completed. Model downloaded to $MODEL_PATH."
