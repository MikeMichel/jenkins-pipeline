#!groovy

properties([pipelineTriggers([githubPush()])])

node {

  stage 'Checkout repo with Code and Dockerfile'
    // replace with your id and url, check that the user has access to the repo
    git credentialsId: 'gitlabdeploymentlogin', url: 'https://github.com/MikeMichel/lets-chat.git'

  stage 'Set git en vars workaround'
    sh('git rev-parse HEAD > GIT_COMMIT')
    env.GIT_COMMIT=readFile('GIT_COMMIT').trim()
    
     //replace the path to your Dockerfile
  dir('./') {
      // replace with your id and url
    withDockerRegistry([credentialsId: 'mikedockerhub', url: 'https://index.docker.io/v1/']) {
      stage 'Build docker image'
      // replace with your image name
        def letschat = docker.build('mikemichel/letschat')

      stage 'Push image'
        letschat.push "latest"
        letschat.push "${GIT_COMMIT}"
    }

    stage 'Install sloppy.io CLI'
     sh "curl -k -L https://files.sloppy.io/sloppy-`uname -s`-`uname -m` > sloppy"
     sh "chmod +x sloppy"
     
    stage 'Deploy to sloppy.io'
     withCredentials([string(credentialsId: 'mikesloppytoken', variable: 'SLOPPY_APITOKEN')]) {
     sh "./sloppy change --image mikemichel/letschat:${GIT_COMMIT} letschat/frontend/node"
     }

  } // end dir

}

