FROM nginxinc/nginx-unprivileged:1.17.2-alpine
# Note that .dockerignore excludes all development files
COPY . /usr/share/nginx/html/