#!/bin/bash
# Link network volume models to where ComfyUI custom nodes expect them
# Called at worker startup before ComfyUI launches

VOLUME="/runpod-volume"
MODELS="/comfyui/models"

echo "=== Linking network volume models ==="

# XLabs IPAdapter models -> {models_dir}/xlabs/ipadapters/
if [ -d "$VOLUME/models/xlabs/ipadapters" ]; then
    mkdir -p "$MODELS/xlabs/ipadapters"
    for f in "$VOLUME/models/xlabs/ipadapters"/*.safetensors; do
        [ -f "$f" ] && ln -sf "$f" "$MODELS/xlabs/ipadapters/$(basename $f)" && echo "  Linked: xlabs/ipadapters/$(basename $f)"
    done
fi

# CLIP Vision models -> {models_dir}/clip_vision/
if [ -d "$VOLUME/models/clip_vision" ]; then
    mkdir -p "$MODELS/clip_vision"
    for f in "$VOLUME/models/clip_vision"/*.safetensors; do
        [ -f "$f" ] && ln -sf "$f" "$MODELS/clip_vision/$(basename $f)" && echo "  Linked: clip_vision/$(basename $f)"
    done
fi

# Also check if models are directly in volume root models dir
for model_dir in "xlabs" "clip_vision" "ipadapter" "controlnet"; do
    if [ -d "$VOLUME/models/$model_dir" ]; then
        mkdir -p "$MODELS/$model_dir"
        for f in "$VOLUME/models/$model_dir"/*.safetensors "$VOLUME/models/$model_dir"/*.bin; do
            [ -f "$f" ] && ln -sf "$f" "$MODELS/$model_dir/$(basename $f)" && echo "  Linked: $model_dir/$(basename $f)"
        done
    fi
done

# Link clip-vit-large-patch14 if it's in a subfolder
if [ -d "$VOLUME/models/clip-vit-large-patch14" ]; then
    mkdir -p "$MODELS/clip_vision"
    for f in "$VOLUME/models/clip-vit-large-patch14"/*.safetensors "$VOLUME/models/clip-vit-large-patch14"/*.bin; do
        [ -f "$f" ] && ln -sf "$f" "$MODELS/clip_vision/$(basename $f)" && echo "  Linked: clip_vision/$(basename $f) (from clip-vit-large-patch14/)"
    done
fi

echo "=== Model linking complete ==="
