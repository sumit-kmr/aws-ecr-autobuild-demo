# FROM public.ecr.aws/lambda/nodejs:12
# FROM node:17-alpine3.14
# FROM public.ecr.aws/docker/library/ubuntu:18.04
FROM ubuntu
RUN apt-get update
RUN apt-get install -y libssl-dev
RUN apt-get install -y curl
RUN apt-get install -y npm
# RUN apk update
# RUN apk add --update curl
# RUN apk add --update openssl

# Download and configure anypoint-cli
# RUN npm install -g yarn
# RUN npm install -g anypoint-cli@latest
# COPY credentials "~/.anypoint/credentials"
# COPY index.js "/var/lang/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"

# ARG AWS_ACCESS_KEY_ID
# ARG AWS_SECRET_ACCESS_KEY
# ARG AWS_REGION
# ENV AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID
# ENV AWS_SECRET_KEY=$AWS_SECRET_ACCESS_KEY
# ENV AWS_REGION=$AWS_REGION

# Copy our bootstrap and make it executable
# WORKDIR /var/runtime/
# COPY bootstrap bootstrap
# RUN chmod 755 bootstrap

# Copy our function code and make it executable
# WORKDIR /var/task/
# COPY function.sh function.sh
# RUN chmod 755 function.sh
# RUN npm install crypto-js
# CMD [ "function.sh.handler" ]


COPY function.sh "~/"
COPY s3-get.sh "~/"
COPY credentials "~/.anypoint/credentials"
RUN ["chmod", "+x", "~/function.sh"]
RUN ["chmod", "+x", "~/s3-get.sh"]
ENTRYPOINT ["~/function.sh"]