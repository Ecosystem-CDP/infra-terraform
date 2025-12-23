# Manual Redeployment Guide

Follow these steps to reset the Ambari state and redeploy the cluster with the updated configurations.

### 1. Transfer Updated Files
Execute this command from your local machine (where the files are located) to update the configuration on the Master node.

```powershell
scp blueprint.json cluster_deploy.yml cluster-template.json root@master.cdp:/root/
```

### 2. Connect to Master Node
SSH into the master node to execute commands.

```powershell
ssh root@master.cdp
```

### 3. (Optional) Hard Reset of Ambari Server
**Only do this** if you want to completely wipe the Ambari database and start from scratch. If you just want to redeploy the cluster configuration, skip to Step 4 (the playbook handles cluster deletion).

```bash
# On master.cdp
ambari-server stop
ambari-server reset --silent
ambari-server start
```

### 4. Execute Deployment Playbook
Run the Ansible playbook. This script has been updated to:
1. Delete any existing 'odp-cluster' instance.
2. Delete the old 'odp-blueprint'.
3. Register the new blueprint and VDF.
4. Create the new cluster.

```bash
# On master.cdp
ansible-playbook /root/cluster_deploy.yml
```

### Troubleshooting
If `scp` or `ssh` fails with "Could not resolve hostname":
- Ensure `master.cdp` is in your `C:\Windows\System32\drivers\etc\hosts` file.
- Or replace `master.cdp` with the actual IP address of the master node.
