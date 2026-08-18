import threading
T, OPS = 8, 10_000_000
counter = 0
lock = threading.Lock()
def worker():
    global counter
    for _ in range(OPS):
        with lock:
            counter += 1
threads = [threading.Thread(target=worker) for _ in range(T)]
for t in threads: t.start()
for t in threads: t.join()
print(counter)
