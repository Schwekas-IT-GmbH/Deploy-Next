# JamStrapper Toolkit powered by Schwekas IT GmbH

This project aims to automate the repetitive task of creating a new project and setting up servers do deploy them.




## Install the NextJS Client for this Project




## Features

- Setup a Master Server with GitLab
- Setup unlimited Slave Servers for deployment
- Automatic Cloudflare DNS Provisioning
- Automatically create new Projects via Bash/GitBash
- Fully integrated DevOps with GitLab CI Pipeline
- Local development environment using Docker
- Automagically deploy your Projects to Master or Slave Servers
- Generate LetsEncrypt Certificates





## Description


```
// TODO
```





## Getting started


#### Master Server Setup

> A running copy of GitLab is needed for this Toolkit. That's why the Master Server Setup includes an Installation of GitLab CE. If you do not already have a working GitLab, you have to set this up once!

1. Get yourself a Debian 10 Server with SSH
    > This works with any hosting provider
2. Choose a Domain for your GitLab Installation and point its A-Record to the new Server
    > Be sure, that DNS has propagated before running the Setup
3. Run the Master Server Setup by typing
    ```bash
    $ export GIT_SERVER_DOMAIN="your.gitlab_domain.com"
    $ sudo curl -s -L https://git.schwekas.com/schwekas-it-gmbh/jamstrapper/-/raw/main/server_setup_master_w_GitLab.sh | bash
    ```
    > By this point your Server will be fully equiped with:
    NGINX: A fast reverse proxy webserver
    DOCKER: A container service that keeps every project sandboxed
    GITLAB-RUNNER: The CI runner that makes the GIT pipelines work
    PORTAINER: A web-based docker container manager (View Logs, Start/Stop, Shell)
    LETSENCRYPT: Automatically validates your domains for SSL
    GITLAB: A complete GitLab installation
4. Wait until all Docker Containers are up and running
    > This usually takes about 5-15 Minutes, depending on server performance
5. Go to http://your_ip:42069 and create an Admin Account for Portainer
    > With portainer, you can view all your running containers, stop and start them, as well as view their logs and access a remote shell. **Note: Be quick with setting up your Account or the installation could be hijacked**
6. In Portainer, find the GitLab Container and access its Shell
    > Click on "local" Docker Endpoint > Containers > GitLab > Quick Actions > Exec Console > root 
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
9. Register the Master Server as your first Gitlab-Runner
    > See "Register Gitlab-Runner" for more Information

#### Runner-Only Setup
> Should you want to deploy your projects on more than one Server, follow these Steps to create another Deployment/Staging server instance.
1. Get yourself a Debian 10 Server with SSH
    > This works with any hosting provider
2. Run the Master Server Setup by typing
    ```bash
    $ sudo curl -s -L https://git.schwekas.com/schwekas-it-gmbh/jamstrapper/-/raw/main/server_setup_pure_runner.sh | bash
    ```
    > By this point your Server will be fully equiped with:
    NGINX: A fast reverse proxy webserver
    DOCKER: A container service that keeps every project sandboxed
    GITLAB-RUNNER: The CI runner that makes the GIT pipelines work
    PORTAINER: A web-based docker container manager (View Logs, Start/Stop, Shell)
    LETSENCRYPT: Automatically validates your domains for SSL
3. Go to http://your_ip:42069 and create an Admin Account for Portainer
    > With portainer, you can view all your running containers, stop and start them, as well as view their logs and access a remote shell. **Note: Be quick with setting up your Account or the installation could be hijacked**
4. Register the Slave Server with Gitlab
    > See "Register Gitlab-Runner" for more Information





## Register Gitlab-Runner

GitLab-Runners are responsible for deploying your GIT projects onto a staging or production environment. It is recommended to have 3 runners tagged `production`, `staging` & `test`. Although you can name them whatever you want. You can also have mutliple production and deployment servers with different names, for example `deploy1` `deploy2`, etc. It is also recommended to setup GitLab Groups and register the runners only on groups where they are actually used. 

1. Go to your GitLab Instance
2. Create a new Group
3. Go to Runner Settings of this Group
    > Group > Settings > CI/CD > Runners
4. Run `$ gitlab-runner register`
    > **Note**: The server setup scripts run this command on their own. Though as it is the last command you can safely abort the server setup by that point and return to the registration later by running the register command manually.
