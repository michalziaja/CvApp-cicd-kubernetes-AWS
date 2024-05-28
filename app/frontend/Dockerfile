FROM node:18-alpine AS build

WORKDIR /app

COPY package.json .

RUN yarn install


COPY . .

RUN yarn run build

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