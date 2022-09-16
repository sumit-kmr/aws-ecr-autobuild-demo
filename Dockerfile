FROM ubuntu
RUN apt-get update
RUN apt-get install -y ntpdate
RUN apt-get install -y libssl-dev
RUN apt-get install -y curl
RUN apt-get install -y npm

# Download and configure anypoint-cli
RUN npm install -g yarn
RUN npm install -g anypoint-cli@latest
COPY credentials "~/.anypoint/credentials"
COPY index.js "/usr/local/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"

# Get args from build and set env variables
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION
ENV AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_REGION=$AWS_REGION

# Copy the script and make it executable
COPY lambda_fun.sh "~/"
RUN ["chmod", "+x", "~/lambda_fun.sh"]
ENTRYPOINT ["~/lambda_fun.sh"]