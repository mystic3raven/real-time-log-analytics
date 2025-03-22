# Use the official Kibana image
FROM docker.elastic.co/kibana/kibana:8.12.0

# Optional: add custom configs or plugins
# COPY kibana.yml /usr/share/kibana/config/kibana.yml

# Set working directory
WORKDIR /usr/share/kibana

CMD ["bin/kibana"]
