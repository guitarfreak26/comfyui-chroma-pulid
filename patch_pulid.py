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

new = '''    def load_insightface(self, provider):
        prov = [provider + 'ExecutionProvider', 'CPUExecutionProvider']
        try:
            # Newer insightface: providers in __init__
            model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR, providers=prov)
        except TypeError:
            # Even newer insightface: no providers in __init__, pass to prepare()
            model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR)
        model.prepare(ctx_id=0, det_size=(640, 640), providers=prov)

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
