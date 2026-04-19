<div align="center">  
  <img src="https://judgels.toki.id/img/logo.png" height="150" />
</div>

# Judgels Docker Compose

Simplified judgels deployment with docker compose without using the official ansible deployment guide.

## ⚙️ How to use

This docker-compose configuration supports two deployment topologies:

- **Multi-VM** (recommended for production): 1 core VM + $N$ grader VMs. Graders fetch problem data from the core VM over SSH. Gives you resource isolation between the core services and the untrusted user code that graders sandbox. The steps below cover this setup.
- **Single-VM**: everything runs on one host. Graders read problem data via a local bind mount instead of SSH. Simpler to set up, but grader sandboxes share the host with the core DB/API — a sandbox escape has a larger blast radius. See [Single-VM deployment](#single-vm-deployment).

For multi-VM:

- Core VM will be used to host the React Client, Java Server, MySQL Database and RabbitMQ Message Broker that can be spin up with containers defined in [docker-compose.yml](./docker-compose.yml). 
- The Grader VM is used to run the grading system. You can also run the grader on your local machine, as long as it has the SSH private key that corresponds to the Grader VM’s public key. The Grader VM’s **SSH public key must be added to the Core VM’s `authorized_keys`** to allow SSH access. You can start the grader container using the `spawn-grader.sh` script.


For more understanding about how this system works, please see the [architecture diagram](https://judgels.toki.id/assets/images/judgels-deployment-9e088b0e29ea99979220c04935214213.png) and [the concepts](https://judgels.toki.id/docs/deployment/concepts) in the official judgels website.

> [!NOTE]   
> Make sure Core VM and Grader VM already has docker installed!


1. Clone this repository in `Core VM`
```zsh
git clone https://github.com/bccfilkom-cp/judgels-compose.git
cd judgels-compose
```

2. Copy the `.env.example` file to `.env` and defined your database and rabbitmq credentials there.
```zsh
cp .env.example .env
vim .env # or nano .env
```

3. Change the variables in [./conf/judgels-client.js](./conf/judgels-client.js) file and [./conf/judgels-server.yml](./conf/judgels-server.yml) that marked as `CHANGE THIS`. You can also change the rabbitmq port forwarding in [docker-compose.yml](./docker-compose.yml) for security purpose.

4. Now made [core-deploy.sh](./core-deploy.sh) bash script to be executeable by running the following command.
```zsh
chmod +x ./core-deploy.sh
```

5. Execute the bash script with sudo.
```zsh
sudo ./core-deploy.sh
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
sudo ./spawn-grader.sh
```

10. And that's all, you're good to go. You can access the web client interface (User and Admin for creating contests) at `CORE_VM_IP`, and the web admin interface (Admin for managing problemsets) at `CORE_VM_IP:9101`, depending on the ports defined in the judgels-server container of your [docker-compose.yml](./docker-compose.yml). To create a contest, log in as superadmin through the web client interface.

## Single-VM deployment

Runs the core services and graders on the same host. Use this for local development, small deployments, or when you don't need the isolation boundary that multi-VM provides.

> [!WARNING]
> Grader sandboxes will share the host with the core DB, API, and RabbitMQ. A sandbox escape from untrusted user code has a larger blast radius than in the multi-VM setup. Prefer multi-VM for production.

From the core VM, **after completing steps 1–5 from the multi-VM instructions above**:

1. Provision the host for the grader sandbox (kernel tuning, reboots at the end):

```zsh
chmod +x ./prov-grader.sh
sudo ./prov-grader.sh
```

2. Edit [./conf/judgels-grader.yml](./conf/judgels-grader.yml) and set:

```yaml
gabriel:
  cache:
    serverBaseDataDir: /judgels/server/var/data
```

No `user@host:` prefix. This is the path **inside the grader container** where the server data directory will be bind-mounted read-only. `rsyncIdentityFile` can be left at its default since rsync ignores the SSH transport when both source and destination are local paths.

3. Spawn the grader containers on the same host:

```zsh
chmod +x ./spawn-grader.sh
sudo ./spawn-grader.sh
```

The script detects the running `judgels-server` container and bind-mounts `./judgels/server/var/data` into each grader. No SSH keypair, no `authorized_keys` entry, and no separate Grader VM are needed.

4. Access the interfaces as described in the multi-VM step 10, except `CORE_VM_IP` is your single host's address (use `localhost` if accessing from the same machine).

## Contributing

If you discovered any issue regarding the judgels docker configuration, please see [ISSUES.md](./ISSUES.md) to create new issue.