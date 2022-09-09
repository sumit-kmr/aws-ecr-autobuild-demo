# pull the official base image (Background o.s for container)
#FROM node:17-alpine3.14

# RUN ls

FROM public.ecr.aws/lambda/nodejs:12
#FROM ubuntu
# RUN apt-get update
# RUN apt-get -y install npm
# RUN npm install -g yarn
# RUN npm install -g anypoint-cli@latest
# COPY my-script.sh "~/"
# COPY credentials "~/.anypoint/credentials"
# COPY index.js "/usr/local/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"
# RUN ["chmod", "+x", "~/my-script.sh"]
# ENTRYPOINT ["~/my-script.sh"]
####################################################################################################################

# First we pull the base image from DockerHub
#FROM amazon/aws-lambda-provided:al2

RUN npm install -g yarn
RUN npm install -g anypoint-cli@latest
COPY credentials "~/.anypoint/credentials"
COPY index.js "/usr/local/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"

# Copy our bootstrap and make it executable
WORKDIR /var/runtime/
COPY bootstrap bootstrap
RUN chmod 755 bootstrap

# Copy our function code and make it executable
WORKDIR /var/task/
COPY function.sh function.sh
RUN chmod 755 function.sh

# Set the handler
# by convention <fileName>.<handlerName>
CMD [ "function.sh.handler" ]