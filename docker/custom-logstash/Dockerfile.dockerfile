# Use the official Logstash image as base
FROM docker.elastic.co/logstash/logstash:8.12.0

# Copy your pipeline configuration (logstash.conf)
COPY logstash.conf /usr/share/logstash/pipeline/logstash.conf

# Optional: Add custom plugins here
# RUN logstash-plugin install logstash-filter-json

# Set the working directory
WORKDIR /usr/share/logstash

# Default command
CMD ["logstash"]
