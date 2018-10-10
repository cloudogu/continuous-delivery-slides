FROM nginx
# Note that .dockerignore excludes all development files
COPY . /usr/share/nginx/html/
