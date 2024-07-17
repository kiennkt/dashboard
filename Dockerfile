##### Dockerfile #####
## build stage ##
FROM node:18.18-alpine as build

WORKDIR /app
COPY . .
RUN npm install && \
    npm run build

## run stage ##
FROM nginx:alpine

RUN adduser -D dashboard

RUN chown -R dashboard:dashboard /usr/share/nginx/html && \
    chown -R dashboard:dashboard /var/cache/nginx && \
    chown -R dashboard:dashboard /etc/nginx/conf.d/default.conf

USER dashboard

COPY --from=build /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf
# CMD ["nginx", "-g", "daemon off;"]
