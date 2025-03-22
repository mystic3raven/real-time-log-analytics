import os
import json
import time
import socket
from kafka import KafkaProducer

# === Configuration ===
KAFKA_BROKER = os.getenv("KAFKA_BROKER", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "logs")
LOG_SOURCE_FILE = os.getenv("LOG_SOURCE_FILE", "/var/log/syslog")  # Customize per OS
HOSTNAME = socket.gethostname()

# === Kafka Producer Setup ===
producer = KafkaProducer(
    bootstrap_servers=KAFKA_BROKER,
    value_serializer=lambda v: json.dumps(v).encode("utf-8")
)

# === Function: Tail a file like 'tail -F' ===
def tail_file(filename):
    with open(filename, "r") as f:
        f.seek(0, 2)  # Move to EOF
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.1)
                continue
            yield line.strip()

# === Function: Enrich log entry ===
def enrich_log(line):
    return {
        "host": HOSTNAME,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "log": line
    }

# === Main loop ===
def stream_logs():
    print(f"[INFO] Streaming logs from {LOG_SOURCE_FILE} to Kafka topic '{KAFKA_TOPIC}' at {KAFKA_BROKER}")
    for line in tail_file(LOG_SOURCE_FILE):
        log_entry = enrich_log(line)
        producer.send(KAFKA_TOPIC, log_entry)
        print(f"[DEBUG] Sent: {log_entry}")

if __name__ == "__main__":
    try:
        stream_logs()
    except KeyboardInterrupt:
        print("\n[INFO] Stopped by user.")
    except Exception as e:
        print(f"[ERROR] {e}")
