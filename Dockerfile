FROM ghcr.io/nginxinc/nginx-unprivileged:stable-alpine-slim

COPY ./html /usr/share/nginx/html

EXPOSE 8080
