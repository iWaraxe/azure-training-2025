# Demo workflow. 

The purpuse of this demo is to demonstrate how to deployed and setup the monitoring stack for kubernetes with helm. 

## 1. Wolk throught chart configuration. 
Open prometheus github repo  and show from where did we taked this chart. 
https://github.com/prometheus-community/helm-charts


## 2. Show how to work with values.yaml file

The helm charts contains the values.yaml that define the configuration settings for the software or tools. 
Deploy helm chart:
```
cd kube-prometheus-stack
# deploy helm chart
Helm install monitoring .\kube-prometheus-stack
```
The Grafana stack will be deployed without public endpoint. 
Re-deploy the public endpoint for Grafana. For this we need to enable nginx ingress. 
Create new value.yaml file with the content below and deploy it with the command:
Values.yaml:
```
kube-prometheus-stack:
  grafana:
	ingress:
	  enabled:true
```
```
Helm update --install monitoring .\kube-prometheus-stack -f values.yaml
```
Explain how the umbrela charts works (https://helm.sh/docs/chart_template_guide/subcharts_and_globals/).
Demonstrate how to access Grafana 
Demonstrate how to access Prometheus and how to test metrics with Prometheus queries.
Explain from where this chart download dependencies (See Chart.yaml.)

Explain how to store them staticly in own git repo. For this create folder with name "Chart"  in the root folder of kube-prometheus-stack and download all charts to this folder.
Then remove dependencies block from Chart.yaml and deploy stack again:
```
Helm update --install monitoring .\kube-prometheus-stack -f values.yaml
```