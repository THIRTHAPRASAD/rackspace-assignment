# Sample PHP SQL Docker Application

I took a PHP (8.0 version) and mysql (8.0 version) application, which displays simple data table fetches from mysql DB in the browser on port 8001.
<img src="./../lamp-infra/ansible/screen.png"  />

## Application Deployment on local environment

**pre-requisities**
1. docker runtime
2. docker compose

**Application deployment**
* Clone github repo


* Deploying appication and db containers
    1. for stage environment
    ```shell
    docker-compose build && docker-compose --env-file .env-stage up -d
    ```
    2. for prod environment
    ```shell
    docker-compose build && docker-compose --env-file .env-prod up -d
    ```
## Application Deployment on AWS environment

**pre-requisities**
1. AWS account
2. AWS IAM user 
3. terraform
4. ansible

* Clone github repo


* build infra
    ```shell
    cd lamp-infra
    terraform init
    terraform plan
    terraform apply
    ```

* deploying application using ansible on aws infra
    1. prepare hosts file with by listing the instance IP address and key file
        ```shell
        [all]     # list the IP/DNS addresses of the VMs to deploy VM Enforcer
        10.0.0.1       ansible_ssh_private_key_file=~/.ssh/test-key    ansible_user=test-user
        10.0.0.x       ansible_ssh_private_key_file=~/.ssh/test-key
        test.aqua.com  ansible_user=test-user
        ```
    2. deploy application on the hosts
        ```shell
        cd ansible
        ansible-playbook lamp-app.yaml -e env=prod --vault-password-file pass -vv
        ```