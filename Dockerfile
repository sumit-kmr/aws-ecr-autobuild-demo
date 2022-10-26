FROM ubuntu
RUN apt-get update
RUN apt-get install -y ntpdate
RUN apt-get install -y libssl-dev
RUN apt-get install -y curl
RUN apt-get install -y npm

# Download and configure anypoint-cli
RUN npm install -g yarn
RUN npm install -g anypoint-cli@latest
COPY index.js "/usr/local/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"

# Get args from build and set env variables
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION
ARG ANYPOINT_USERNAME
ARG ANYPOINT_PASSWORD
ENV AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_REGION=$AWS_REGION
ENV ANYPOINT_USERNAME=$ANYPOINT_USERNAME
ENV ANYPOINT_PASSWORD=$ANYPOINT_PASSWORD
ENV ANYPOINT_ORG='C4E'
ENV ANYPOINT_ENV='Sandbox'

# Copy the script and make it executable
COPY lambda_fun.sh "~/"
COPY aws4.js ${LAMBDA_RUNTIME_DIR}
COPY lru.js ${LAMBDA_RUNTIME_DIR}
COPY signature_v4_util.js ${LAMBDA_RUNTIME_DIR}
RUN ["chmod", "+x", "~/lambda_fun.sh"]
ENTRYPOINT ["~/lambda_fun.sh"]