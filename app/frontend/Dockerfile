FROM node:18.20.2 AS build

WORKDIR /app

COPY package.json .

RUN npm install -g npm@10.5.0


COPY . .

RUN npm run build

FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]



# FROM node:18
# WORKDIR /app
# COPY package.json .
# RUN npm install
# COPY . .
# RUN npm run build
# EXPOSE 8080
# CMD ["npm", "run", "start"]