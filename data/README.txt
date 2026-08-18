This directory holds the large generated inputs for B5 (regex) and B8 (JSON).
They are NOT shipped (≈160 MB). Generate them once before running B5/B8:

    python3 harness/generate_data.py

This creates regex_input.txt (~61 MB) and json_input.json (~100 MB) here.
B6 creates and deletes its own 4 GB scratch file at run time.
