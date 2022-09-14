FROM public.ecr.aws/lambda/nodejs:12
# FROM public.ecr.aws/docker/library/ubuntu:18.04
# FROM ubuntu
# RUN apt-get update
# RUN apt-get install -y libssl-dev
# RUN npm install -g curl@latest
# RUN apt-get install -y npm

# Download and configure anypoint-cli
# RUN npm install -g yarn
# RUN npm install -g anypoint-cli@latest
# COPY credentials "~/.anypoint/credentials"
# COPY index.js "/var/lang/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION
ENV awsAccessKey=$AWS_ACCESS_KEY_ID
ENV awsSecretKey=$AWS_SECRET_ACCESS_KEY
ENV awsRegion=$AWS_REGION

# Copy our bootstrap and make it executable
WORKDIR /var/runtime/
COPY bootstrap bootstrap
RUN chmod 755 bootstrap

# Copy our function code and make it executable
WORKDIR /var/task/
COPY function.sh function.sh
COPY signatureV4.js signatureV4.js
RUN chmod 755 function.sh
CMD [ "function.sh.handler" ]