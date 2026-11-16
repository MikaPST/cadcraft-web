FROM nginx:1.27-alpine
LABEL org.opencontainers.image.source="https://github.com/MikaPST/cadcraft-web" \
      org.opencontainers.image.description="Community-maintained CADCraft browser application"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/licenses/cadcraft/
RUN mkdir -p /var/cache/nginx /var/run/nginx /tmp/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/run/nginx /tmp/nginx /usr/share/nginx/html
USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
CMD ["nginx", "-g", "pid /tmp/nginx.pid; daemon off;"]
