import requests
import json

r = requests.get("http://127.0.0.1:8188/object_info")
info = r.json()

target_nodes = [
    "CheckpointLoaderSimple",
    "AudioEncoderLoader",
    "LoadAudio",
    "SheetSage2AudioToABC",
    "YuE2GenerateABC",
    "YuE2GenerateMusic",
    "EmptyYuE2LatentAudio",
    "KSampler",
    "VAEDecodeAudioTiled",
    "SaveAudioAdvanced"
]

for name in target_nodes:
    if name in info:
        node_def = info[name]
        req_inputs = node_def.get("input", {}).get("required", {})
        opt_inputs = node_def.get("input", {}).get("optional", {})
        print(f"=== {name} ===")
        print("  Required:", list(req_inputs.keys()))
        print("  Optional:", list(opt_inputs.keys()))
        print("  Outputs:", node_def.get("output", []))
    else:
        print(f"MISSING: {name}")

