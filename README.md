# Deploy-Next Toolkit Powered By Schwekas IT GmbH

### What Is Deploy-Next Toolkit?

Essentially it is a self-hosted alternative to Vercel. It makes remote deployment of NextJS Apps almost effortless. This Project comes with TailwindCSS, GraphQL, Apollo & Directus as headless API. But you can modify this base Project to your Stack as you see fit. It uses GitLab as a command center to deploy anything you want, to any server you have configured via GitLab's integrated CI and Pipelines.

### Features

- Setup a Master Server with GitLab
- Setup unlimited Slave Servers for deployment
- Fully integrated DevOps with GitLab CI Pipeline
- Local development environment
- Automagically deploy your Projects to Master or Slave Servers
- Generate LetsEncrypt Certificates for your Domains with ease

### Developer Prerequisites

1. Install NodeJS on your Computer (Yes, thats it :D)

### Project Installation

Just use the regular create-next-app utility with the `-e` flag to create a new next project.

```shell
$ yarn create next-app -e https://github.com/Schwekas-IT-GmbH/Deploy-Next
$ cd your_project
$ yarn dev
```

After that your project should be running already and you will see the NextJS Sample Page.
Before you can connect to your Directus GraphQL Database though, you will have to follow the
steps outlines below to establish a master-server with GitLab, that will handle the CI pipeline
instructions and spin up your staging and production environment in docker and the specified server.

> Note: we opted against a local database version as - for us - it does not make sense for every developer
> to have their own database with testdata.

### Benefits

Things that you will **NO LONGER** have to to:

- SSHing into a Server when deploying or updating a project
- Configuring git on a server to pull a project
- Install NGINX, or NodeJS, Certbot
- Configure NGINX and Certbot

What's left for you to do:

1. Create this repo with `create next-app`
2. Develop the actual Project
3. *(Once) Run the Master-Server setup and configure your GitLab*
4. Point DNS Records to the production/staging server
5. Push this to production/staging branch to deploy


### Deploying your Code to Staging / Production

The beauty of this project is the autodeployment. Any time you want to deploy your code to your staging or production environment, all you need to do is push your changes to the according branch. At that point GitLab will start the CI Pipelines, run tests and start the deployment on the server you specified (See GIT CI Variables below)

### Branches

This project assumes at least 3 Branches. "production" pushes to code to the production server and updates the application. "staging" pushes the code to a staging server and "development" (or any other branch name) is used for regular pushes and automated CI testing.

### GIT CI Variables

For staging and production to work correctly you have to supply some GIT CI-Variables for the Docker Container with some vital information. Every CI Variable can be set in the GIT Group as parent, so you only need to overwrite specific Variables when needed. That way for example all staging DBs (as they should not contain sensitive Data) could use the same credentials. `STAGE_DOMAIN` and `PROD_DOMAIN` however need to be unique and need to be pointing to the actual Server for LetsEncrypt to be able to create certificates.

> All of these Variables have to be supplied somewhere. As mentioned before that can be either in GitLab Project, GitLab Group, or the ci.yml File.

See the `.gitlab-ci.yml` file for a reference of the available variables

### Master Server Setup

> A running copy of GitLab is needed for this Toolkit. That's why the Master Server Setup includes an Installation of GitLab CE. If you do not already have a working GitLab, you have to set this up once!

1. Get yourself a Debian 10 Server with SSH

   > This works with any hosting provider
   >
2. Choose a Domain for your GitLab Installation and point its A-Record to the new Server

   > Be sure, that DNS has propagated before running the Setup
   >
3. Run the Master Server Setup by typing

   ```bash
   $ export GIT_SERVER_DOMAIN="your.gitlab_domain.com"
   $ sudo curl -s -L https://raw.githubusercontent.com/Schwekas-IT-GmbH/Deploy-Next/main/scripts/server_setup_master_w_GitLab.sh | bash
   ```

   > By this point your Server will be fully equiped with:
   > NGINX: A fast reverse proxy webserver
   > DOCKER: A container service that keeps every project sandboxed
   > GITLAB-RUNNER: The CI runner that makes the GIT pipelines work
   > PORTAINER: A web-based docker container manager (View Logs, Start/Stop, Shell)
   > LETSENCRYPT: Automatically validates your domains for SSL
   > GITLAB: A complete GitLab installation
   >
