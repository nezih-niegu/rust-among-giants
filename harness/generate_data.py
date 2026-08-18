#!/usr/bin/env python3
"""Generate test data for benchmarks B5 (regex) and B8 (JSON)."""
import random
import json
import os

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# === B5: Regex input (1M lines, ~30% contain emails) ===
print("Generating regex_input.txt (1M lines)...")
random.seed(42)
domains = ["gmail.com", "yahoo.com", "outlook.com", "company.org", "university.edu"]
words = ["hello", "world", "the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog",
         "benchmark", "performance", "testing", "language", "programming", "rust", "python"]

with open(os.path.join(DATA_DIR, "regex_input.txt"), "w") as f:
    for i in range(1_000_000):
        if random.random() < 0.3:
            # Line with email
            name = random.choice(words) + str(random.randint(1, 999))
            domain = random.choice(domains)
            prefix = " ".join(random.choices(words, k=random.randint(2, 8)))
            suffix = " ".join(random.choices(words, k=random.randint(0, 5)))
            f.write(f"{prefix} {name}@{domain} {suffix}\n")
        else:
            # Line without email
            line = " ".join(random.choices(words, k=random.randint(3, 15)))
            f.write(f"{line}\n")

size_mb = os.path.getsize(os.path.join(DATA_DIR, "regex_input.txt")) / (1024*1024)
print(f"  -> {size_mb:.1f} MB")

# === B8: JSON input (~100MB) ===
print("Generating json_input.json (~100MB)...")
random.seed(42)

def gen_record():
    return {
        "id": random.randint(1, 10_000_000),
        "name": " ".join(random.choices(words, k=2)),
        "email": f"{random.choice(words)}{random.randint(1,999)}@{random.choice(domains)}",
        "score": round(random.uniform(0, 100), 2),
        "active": random.choice([True, False]),
        "tags": random.choices(words, k=random.randint(1, 5)),
        "metadata": {
            "created": f"2024-{random.randint(1,12):02d}-{random.randint(1,28):02d}",
            "version": random.randint(1, 10),
            "notes": " ".join(random.choices(words, k=random.randint(5, 20))) if random.random() > 0.3 else None,
        }
    }

target_size = 100 * 1024 * 1024  # 100MB
records = []
current_size = 2  # for [ and ]
print("  Building records...")
while current_size < target_size:
    rec = gen_record()
    rec_json = json.dumps(rec)
    current_size += len(rec_json) + 2  # comma + newline
    records.append(rec)
    if len(records) % 100000 == 0:
        print(f"    {len(records)} records, ~{current_size/(1024*1024):.0f} MB")

print(f"  Writing {len(records)} records...")
with open(os.path.join(DATA_DIR, "json_input.json"), "w") as f:
    json.dump(records, f)

size_mb = os.path.getsize(os.path.join(DATA_DIR, "json_input.json")) / (1024*1024)
print(f"  -> {size_mb:.1f} MB")
print("Done!")
