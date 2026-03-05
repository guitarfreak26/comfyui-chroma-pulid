#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# === CUSTOM: Link network volume models to where custom nodes expect them ===
echo "worker-comfyui: Linking network volume models"

VOLUME="/runpod-volume"
MODELS="/comfyui/models"

# XLabs IPAdapter: node looks in {models_dir}/xlabs/ipadapters/
if [ -d "$VOLUME/models/xlabs/ipadapters" ]; then
    mkdir -p "$MODELS/xlabs/ipadapters"
    for f in "$VOLUME/models/xlabs/ipadapters"/*.safetensors; do
        [ -f "$f" ] && ln -sf "$f" "$MODELS/xlabs/ipadapters/$(basename "$f")" && echo "  Linked: xlabs/ipadapters/$(basename "$f")"
    done
fi

# CLIP Vision: AdvancedVisionLoader looks in {models_dir}/clip_vision/
if [ -d "$VOLUME/models/clip_vision" ]; then
    mkdir -p "$MODELS/clip_vision"
    for f in "$VOLUME/models/clip_vision"/*.safetensors "$VOLUME/models/clip_vision"/*.bin; do
        [ -f "$f" ] && ln -sf "$f" "$MODELS/clip_vision/$(basename "$f")" && echo "  Linked: clip_vision/$(basename "$f")"
    done
fi

echo "worker-comfyui: Model linking complete"
# === END CUSTOM ===

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi
