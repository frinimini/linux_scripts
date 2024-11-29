#!/bin/bash

# Exit on any error
set -e

echo "Cloning the Mochi repository..."
git clone https://github.com/genmoai/models
cd models

echo "Setting up Python virtual environment..."
python3 -m venv myenv
source myenv/bin/activate

echo "Installing required Python packages..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -ve . --no-build-isolation
pip install click huggingface_hub

echo "Downloading model weights..."
python3 ./scripts/download_weights.py weights/

echo "Fixing 'configure_model' issue in gradio_ui.py..."
sed -i "s/configure_model(model_dir, cpu_offload)/configure_model(model_dir, cpu_offload, cpu_offload_=True)/" ./demos/gradio_ui.py

echo "Enabling public link sharing in gradio_ui.py..."
sed -i "s/demo.launch()/demo.launch(share=True)/" ./demos/gradio_ui.py

echo "Adding alias for running Mochi Gradio UI..."
# Add alias to ~/.bashrc or ~/.zshrc
if [[ $SHELL == *"zsh"* ]]; then
    echo 'alias mochiui="cd ~/models && source myenv/bin/activate && python3 ./demos/gradio_ui.py --model_dir weights/"' >> ~/.zshrc
    source ~/.zshrc
else
    echo 'alias mochiui="cd ~/models && source myenv/bin/activate && python3 ./demos/gradio_ui.py --model_dir weights/"' >> ~/.bashrc
    source ~/.bashrc
fi

echo "Setup completed successfully! To run the Gradio UI, use the alias 'mochiui' or run the following command:"
echo "python3 ./demos/gradio_ui.py --model_dir weights/"
