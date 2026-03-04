"""Patch PuLID InsightFace loader for compatibility with various insightface versions"""
import re

target = "/comfyui/custom_nodes/ComfyUI-PuLID-Flux-Chroma/pulidflux.py"

with open(target, "r") as f:
    content = f.read()

# Replace the entire load_insightface method
old = '''    def load_insightface(self, provider):
        model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR, providers=[provider + 'ExecutionProvider',]) # alternative to buffalo_l
        model.prepare(ctx_id=0, det_size=(640, 640))

        return (model,)'''

# insightface FaceAnalysis.__init__ accepts **kwargs which passes providers
# to model_zoo.get_model(). prepare() does NOT accept providers.
# Add verbose logging so we can see what's happening on RunPod.
new = '''    def load_insightface(self, provider):
        import traceback as tb
        prov = [provider + 'ExecutionProvider', 'CPUExecutionProvider']
        print(f"[PuLID] Loading InsightFace with providers={prov}")
        print(f"[PuLID] INSIGHTFACE_DIR={INSIGHTFACE_DIR}")
        import os
        model_dir = os.path.join(INSIGHTFACE_DIR, 'models', 'antelopev2')
        if os.path.exists(model_dir):
            print(f"[PuLID] Model dir contents: {os.listdir(model_dir)}")
        else:
            print(f"[PuLID] WARNING: Model dir does not exist: {model_dir}")
        try:
            model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR, providers=prov)
        except Exception as e:
            print(f"[PuLID] FaceAnalysis init error: {type(e).__name__}: {e}")
            tb.print_exc()
            raise
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
