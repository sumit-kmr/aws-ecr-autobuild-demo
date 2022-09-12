FROM public.ecr.aws/lambda/nodejs:12
# FROM ubuntu
# RUN apt-get update
# RUN apt-get install -y curl
# RUN apt-get install -y unzip
# RUN apt-get install -y npm

# Download and configure anypoint-cli
RUN npm install -g yarn
RUN npm install -g anypoint-cli@latest
COPY credentials "~/.anypoint/credentials"
COPY index.js "/var/lang/lib/node_modules/anypoint-cli/node_modules/home-dir/index.js"

# Download extract-zip
RUN npm install extract-zip -g

# Download and install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN extract-zip awscliv2.zip ~/
RUN ~/aws/install
COPY aws_credentials.csv "~/aws_credentials.csv"
#RUN aws configure import --csv "file://~/aws_credentials.csv"
# ARG AWS_ACCESS_KEY_ID=AKIA2ZOD6FY5L5FPWE65
# ARG AWS_SECRET_ACCESS_KEY=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
# ARG AWS_REGION=ap-south-1
#RUN aws s3 ls s3://anypoint-dlb-cert-bucket --no-verify-ssl

# Copy our bootstrap and make it executable
WORKDIR /var/runtime/
COPY bootstrap bootstrap
RUN chmod 755 bootstrap

# Copy our function code and make it executable
WORKDIR /var/task/
COPY function.sh function.sh
RUN chmod 755 function.sh
CMD [ "function.sh.handler" ]