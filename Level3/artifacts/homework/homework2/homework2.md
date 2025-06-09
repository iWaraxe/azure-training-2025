The purpose of this homework is to:
- Get practical knowledge of how to deploy application to Kubernetes with HELM
- Get practical experience of working with Nginx-Ingress



`Table of content:`
1. Introduction


## `1. Introduction`

`HELM` was designed to optimize the Kuberentes deployment and management. 
The best practice is to use helm to deploy application and related components.
You need to create `HELM chart` that you can use to deploy application, `nginx` front-end load balancer and `redis cache` server.

You also need to expose application to the public network so users can use DNS alias with SSL cert to access it. 
For this you can re-use existing `HELM` chart for nginx-ingress and deploy with  minimal changes by operating the values.yaml file.

At the end of this homework you should get the following folder structure:
```
- helm-charts | 
    - mars-application
    - mars-nginx-ingress
    - redis
```
All folders represent the `HELM` charts

Create folder for helm charts:
```
mkdir helm-charts

```

## `2. Create HELM chart for application`

Create base HELM template using the following command: 
```
cd helm-charts
helm create mars-application
```
This command will generate the HELM chart with pre-exiting kuberentes templates. 
You need to review and update the configuration and include the following components below.
> Note: Helm chart already defines required configuration for application deployment. You can use Values.yaml file to update configuration to required state. 

The generated helm chart contains templates/_helper.tpl file that defines HELM function. 
Read this article to get more information about helm tpl - https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-tpl-function
In this homework we will simplify the configuration by removing all tpl functions from template and replace them by variables in values.yaml file. 

Remove serviceaccount.yaml file. 

### 1. Deployment.yaml

- `Labels` – use labels to specify the application name, target environment, and deployment version:
```
Labels:
	- name: myapp
 	  version: 1.0 
	  environment: QA
```

The labels definition contains a reference to helm tpl function. 
Read more about *helm tpl* function. 
Update the following configuration in _helper.tpl and add variables to have ability to define labels from Values.yaml

```
{{- define "mars-application.labels" -}}
helm.sh/chart: {{ include "mars-application.chart" 
name: {{ .Values.application.name}}
version: {{ .Values.application.version}}
enviro1nment: {{ .Values.application.environment}}
. }}
```
Create new variables in Values.yaml 
```
application:
	name: myapp
 	version: 1.0 
	environment: QA
```

- `Kuberentes probes`:
  - startup – to make sure that the application was started successfully 
  - readiness – to make sure that the application is ready to accept the traffic 
  - liveness – to check the application state over time. 

With `Kuberentes probes` you can check if application is running on 5000 port. 

- `Minimum number of replica` – 2

- `rollingUpdate` – with zero deployment downtime policy by your choice.

> Notes: Update deployment.yaml configuration section for healthcheck probes

Remove all other unused configuration from Values.yaml and Deployment.yaml file (like a configuration for service account)
### 2. hpa.yaml:

- `HPA` (horizontal pod autoscaling) – with autoscaling settings by your choice 
Re-use existing configuration for 
### 3. pdb.yaml (it is a new file, you need to create it manually):

- `PDB` (pod disruption budget)
Move all configuration of `PDB` to values.yaml of generated template.

Review the `HELM` chart configuration that was generated with `helm create` command. The values.yaml file contains all settings that are working as a parametrization for the `templates/*.yaml` file.
You should use the same concept. 

### 4. Ingress.yaml
- `Ingress`. 
Review the configuration of `template/ingress.yaml` file. 
All configuration of it is defined in `Values.yaml`. 
With the settings below you can configure the `DNS` record and `SSL` cert for `Nginx-Ingress`.

 
```
ingress:
  enabled: false
  className: ""
  annotations: {}
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

```
Do not remove this file, it will be re-configured with the next steps.

- Additionally, you need to migrate `configMap` that store application settings for the MARS application `homework 1` to HELM chart as well.

### 5. Service.yaml 
You already have the Service.yaml from previuse homework. The new file already contains all required configuration to expose your application. 
Additionally, you need to update the port configuration according to previuse homework requirements. 

## `3. Re-configure the PV volume. `

In case if you are building high available infrastructure you need to support at least two instances of application (in our case we use 2 instances - `Minimum number of replica` – 2). 
Update the disk mount configuration to be able to use shared volume and share it between pods.

In the Homework 1 we used PVC with one pod. There is no way to use the same configuration for two pods. Now you need to re-design the PVC setup. 

For this we need to update application and change the log file name. 
The new version of application is attached to this homework. 
Then, you need:
1. Re-build and push docker image to ACR. 
2. Create and mount disk according to the following guide: https://docs.microsoft.com/en-us/azure/aks/azure-disk-volume. 
 

## `4. Deploy Redis`

In previuse homework you created a simple deployment file where you used the `REDIS` image. 

With `HELM` you can install official `REDIS` chart. 
For this you need:
1. Download the `REDIS` chart from official git repo and install it with command:
```
# https://github.com/bitnami/charts/blob/master/bitnami/redis/values.yaml
helm install redis .\redis -n dev
# where -n dev - namespace
```
> Note: This `HELM` chart does not allow you to control the target deployment namespace from values.yaml. Instead of this it allows you to control deployment namespace with `helm install -n` command above:

Update and specify new name of `redis` Kubernetes service in configMap that store application config (if needed). 

## `4. Deploy nginx-ingress`

Download and install `nginx ingress` `HELM` chart. 
Create two folders:
  - helm - folder to store all homework helm charts
  - variables - folder to store your customized variables for helm charts.
```
# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
helm install mars-nginx .\ingress-nginx -n dev
```
> Note: here we also use `-n` flag that control target namespace for the deployment. 

## `5. Register DNS alises and SSL certifcate`
We need to configure DNS and SSL for our web site. 
For this we need to register free domain and download SSL certificate. 
After this we need to create a `Kubernetes SSL Secret` and map it with `Ingress.yaml`.
For the training purpuse we will skip this steps. Instead of this you will add DNS to localhost and register self-signed certificate .

Let's assume that you need to create website with the domain - issoft-k8s.net. 
Create certificate using powershell command:
```
New-SelfSignedCertificate -DnsName issoft-k8s.net -CertStoreLocation cert:\LocalMachine\My
``` 
Create certificate and process configuration with the next steps.

## `6. Configure Ingress`

Now you need to configure `template/Ingress.yaml`:
- set target ingress-nginx controller
- SSL
- DNS.

### 1. Set target ingress-nginx controller
`Nginx` is configured to automatically discover all ingress with the `kubernetes.io/ingress.class`: "nginx" annotation or where `ingressClassName: nginx` is present. Please note that the ingress resource should be placed inside the same namespace of the backend resource.
The `Values.yaml` file contains variable to manage `ingress.yaml` configuration.  
Update Values.yaml:
```
ingress:
  enabled: false
  className: "nginx"
```
> https://kubernetes.github.io/ingress-nginx/user-guide/basic-usage/
### 2. Configure DNS and SSL 
