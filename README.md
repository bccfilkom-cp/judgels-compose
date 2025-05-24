<div align="center">  
  <img src="https://judgels.toki.id/img/logo.png" height="150" />
</div>

# Judgels Docker Compose

Simplified judgels deployment with docker compose without using the official ansible deployment guide.

## ⚙️ How to use

This docker-compose configuration requires you to prepare  1 core VM and N grader VM. 

- Core VM will be used to host the client, server, mysqldb and rabibtmq that can be spin up with containers defined in [docker-compose.yml](./docker-compose.yml). 
- Grader VM will be used to run the grader system. However, you can also run the grader on your local machine, as long as it has the SSH private key required to access the Core VM. The Core VM must already have the corresponding SSH public key added to its authorized_keys file to allow SSH access. You can spawn the grader container with [spawn-grader.sh](./spawn-grader.sh) shell script.

For more understanding about how this system works, please see the [architecture diagram](https://judgels.toki.id/assets/images/judgels-deployment-9e088b0e29ea99979220c04935214213.png) and [the concepts](https://judgels.toki.id/docs/deployment/concepts)

NOTES: Make sure Core VM and Grader VM already has docker installed!


1. Clone this repository in `Core VM`
```zsh
git clone https://github.com/bccfilkom-cp/judgels-compose.git
cd judgels-compose
```

2. Copy the `.env.example` file to `.env` and defined your credentials there
```zsh
copy .env.example .env
vim .env
```

3. Change the variables in [judgels-client.js](./conf/judgels-client.js) and [judgels-server.yml](./conf/judgels-server.yml) that marked as `CHANGE THIS` and change the rabbitmq port forwarding in [docker-compose.yml](./docker-compose.yml) for security purpose.

4. Now change the [core-deploy.sh](./core-deploy.sh) to be executeable
```zsh
chmod +x ./core-deploy.sh
```

5. Execute the bash script
```zsh
./core-deploy.sh
```

6. If all goes well, now we need to prepare the grader container, clone this repository again in `Grader VM`
```zsh
git clone https://github.com/bccfilkom-cp/judgels-compose.git
cd judgels-compose
```

7. Adjust the variables in [judgels-grader.yml](./conf/judgels-grader.yml)

8. Provision the Grader VM with [prov-grader.sh](./prov-grader.sh) bash script, execute it with sudo.

```zsh
chmod +x ./prov-grader.sh
sudo ./prov-grader.sh
```

9. After rebooting, add the Grader VM SSH pubkey to Core VM to allow Grader VM to SSH to Core VM
10. Spawn the grader containers with [spawn-grader.sh](./spawn-grader.sh) bash script. You can change how many containers you needed

```zsh
chmod +x ./spawn-grader.sh
./spawn-grader.sh
```

10. And that's all, you're good to go. The web client interface (User, Admin to create contest) can be accessed at `CORE_VM_IP` and the web admin interface (Admin to create problemsets) can be accessed at `CORE_VM_IP:9101` depends on the port forwarded in [docker-compose.yml](./docker-compose.yml) judgels-server container configuration