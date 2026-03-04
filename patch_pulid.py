"""Patch PuLID InsightFace loader for compatibility with insightface versions that don't accept providers"""
import re

target = "/comfyui/custom_nodes/ComfyUI-PuLID-Flux-Chroma/pulidflux.py"

with open(target, "r") as f:
    content = f.read()

old = '''    def load_insightface(self, provider):
        model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR, providers=[provider + 'ExecutionProvider',]) # alternative to buffalo_l
        model.prepare(ctx_id=0, det_size=(640, 640))

        return (model,)'''

# Set providers globally via onnxruntime session options before creating FaceAnalysis
new = '''    def load_insightface(self, provider):
        import onnxruntime
        # Set default providers globally since this insightface version doesn't accept providers kwarg
        available = onnxruntime.get_available_providers()
        print(f"[PuLID] Available ONNX providers: {available}")
        print(f"[PuLID] Requested provider: {provider}")
        print(f"[PuLID] INSIGHTFACE_DIR: {INSIGHTFACE_DIR}")
        import os
        model_dir = os.path.join(INSIGHTFACE_DIR, 'models', 'antelopev2')
        if os.path.exists(model_dir):
            print(f"[PuLID] Model files: {os.listdir(model_dir)}")
        else:
            print(f"[PuLID] WARNING: dir missing: {model_dir}")
        # Create FaceAnalysis without providers kwarg
        model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR)
        model.prepare(ctx_id=0, det_size=(640, 640))
        print("[PuLID] InsightFace loaded successfully")
        return (model,)'''

if old in content:
    content = content.replace(old, new)
    with open(target, "w") as f:
        f.write(content)
    print("PATCHED successfully")
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
