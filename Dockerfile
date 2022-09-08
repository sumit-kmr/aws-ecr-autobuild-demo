# pull the official base image (Background o.s for container)
#FROM node:17-alpine3.14

# RUN ls

#FROM public.ecr.aws/lambda/nodejs:12
FROM ubuntu
RUN apt-get update
RUN apt-get -y install npm
RUN npm install -g yarn
RUN npm install -g anypoint-cli@latest
COPY my-script.sh "~/"
COPY credentials "~/.anypoint/credentials"
COPY config_loader.js "/usr/local/lib/node_modules/anypoint-cli/src/config_loader.js"
RUN ["chmod", "+x", "~/my-script.sh"]
ENTRYPOINT ["~/my-script.sh"]