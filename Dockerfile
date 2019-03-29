# Don't use official nginx because it runs as root
FROM bitnami/nginx:1.14.2
# Note that .dockerignore excludes all development files
COPY . /app/
