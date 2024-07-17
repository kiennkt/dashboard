##### Dockerfile #####
## build stage ##
FROM node:18.18-alpine as build

WORKDIR /app
COPY . .
RUN npm install && \
    npm run build

## run stage ##
FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf
# CMD ["nginx", "-g", "daemon off;"]
