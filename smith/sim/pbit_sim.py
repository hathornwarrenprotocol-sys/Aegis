#!/usr/bin/env python3
import hashlib, json, random, sys
n = int(sys.argv[1]) if len(sys.argv) > 1 else 16
seed = sys.argv[2] if len(sys.argv) > 2 else "aegis"
rng = random.Random(int(hashlib.sha256(seed.encode()).hexdigest()[:8], 16))
print(json.dumps({"n": n, "seed": seed, "state": [rng.choice([0,1]) for _ in range(n)], "forge_class": "software"}))