4. Wait until all Docker Containers are up and running

   > This usually takes about 5-15 Minutes, depending on server performance
   >
5. Go to http://your_ip:42069 and create an Admin Account for Portainer

   > With portainer, you can view all your running containers, stop and start them, as well as view their logs and access a remote shell. **Note: Be quick with setting up your Account or the installation could be hijacked**
   >
6. In Portainer, find the GitLab Container and access its Shell

   > Click on "local" Docker Endpoint > Containers > GitLab > Quick Actions > Exec Console > root
   >
7. Execute the following Command to set your intial Root-Password for GitLab

   ```bash
   $ gitlab-rails console -e production
   > user = User.where(id: 1).first
   > user.password = 'secret_pass'
   > user.password_confirmation = 'secret_pass'
   > user.save!
   ```
8. Access your newly created GitLab Instance which should be running on your specified Domain

   > If not, check the NIGNX and GitLab Logs via Portainer
   >
9. Register the Master Server as your first Gitlab-Runner

   > See "Register Gitlab-Runner" for more Information
   >

### Runner-Only Setup

> Should you want to deploy your projects on more than one Server, follow these Steps to create another Deployment/Staging server instance.

1. Get yourself a Debian 10 Server with SSH

   > This works with any hosting provider
   >
2. Run the Master Server Setup by typing

   ```bash
   $ sudo curl -s -L https://raw.githubusercontent.com/Schwekas-IT-GmbH/Deploy-Next/main/scripts/server_setup_pure_runner.sh | bash
   ```

   > By this point your Server will be fully equiped with:
   > NGINX: A fast reverse proxy webserver
   > DOCKER: A container service that keeps every project sandboxed
   > GITLAB-RUNNER: The CI runner that makes the GIT pipelines work
   > PORTAINER: A web-based docker container manager (View Logs, Start/Stop, Shell)
   > LETSENCRYPT: Automatically validates your domains for SSL
   >
3. Go to http://your_ip:42069 and create an Admin Account for Portainer

   > With portainer, you can view all your running containers, stop and start them, as well as view their logs and access a remote shell. **Note: Be quick with setting up your Account or the installation could be hijacked**
   >
4. Register the Slave Server with Gitlab

   > See "Register Gitlab-Runner" for more Information
   >

### Register Gitlab-Runner

GitLab-Runners are responsible for deploying your GIT projects onto a staging or production environment. It is recommended to have 3 runners tagged `production`, `staging` & `test`. Although you can name them whatever you want. You can also have mutliple production and deployment servers with different names, for example `deploy1` `deploy2`, etc. It is also recommended to setup GitLab Groups and register the runners only on groups where they are actually used.

1. Go to your GitLab Instance
2. Create a new Group
3. Go to Runner Settings of this Group

   > Group > Settings > CI/CD > Runners
   >
4. Run `$ gitlab-runner register`

   > **Note**: The server setup scripts run this command on their own. Though as it is the last command you can safely abort the server setup by that point and return to the registration later by running the register command manually.
   >
5. Enter the GitLab Credentials (URL and Token) displayed on your "Runners" Tab in GitLab
6. Choose a unique name for your runner

   > We recommend using the server ip with underlines you can easily reference it later like so `1_1_1_1`
   >
7. Choose the runners tags

   > This is an important step! The tags are responsible for addressing this runner via GitLab! If you are using Cloudflare Autoprovision, this will also be part of the CNAME Entry that is automatically created.
   >

   > **Note**: You can use multiple tags by using `,` as a seperator. This can be useful if you only want to use one server at first but do plan to scale it later. That way you do not have to change your project settings afterwards. The only thing you would need to change to deploy projects to a different server, is the runner tags. You can do this easily via the GitLab Runner Tab, once the runner is registered. For example, if you want your Master Server to handle testing, deployment and production you would use the following tag: `production,staging,test`
   >
8. Choose `shell` as its executor
