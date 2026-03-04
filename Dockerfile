# alarastudios/comfyui-chroma-pulid
# Custom nodes only — models live on Network Volume
FROM runpod/worker-comfyui:5.1.0-base

# ============================================
# Custom Nodes via git clone
# ============================================
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/PaoloC68/ComfyUI-PuLID-Flux-Chroma.git && \
    git clone https://github.com/XLabs-AI/x-flux-comfyui.git && \
    git clone https://github.com/ostris/ComfyUI-Advanced-Vision.git && \
    git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    git clone https://github.com/TinyTerra/ComfyUI_tinyterranodes.git && \
    git clone https://github.com/neuratech-ai/ComfyUI-MultiGPU.git && \
    git clone https://github.com/city96/ComfyUI-GGUF.git

# Install all requirements
RUN cd /comfyui/custom_nodes && \
    for dir in */; do \
      if [ -f "$dir/requirements.txt" ]; then \
        pip install -r "$dir/requirements.txt" 2>/dev/null || true; \
      fi; \
    done

# Install insightface + onnxruntime (needed by PuLID)
RUN pip install insightface onnxruntime-gpu

# Patch PuLID: remove 'providers' kwarg from FaceAnalysis (incompatible with newer insightface)
RUN sed -i 's/providers=\[provider.*ExecutionProvider.*\]//' \
    /comfyui/custom_nodes/ComfyUI-PuLID-Flux-Chroma/pulidflux.py && \
    sed -i 's/root=INSIGHTFACE_DIR, )/root=INSIGHTFACE_DIR)/' \
    /comfyui/custom_nodes/ComfyUI-PuLID-Flux-Chroma/pulidflux.py

# Download InsightFace antelopev2 model (needed by PuLID face detection)
RUN mkdir -p /comfyui/models/insightface/models/antelopev2 && \
    wget -O /tmp/antelopev2.zip "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" && \
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/antelopev2.zip').extractall('/comfyui/models/insightface/models/antelopev2/')" && \
    rm /tmp/antelopev2.zip

# Download PuLID model into the image (custom path not mapped from volume)
RUN mkdir -p /comfyui/models/pulid && \
    wget -O /comfyui/models/pulid/pulid_flux_v0.9.0.safetensors \
    "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.0.safetensors"
