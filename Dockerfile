# alarastudios/comfyui-chroma-pulid
# Chroma + PuLID + IPAdapter worker for RunPod Serverless
# Based on official ComfyUI worker base image
FROM runpod/worker-comfyui:5.1.0-base

# ============================================
# Custom Nodes
# ============================================
# PuLID for Flux/Chroma (face identity preservation)
RUN comfy-node-install ComfyUI-PuLID-Flux-Enhanced

# IPAdapter for Flux (body consistency)
RUN comfy-node-install x-flux-comfyui

# Advanced Vision (SigLIP2 loader)
RUN comfy-node-install ComfyUI-Advanced-Vision

# Easy Use (background removal, GPU cleanup)
RUN comfy-node-install comfyui-easy-use

# KJ Nodes (ControlNet type setter)
RUN comfy-node-install comfyui-kjnodes

# ControlNet Aux (DW Preprocessor for pose)
RUN comfy-node-install comfyui_controlnet_aux

# Essentials (SDXL latent size picker)
RUN comfy-node-install comfyui_essentials

# Tiny Terra Nodes (text nodes)
RUN comfy-node-install comfyui_tinyterranodes

# MultiGPU / GGUF loader
RUN comfy-node-install comfyui-multigpu

# ============================================
# Models - Checkpoints / UNET
# ============================================
# Chroma GGUF (Q8_0 quantized - fits in 24GB with all other models)
RUN comfy model download \
  --url https://huggingface.co/silveroxides/Chroma-GGUF/resolve/main/chroma-unlocked-v37-detail-calibrated/chroma-unlocked-v37-detail-calibrated-Q8_0.gguf \
  --relative-path models/diffusion_models/Chroma \
  --filename chroma-unlocked-v37-detail-calibrated-Q8_0.gguf

# ============================================
# Models - Text Encoder (CLIP / T5)
# ============================================
# T5-XXL fp16 (required for Chroma/Flux text encoding)
RUN comfy model download \
  --url https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors \
  --relative-path models/clip \
  --filename t5xxl_fp16.safetensors

# ============================================
# Models - VAE
# ============================================
# Flux VAE
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
# Models - IPAdapter
# ============================================
# Flux IPAdapter
RUN comfy model download \
  --url https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/ip_adapter.safetensors \
  --relative-path models/xlabs/ipadapters \
  --filename ip_adapter.safetensors

# CLIP Vision for IPAdapter
RUN comfy model download \
  --url https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors \
  --relative-path models/clip_vision \
  --filename clip-vit-large-patch14.safetensors

# ============================================
# Models - Advanced Vision (SigLIP2)
# ============================================
RUN comfy model download \
  --url https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors \
  --relative-path models/clip_vision \
  --filename siglip2-so400m-patch16-512.safetensors

# ============================================
# Models - LoRA (Speed)
# ============================================
RUN comfy model download \
  --url https://huggingface.co/clover-supply/Chroma-loras/resolve/main/Hyper-Chroma-low-step-LoRA.safetensors \
  --relative-path models/loras/Chroma \
  --filename Hyper-Chroma-low-step-LoRA.safetensors

# ============================================
# Models - Upscaler
# ============================================
RUN comfy model download \
  --url https://huggingface.co/eendy/upscale-models/resolve/main/4xFaceUpDAT.pth \
  --relative-path models/upscale_models \
  --filename 4xFaceUpDAT.pth

# ============================================
# Models - ControlNet (optional, disabled by default in workflow)
# ============================================
# Uncomment if you want pose control:
# RUN comfy model download \
#   --url https://huggingface.co/Shakker-Labs/FLUX.1-dev-ControlNet-Union-Pro-2.0/resolve/main/diffusion_pytorch_model.safetensors \
#   --relative-path models/controlnet/FLUX \
#   --filename FLUX.1-dev-ControlNet-Union-Pro-2.0.safetensors
