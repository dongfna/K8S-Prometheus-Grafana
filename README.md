# k8s-prometheus-grafana

[K8s+Prometheus+Grafana部署笔记]

1、部署K8S


2、kubectl create -f K8S-Prometheus-Grafana/kubernetes-dashboard/*


3、kubectl create -f K8S-Prometheus-Grafana/kube-state-metrics/*


4、kubectl create -f K8S-Prometheus-Grafana/prometheus/*


5、kubectl create -f K8S-Prometheus-Grafana/grafana/*


Grafana v7.3.7登录密码：

admin/abcdocker


grafana/grafana-volume.yaml 中 nfs sever ip换成自己环境master的


Dashboard 模板ID：13105

官网下载地址：https://grafana.com/grafana/dashboards


docker pull 加速：
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io
