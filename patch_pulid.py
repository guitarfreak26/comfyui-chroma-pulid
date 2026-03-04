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
        import traceback
        prov = [provider + 'ExecutionProvider', 'CPUExecutionProvider']
        try:
            model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR, providers=prov)
        except TypeError:
            try:
                model = FaceAnalysis(name="antelopev2", root=INSIGHTFACE_DIR)
            except Exception as e2:
                print(f"[PuLID] FaceAnalysis init failed: {e2}")
                traceback.print_exc()
                raise
        model.prepare(ctx_id=0, det_size=(640, 640))

        return (model,)'''

if old in content:
    content = content.replace(old, new)
    with open(target, "w") as f:
        f.write(content)
    print("PATCHED successfully")
else:
    print("WARNING: exact match not found, trying regex")
    # Fallback regex
    pattern = r'def load_insightface\(self, provider\):.*?return \(model,\)'
    if re.search(pattern, content, re.DOTALL):
        content = re.sub(pattern, new.lstrip(), content, flags=re.DOTALL)
        with open(target, "w") as f:
            f.write(content)
        print("PATCHED via regex")
    else:
        print("ERROR: could not find load_insightface method")
