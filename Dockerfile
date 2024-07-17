##### Dockerfile #####
## build stage ##
FROM node:18.18-alpine as build

WORKDIR /app
COPY . .
RUN npm install

RUN npm run build

## run stage ##
FROM nginx:alpine

RUN adduser -D dashboard

COPY --from=build /app/build /usr/share/nginx/html

RUN chown -R dashboard:dashboard /usr/share/nginx/html

USER dashboard

COPY nginx.conf /etc/nginx/conf.d/default.conf

# EXPOSE 80
# CMD ["nginx", "-g", "daemon off;"]
