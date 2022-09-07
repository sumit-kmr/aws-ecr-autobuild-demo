# pull the official base image (Background o.s for container)
# FROM node:17-alpine3.14

# RUN ls

FROM public.ecr.aws/lambda/nodejs:12
RUN npm install
RUN npm install -g yarn
RUN npm install -g anypoint-cli@latest
COPY my-script.sh ${LAMBDA_TASK_ROOT}
RUN ["chmod", "+x", "/var/task/my-script.sh"]
ENTRYPOINT ["/var/task/my-script.sh"]