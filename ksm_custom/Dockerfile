FROM scratch

COPY kube-state-metrics /
VOLUME /tmp

ENTRYPOINT [ "/kube-state-metrics", "--port=8080", "--collectors=daemonsets,deployments,limitranges,nodes,pods,replicasets,replicationcontrollers,resourcequotas,services,jobs,cronjobs,statefulsets"]

EXPOSE 8080
