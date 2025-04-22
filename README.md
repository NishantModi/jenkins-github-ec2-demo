# jenkins-github-ec2-demo
This demo will help you to understand how code is getting deployed to ec2 instance/server
Here’s a beginner‑friendly, step‑by‑step guide to set up a Jenkins Pipeline that checks out your GitHub code and deploys it to your EC2 Linux instance over SSH.

---

## 1. Prerequisites

1. **Jenkins** running in Docker on your local / running on AWS instance.  
2. **EC2 Linux instance** reachable from your local via SSH (you have the `.pem` key).  
3. **GitHub repository** URL containing your sample code.  
4. **SSH Agent Plugin** installed in Jenkins (we’ll install it below).  

---

## 2. Prepare Your EC2 Instance

On your local terminal, ensure you can SSH into the EC2:
```bash
ssh -i /path/to/your-key.pem ec2-user@ec2-your-ip.compute.amazonaws.com
```
If that works, move on.

---

## 3. Configure Jenkins for SSH Deployments

1. **Open Jenkins UI**  
   Navigate to `http://localhost:8080` in your browser.

2. **Install SSH Agent Plugin**  
   - Manage Jenkins → Manage Plugins → Available  
   - Search **“SSH Agent Plugin”**, check it, and click **Install without restart**.

3. **Add SSH Credentials**  
   - Manage Jenkins → Credentials → System → Global credentials (unrestricted) → Add Credentials  
     - Kind: **SSH Username with private key**  
     - Username: `ec2-user` (or your EC2 user)  
     - Private Key: **Enter directly** → paste the contents of your `.pem` file  
     - ID: `ec2-deploy-key` (you’ll reference this in the pipeline)  
     - Description: “EC2 deploy key”

---

## 4. Create a Jenkins Pipeline Job

1. **New Item** → “my‑deploy‑pipeline” → Pipeline → OK  
2. Under **Pipeline** section:
   - Definition: **Pipeline script from SCM**  
   - SCM: **Git**  
     - Repository URL: `https://github.com/your‑username/your‑repo.git`  
     - Credentials: (if private) add GitHub credentials the same way you added SSH, or use “None” for public repo  
   - Script Path: `Jenkinsfile` (we’ll create this next)  
3. Save the job.

---

## 5. Write Your `Jenkinsfile`

In the **root** of your GitHub repo, create a file named `Jenkinsfile` with the following declarative pipeline:

```groovy
pipeline {
  agent any

  environment {
    // reference the SSH credential you added
    EC2_SSH = 'ec2-deploy-key'
    // remote host details
    REMOTE_USER = 'ec2-user'
    REMOTE_HOST = 'ec2-your-ip.compute.amazonaws.com'
    // path on the server where code will live
    REMOTE_DIR  = '/home/ec2-user/deploy-demo'
  }

  stages {
    stage('Checkout') {
      steps {
        // clone your GitHub repo
        checkout scm
      }
    }

    stage('Build') {
      steps {
        // (optional) build commands, e.g. npm install, mvn package, etc.
        echo "Add build steps here if needed"
      }
    }

    stage('Deploy to EC2') {
      steps {
        // wraps the following steps in SSH agent
        sshagent (credentials: ["${EC2_SSH}"]) {
          // create target dir, copy code, restart service
          sh """
            ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'mkdir -p ${REMOTE_DIR}'
            scp -o StrictHostKeyChecking=no -r * ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}
            ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && ./deploy.sh'
          """
        }
      }
    }
  }

  post {
    success {
      echo 'Deployment succeeded!'
    }
    failure {
      echo 'Deployment failed. Check logs.'
    }
  }
}
```

### Notes on the Pipeline
- **sshagent**: makes your SSH key available inside the `sh` block.  
- **StrictHostKeyChecking=no**: skips the “yes/no” prompt on first SSH.  
- **deploy.sh**: a simple script in your repo’s root that you write to start/restart your app.  

---

## 6. Create a Simple `deploy.sh` in Your Repo

In your repo root, add:

```bash
#!/bin/bash
# deploy.sh – runs on EC2

# Navigate and restart
cd "$(dirname "$0")" || exit
# e.g., if it’s a Node app:
# pm2 stop myapp || true
# pm2 start app.js --name myapp

echo "Deployed at $(date)" >> deploy.log
```

### Make it executable:

```bash
chmod +x deploy.sh
git add deploy.sh
git commit -m "Add deploy script"
git push
```

---

## 7. Run the Pipeline

1. In Jenkins → your “my‑deploy‑pipeline” job → **Build Now**.  
2. Watch the console output:
   - Checkout → Build → Deploy to EC2  
   - You should see SSH connection logs and your `deploy.sh` output.

---

## 8. Verify on EC2

SSH into EC2 again and check:

```bash
cat /home/ec2-user/deploy-demo/deploy.log
```

You should see the timestamp line—confirming your code was copied and the script ran.

---

## 9. Next Steps & Tips

- **Security**: consider adding your EC2 host to known hosts in Jenkins (`ssh-keyscan`) instead of disabling StrictHostKeyChecking.  
- **Scaling**: for multiple instances, loop over hosts in the pipeline.  
- **Credentials**: for private GitHub repos, add Git credentials (username/password or SSH key) to Jenkins.  
- **Notifications**: add email/Slack notifications in the `post` block.  

---

You’re now set up with a Jenkins Pipeline that takes code from GitHub and deploys it to your EC2 instance! Feel free to tweak the `Build` and `Deploy` stages to suit your application’s needs.
