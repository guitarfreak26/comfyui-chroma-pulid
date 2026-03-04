# alarastudios/comfyui-chroma-pulid
# Chroma + PuLID + IPAdapter worker for RunPod Serverless
FROM runpod/worker-comfyui:5.1.0-base

# ============================================
# Custom Nodes - ALL via git clone (registry is unreliable)
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
    git clone https://github.com/neuratech-ai/ComfyUI-MultiGPU.git

# Install all requirements
RUN cd /comfyui/custom_nodes && \
    for dir in */; do \
      if [ -f "$dir/requirements.txt" ]; then \
        pip install -r "$dir/requirements.txt" 2>/dev/null || true; \
      fi; \
    done

# Install insightface + onnxruntime (needed by PuLID)
RUN pip install insightface onnxruntime-gpu

# ============================================
# Models - Chroma GGUF Q8
# ============================================
RUN comfy model download \
    --url https://huggingface.co/silveroxides/Chroma-GGUF/resolve/main/chroma-unlocked-v37-detail-calibrated/chroma-unlocked-v37-detail-calibrated-Q8_0.gguf \
    --relative-path models/diffusion_models/Chroma \
    --filename chroma-unlocked-v37-detail-calibrated-Q8_0.gguf

# ============================================
# Models - T5-XXL text encoder
# ============================================
RUN comfy model download \
    --url https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors \
    --relative-path models/clip \
    --filename t5xxl_fp16.safetensors

# ============================================
# Models - VAE
# ============================================
RUN comfy model download \
    --url https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors \
    --relative-path models/vae \
    --filename ae.safetensors

# ============================================
# Models - PuLID
# ============================================
RUN comfy model download \
    --url https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.0.safetensors \
    --relative-path models/pulid \
    --filename pulid_flux_v0.9.0.safetensors

# ============================================
# Models - IPAdapter + CLIP Vision
# ============================================
RUN comfy model download \
    --url https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/ip_adapter.safetensors \
    --relative-path models/xlabs/ipadapters \
    --filename ip_adapter.safetensors

RUN comfy model download \
    --url https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors \
    --relative-path models/clip_vision \
    --filename clip-vit-large-patch14.safetensors

# ============================================
# Models - SigLIP2
# ============================================
RUN comfy model download \
    --url https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors \
    --relative-path models/clip_vision \
    --filename siglip2-so400m-patch16-512.safetensors

# ============================================
# Models - Hyper Chroma LoRA (speed)
# ============================================
RUN comfy model download \
    --url https://huggingface.co/clover-supply/Chroma-loras/resolve/main/Hyper-Chroma-low-step-LoRA.safetensors \
    --relative-path models/loras/Chroma \
    --filename Hyper-Chroma-low-step-LoRA.safetensors

# ============================================
# Models - 4x Face Upscaler
# ============================================
RUN comfy model download \
    --url https://huggingface.co/eendy/upscale-models/resolve/main/4xFaceUpDAT.pth \
    --relative-path models/upscale_models \
    --filename 4xFaceUpDAT.pth
