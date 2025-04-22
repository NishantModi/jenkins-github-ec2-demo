pipeline {
  agent any

  environment {
    // reference the SSH credential you added
    EC2_SSH = 'ec2-deploy-key'
    // remote host details
    REMOTE_USER = 'ec2-user'
    REMOTE_HOST = 'ec2-13-233-84-45.ap-south-1.compute.amazonaws.com'
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
        sshagent (credentials: ["ec2-deploy-key"]) {
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
