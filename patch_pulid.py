"""Patch PuLID InsightFace loader to work with any insightface version"""
import re
import inspect
from insightface.app import FaceAnalysis

target = "/comfyui/custom_nodes/ComfyUI-PuLID-Flux-Chroma/pulidflux.py"

# Check if FaceAnalysis accepts providers
sig = inspect.signature(FaceAnalysis.__init__)
params = list(sig.parameters.keys())
has_kwargs = any(p.kind == inspect.Parameter.VAR_KEYWORD for p in sig.parameters.values())
accepts_providers = 'providers' in params or has_kwargs

print(f"insightface FaceAnalysis params: {params}")
print(f"accepts **kwargs: {has_kwargs}")
print(f"accepts providers: {accepts_providers}")

if accepts_providers:
    print("No patch needed — insightface accepts providers kwarg")
else:
    print("Patching — insightface does NOT accept providers kwarg")
    
    with open(target, "r") as f:
        content = f.read()
    
    old = '''    def load_insightface(self, provider):
        model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR, providers=[provider + 'ExecutionProvider',]) # alternative to buffalo_l
        model.prepare(ctx_id=0, det_size=(640, 640))

        return (model,)'''
    
    # Without providers kwarg, we need to set the default session options
    # onnxruntime will use available providers automatically (CUDA > CPU)
    new = '''    def load_insightface(self, provider):
        import onnxruntime
        import os
        print(f"[PuLID] Available ONNX providers: {onnxruntime.get_available_providers()}")
        print(f"[PuLID] INSIGHTFACE_DIR: {INSIGHTFACE_DIR}")
        model_dir = os.path.join(INSIGHTFACE_DIR, 'models', 'antelopev2')
        if os.path.exists(model_dir):
            print(f"[PuLID] Model files: {os.listdir(model_dir)}")
        else:
            print(f"[PuLID] WARNING: dir missing: {model_dir}")
        model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR)
        model.prepare(ctx_id=0, det_size=(640, 640))
        print("[PuLID] InsightFace loaded successfully")
        return (model,)'''
    
    if old in content:
        content = content.replace(old, new)
        with open(target, "w") as f:
            f.write(content)
        print("PATCHED successfully (exact match)")
    else:
        print("WARNING: exact match not found, trying regex")
        pattern = r'(    def load_insightface\(self, provider\):.*?return \(model,\))'
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, new, content, flags=re.DOTALL)
            with open(target, "w") as f:
                f.write(content)
            print("PATCHED via regex")
        else:
            print("ERROR: could not find load_insightface method")
