# Generate htpasswd file and create Kubernetes secret
htpasswd -c auth user

# Create Kubernetes secret from the htpasswd file
kubectl create secret generic giropops-senhas-users --from-file=auth
