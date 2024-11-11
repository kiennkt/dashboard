##### Dockerfile #####
## build stage ##
FROM node:18.18-alpine as build

WORKDIR /app
COPY package.json nginx.conf
RUN npm install
COPY . .
RUN npm run build

## run stage ##
FROM nginx:alpine

RUN apk update && \
    apk upgrade --no-cache libcurl

RUN addgroup -S dashboard-app && adduser -S dashboard-app -G dashboard-app

COPY --from=build /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R dashboard-app:dashboard-app /usr/share/nginx/html && \
    # chown -R dashboard-app:dashboard-app /etc/nginx/conf.d/default.conf && \
    chown -R dashboard-app:dashboard-app /var/cache/nginx && \
    chown -R dashboard-app:dashboard-app /var/run/
USER dashboard-app

