# alarastudios/comfyui-chroma-pulid
# Custom nodes only — models live on Network Volume
FROM runpod/worker-comfyui:5.1.0-base

# Install build tools first (needed for insightface C++ extensions)
RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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

# Install insightface with Cython (needs build-essential for C++ extensions)
# Using latest insightface + patching PuLID to work without providers kwarg
RUN pip install Cython numpy && \
    pip install insightface onnxruntime-gpu && \
    python3 -c "from insightface.app import FaceAnalysis; print('insightface OK')" && \
    python3 -c "import onnxruntime; print('onnxruntime OK, providers:', onnxruntime.get_available_providers())"

# Check what version of insightface was installed and if it accepts providers
RUN python3 -c "
import insightface
print(f'insightface version: {insightface.__version__}')
import inspect
from insightface.app import FaceAnalysis
sig = inspect.signature(FaceAnalysis.__init__)
print(f'FaceAnalysis.__init__ params: {list(sig.parameters.keys())}')
sig2 = inspect.signature(FaceAnalysis.prepare)
print(f'FaceAnalysis.prepare params: {list(sig2.parameters.keys())}')
"

# Patch PuLID if needed — make providers work regardless of insightface version
COPY patch_pulid.py /tmp/patch_pulid.py
RUN python3 /tmp/patch_pulid.py && rm /tmp/patch_pulid.py

# Download InsightFace antelopev2 model (needed by PuLID face detection)
# Zip contains antelopev2/ subfolder, so extract to parent dir
RUN mkdir -p /comfyui/models/insightface/models && \
    wget -O /tmp/antelopev2.zip "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" && \
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/antelopev2.zip').extractall('/comfyui/models/insightface/models/')" && \
    rm /tmp/antelopev2.zip

# Download PuLID model into the image (custom path not mapped from volume)
RUN mkdir -p /comfyui/models/pulid && \
    wget -O /comfyui/models/pulid/pulid_flux_v0.9.0.safetensors \
    "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.0.safetensors"

# Verify everything is in place
RUN grep -A10 "def load_insightface" /comfyui/custom_nodes/ComfyUI-PuLID-Flux-Chroma/pulidflux.py && \
    echo "✅ Patch verified" && \
    ls -la /comfyui/models/insightface/models/antelopev2/ && \
    echo "✅ AntelopeV2 models verified" && \
    ls -la /comfyui/models/pulid/ && \
    echo "✅ PuLID model verified"
