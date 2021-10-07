#FROM node:14
FROM 732156313306.dkr.ecr.eu-central-1.amazonaws.com/node:14

# Setting working directory. All the path will be relative to WORKDIR
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./

RUN npm install
RUN npm install express --save
RUN npm install config --save

# Bundle app source
COPY . .

EXPOSE 3000
CMD [ "node", "index.js" ]