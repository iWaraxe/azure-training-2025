The purpose of this homework is to get practical knowledge of how to deploy application to Kuberentes using YAML templates and kubectl. 

`Prerequisites. `

In this homework you need to work with Docker images. 
Download and install Docker Desktop client. 

> Note: Use this command to switch docker daemon to use Linux containers
```
PS: & "C:\Program Files\Docker\Docker\DockerCli.exe" -SwitchLinuxEngine
# powershell 
```
How to install docker desktop - https://www.docker.com/products/docker-desktop. 

> If you experience an issue with Docker desktop installation then setup Azure Virtual Machine from image with docker installed. 


`Table of content:`
1. Introduction
2. Implement Azure container registry (ACR)
3. Create custom image
4. Design kubernetes tempates
5. Deploy `REDIS` server
6. Create `Persistent Volume` (`PV`)
7. Create `ConfigMap`

## `1. Introduction`
In this homework you need to deploy a custom application to Kubernetes cluster. 
In artifacts/mars.py (MARS) you have simple python application. 
The MARS application writes logs to the /mnt/logs/  every time when you access it endpoint. 
THe MARS application it is a backend application so public access should be denied.


## `2.	Implement Azure container registry (ACR)`

You need to implement a private docker registry for your custom images. 
Deploy ACR from azure portal (manually or using automation).

Connect ACR to Azure Kubernetes Service (AKS): https://docs.microsoft.com/en-us/azure-stack/aks-hci/deploy-azure-container-registry#deploy-an-image-from-acr-to-aks-on-azure-stack-hci

```
  kubectl create secret docker-registry acr-docker --namespace development 
                                                   --docker-server=acrname.azurecr.io 
                                                   --docker-username=USERNAME  --docker-password=PASSWORD

# where USERNAME and PASSWORD it is a login and password of ACR from azure portal (portal.azure.com -> ACR -> Access keys)
```

## *Additional documentation for read.*

Container registry - https://docs.microsoft.com/en-us/azure/container-registry/container-registry-concepts

imagePullSecrets - https://kubernetes.io/docs/concepts/containers/images/#referring-to-an-imagepullsecrets-on-a-pod

## `3.	Create custom image`
You need to create a custom docker image for the MARS application and push it to private registry. 
For this you need to create a Dockerfile. Use the content below to create Dockerfile:
```
FROM python:2.7-onbuild
EXPOSE 5000
ENTRYPOINT [ "python", "app.py" ]
```
The `mars.py` and `requirements.txt` should be located in the same directory with Dockerfile where you run docker build command:
```
docker build . -t linux/mars
```
Login to ACR and push image:
```
docker login <acrname>.azurecr.io
docker tag linux/mars:latest  <acrname>.azurecr.io/linux/mars
docker push  <acrname>.azurecr.io/linux/mars
```
> Note: You can get credentials for ACR from azure portal. 

> Note: When you deploy something to Kubernetes you need to tell which command (runtime) should be executed once container will be started. There are 3 ways of how to do this: 
>1.  ENTRYPOINT - In DockerFile
>2.  CMD - in Dockerfile
>4.  command - in Kubernetes YAML

> Without runtime command the Kubernetes will start and fail container.

## *Additional documentation for read.*
Entrypoint - https://www.ctl.io/developers/blog/post/dockerfile-entrypoint-vs-cmd/

Build and push image to ACR - https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-docker-cli?tabs=azure-cli

## `4.	Design kubernetes tempates`

Now you need to deploy application to Kubernetes. 
For this you need to design Kubernetes templates with the requirements below. 
> Notes: resources should be deployed in the same namespace where you deploy application. 

1. Create namespace (with `kubectl create` or with `YAML` - for your choise)
2. Create Kubernetes `Deployment` object:
```
kind: Deployment
metadata:
  name: APP NAME 
  labels:
    app: APP NAME 
spec:
  replicas: 1
  selector:
    matchLabels:
      app: APP NAME 
  template:
    metadata:
      labels:
        app: APP NAME 
    spec:
      imagePullSecrets:
      - name: REGISTRY NAME # READ NOTES BELOW!
      containers:
      - name: APP NAME 
        image: <acr-name>.azurecr.io/APP NAME:v1
        ports:
        - containerPort: 80
```
> Note: the common mistake when create a docker registry secret that secret **should be deployed to the same namespace, where you plan to deploy the pods**.
> Once you've created the image pull secret, you can use it to create Kubernetes pods and deployments. Provide the name of the secret under imagePullSecrets in the deployment file (See documentation). 

3. Kubernetes `Service`.

Create additional `YAML` file to deploy Kubernetes service. 
> Note: `kind: service` use labels to route traffic to the pod. The service label selector should be much with deployment label.

Deploy service. 

Check application logs to make sure that app running properly: 
```
kubectl logs -n NAMESPACE -l app=APPLICATION NAME 
```
Open application in browser:
```
kubectl port-forward svc/SERVICE NAME OF APP -n your NAMESPACE 5000:5000

```
You will get `redis.exceptions.ConnectionError` exception. 

## `5. Deploy REDIS server`

Find required image in dockerhub and import in to the ACR. 
Create `Deployment` and `Service` YAML files and deploy REDIS server (use image from private registry).

Make sure that `6379` redis port is open  

Open application in browser again and check if error with `REDIS` was resolved. 

Now you need to resolve an error with log file path. 
## *Additional documentation for read.*

Import docker image to ACR - https://docs.microsoft.com/en-us/azure/container-registry/container-registry-import-images?tabs=azure-cli#import-from-a-public-registry

## `6. Create Persistent Volume (`PV`)`

When you access application in browser you will see that it throw exception - `redIOError: [Errno 2] No such file or directory: '/mnt/logs/info.log'`, that because application writes logs to the non-existing disk. 

Create and deploy `Persistent Volume` to resolve problem with non-existing disk

Open application in browser and check if application work properly. 

Login to container with `kubectl exec` command and check application logs:
```
PS: kubectl exec -it -n development mars-b5b6cdff8-mf7ps -- /bin/bash

root@mars-b5b6cdff8-mf7ps:/mnt/logs# cat info.log 
INFO:werkzeug:127.0.0.1 - - [24/Jan/2022 09:52:16] "GET / HTTP/1.1" 200 -
INFO:werkzeug:127.0.0.1 - - [24/Jan/2022 09:52:16] "GET /favicon.ico HTTP/1.1" 404 -
INFO:werkzeug:127.0.0.1 - - [24/Jan/2022 09:52:22] "GET / HTTP/1.1" 200 -
```

## 7. `Create ConfigMap`

Your teams just started development of MARS application. The MARS application use `mars.config` file to read secure and configuration settings. 
For now, it fetches the Redis server URL and host URL but in future developers plan to add some other settings to have ability to handle difference between environments. 
The docker contains should be unified for all environments. In this case all application settings should be handled in Kuberentes with ConfigMap or Secrets. 

You need to create a configMap from the mars.config and mount it as a file to the `/usr/src/app/config` config folder.
For this you need:

1. Create `configMap` with a file content of mars.config 
> Note: file should be mounted to `/usr/src/app/config`  folder.
2. Update `Deployment.yaml` (`kind: deployment`) and add configuration to mount the `configMap`.
3. Update file path of the config file in mars.py code to the following:

mars.py: 
```
parser.read("config/mars.config")

```

4. Re-build docker image to apply changes and push it to the ACR. 
5. Re-deploy all Kuberentes components. 