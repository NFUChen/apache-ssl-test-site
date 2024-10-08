# Use the official Apache HTTP Server image
FROM httpd:2.4

# Install OpenSSL
RUN apt-get update && apt-get install -y openssl

# Copy the custom Apache configuration files
COPY apache.conf /usr/local/apache2/conf/extra/apache-ssl.conf
COPY ssl-modules.conf /usr/local/apache2/conf/extra/ssl-modules.conf

# Include the custom configurations in the default httpd.conf
RUN echo "Include conf/extra/ssl-modules.conf" >> /usr/local/apache2/conf/httpd.conf
RUN echo "Include conf/extra/apache-ssl.conf" >> /usr/local/apache2/conf/httpd.conf

# Create directories for the certificates
RUN mkdir -p /etc/ssl/certs /etc/ssl/private

# Generate the CA private key and certificate
RUN openssl genrsa -out /etc/ssl/private/ca.key 2048 && \
    openssl req -x509 -new -nodes -key /etc/ssl/private/ca.key -sha256 -days 365 -out /etc/ssl/certs/ca.crt -subj "/C=SR/ST=KG/O=trendmicro-test/OU=trendmicro-test/CN=localhost"

# Generate the server private key and certificate signing request (CSR)
RUN openssl genrsa -out /etc/ssl/private/server.key 2048 && \
    openssl req -new -key /etc/ssl/private/server.key -out /etc/ssl/certs/server.csr -subj "/C=SR/ST=KG/O=trendmicro-test/OU=trendmicro-test/CN=localhost"

# Sign the server CSR with the CA certificate to create the server certificate
RUN openssl x509 -req -in /etc/ssl/certs/server.csr -CA /etc/ssl/certs/ca.crt -CAkey /etc/ssl/private/ca.key -CAcreateserial -out /etc/ssl/certs/server.crt -days 365 -sha256

# Expose port 443
EXPOSE 443

# Start Apache in the foreground
CMD ["httpd-foreground"]