# Node Image
FROM node:lts-alpine

# Get Arguments
ARG API_DOMAIN

# Set app working dir
WORKDIR /app

# Copy Package
COPY package*.json ./

# Install Dep
RUN yarn install

# Copy Files from GIT into Container
COPY . .

# Create API ENVs
RUN echo "\nNEXT_PUBLIC_API_DOMAIN = https://${API_DOMAIN}\n" >> ./.env.production

# Build Static Pages
RUN yarn build

# RUN COMMANDS
EXPOSE 3000
ENTRYPOINT ["yarn"]
CMD ["start"]