5. Enter the GitLab Credentials (URL and Token) displayed on your "Runners" Tab in GitLab
6. Choose a unique name for your runner
    > We recommend using the server ip with underlines you can easily reference it later like so `1_1_1_1`
7. Choose the runners tags
    > This is an important step! The tags are responsible for addressing this runner via GitLab! If you are using Cloudflare Autoprovision, this will also be part of the CNAME Entry that is automatically created.

    > **Note**: You can use multiple tags by using `,` as a seperator. This can be useful if you only want to use one server at first but do plan to scale it later. That way you do not have to change your project settings afterwards. The only thing you would need to change to deploy projects to a different server, is the runner tags. You can do this easily via the GitLab Runner Tab, once the runner is registered. For example, if you want your Master Server to handle testing, deployment and production you would use the following tag: `production,staging,test`
8. Choose `shell` as its executor





## Developer Installation (Manual)
There are two ways to create a new project. Either manual or automatic. The manual deployment required a bit more setup for each project.

1. Install Docker-Desktop for your OS
2. Install NodeJS on your Computer
3. Clone this Repo and run `$ npm run init`
    > **Important**: This command should only be run once, as it would overwrite files in your Workspace!
4. Rename sample.gitlab-ci.yml to .gitlab-ci.yml
5. Add Variables either in gitlab-ci.yml or in GitLab -> Settings -> CI -> Variables
    > See GIT CI Variables below. Every Variable has to be set somewhere! Either in `.gitlab-ci.yml`, GitLab Project Settings or GitLab Group Settings. The precedence of these Variables is: `.yml File < Group Settings < Project Settings`. You can use this to defines global Variables in the Group, that will be overwritten with Project specific Variables that will be overwritten.





## Developer Installation (Automatic)

This is the automatic setup that will interactively ask you about your disired Domains and create everything for you. That includes Cloudflare DNS Entries, the new GitLab Project & CI Variables for the specific Domains

1. Download the Autoprovision Script
    > This works in regular Bash and GitBash on Windows as well
2. Edit the Autoprovision Script
    > You can set defaults for your Variables, so you the only two entries you would have to make interactively are the stage and production domains.
3. For each new project you want to create, run the script and follow the instructions.





## Working with JamStrapper locally

By running `$ npm run init` the Toolkit will initially start the development environment for you. If you want to restart or start a different projects dev environment, run `$ npm run dev`.

> Important Note: You can only run one of these Environments at once, as they can't share a Port!

## Deploying your Code to Staging / Production

The beauty of this project is the autodeployment. Any time you want to deploy your code to your staging or production environment, all you need to do is push your changes to the according branch. At that point GitLab will start the CI Pipelines, run tests and start the deployment on the server you specified (See GIT CI Variables below)

## Branches

This project assumes at least 3 Branches. "production" pushes to code to the production server and updates the application. "staging" pushes the code to a staging server and "development" (or any other branch name) is used for regular pushes and automated CI testing. This structure will
automatically be setup on `$ npm run init`

## GIT CI Variables



For staging and production to work correctly you have to supply some GIT CI-Variables for the Docker Container with some vital information. Every CI Variable can be set in the GIT Group as parent, so you only need to overwrite specific Variables when needed. That way for example all staging DBs (as they should not contain sensitive Data) could use the same credentials. `STAGE_DOMAIN` and `PROD_DOMAIN` however need to be unique and need to be pointing to the actual Server for LetsEncrypt to be able to create certificates.

> All of these Variables have to be supplied somewhere. As mentioned before that can be either in GitLab Project, GitLab Group, or the ci.yml File.

| Variable |  Description |
| :------- | ------------ |
| STAGE_DOMAIN | The Domain of the Staging Server (xyz.domain.com) Note: this also creates an API Route api.xyz.domain.com! |
| STAGE_SQL_ROOT_PW | Root Password for the Stage SQL Server |
| STAGE_SQL_APP_PW | Application Password for the Stage SQL Server |
| | |
| PROD_DOMAIN | The Domain of the PRODUCTION Server (xyz.domain.com) Note: this also creates an API Route api.xyz.domain.com! |
| PROD_SQL_APP_PW | Root Password for the PRODUCTION SQL Server |
| PROD_SQL_ROOT_PW | Application Password for the PRODUCTION SQL Server |
| | |
| STAGE_SERVER | Specified on which Server the STAGE should be deployed. (Gitlab-Runner Tag) |
| PROD_SERVER  |  Specified on which Server the PRODUCTION should be deployed. (Gitlab-Runner Tag)  |
