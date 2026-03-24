# Create a certificate for the developer user
openssl genrsa -out developer.key 2048
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer"
# Encode the certificate in base64 format
cat developer.csr | base64 | tr -d '\n'

# Create a namespace for the development environment
kubectl create ns dev

# Create a certificate for the platform user
openssl genrsa -out platform.key 2048
openssl req -new -key platform.key -out platform.csr -subj "/CN=platform/O=platform"
# Encode the certificate in base64 format
cat platform.csr | base64 | tr -d '\n'

# Create a certificate for the admin user
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -subj "/CN=admin/O=admin"
# Encode the certificate in base64 format
cat admin.csr | base64 | tr -d '\n'