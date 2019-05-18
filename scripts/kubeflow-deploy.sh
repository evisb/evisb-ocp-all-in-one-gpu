#!/bin/sh

echo $(date) "- Creating kf directory to host the deployment artifacts"
mkdir /root/kf
export KFAPP=/root/kf
cd ${KFAPP}

#echo $(date) "- Creating nfs share for kubeflow"
#mkdir /srv/nfs/kubeflow
#chown nfsnobody:nfsnobody /srv/nfs/kubeflow/
#chmod -R 777 /srv/nfs/kubeflow/
#echo '"/srv/nfs/kubeflow" *(rw,root_squash)' >> /etc/exports.d/openshift-ansible.exports
#systemctl restart nfs

echo $(date) "- Create kubeflow local storage "
mkdir /mnt/kubeflow

echo $(date) "- Creating storage class for local storage"
cat > storageclass.yaml <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

echo $(date) "- Creating yaml files for the necessary pv objects in kubeflow"
cat > pv1.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv1
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ocp.eb.gpu.gr.clus
EOF

cat > pv2.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv2
spec:
  capacity:
    storage: 20Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ocp.eb.gpu.gr.clus
EOF

cat > pv3.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv3
spec:
  capacity:
    storage: 20Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ocp.eb.gpu.gr.clus
EOF

echo $(date) "- Creating kubeflow project"
oc new-project kubeflow

echo $(date) "- Creating storage class and pv objects in Openshift"
oc create -f storageclass.yaml
oc create -f pv1.yaml
oc create -f pv2.yaml
oc create -f pv3.yaml

echo $(date) "- Deploy Kubeflow"
wget https://github.com/kubeflow/kubeflow/releases/download/v0.5.1/kfctl_v0.5.1_linux.tar.gz -O kfctl.tar.gz
tar -xvf kfctl.tar.gz
mv -f kfctl /usr/bin/kfctl
rm -f /root/kf/*
kfctl init ${KFAPP}
kfctl generate all -V
kfctl apply all -V

echo $(date) "- Applying correct scc to service accounts in the kubeflow project"
oc adm policy add-scc-to-user anyuid -z ambassador -n kubeflow
oc adm policy add-scc-to-user anyuid -z jupyter -n kubeflow
oc adm policy add-scc-to-user anyuid -z katib-ui -n kubeflow
oc adm policy add-scc-to-user anyuid -z default -n kubeflow
oc adm policy add-scc-to-user anyuid -z jupyter-hub -n kubeflow
oc adm policy add-scc-to-user anyuid -z jupyter-notebook -n kubeflow
oc adm policy add-scc-to-user anyuid -z studyjob-controller -n kubeflow


#oc adm policy add-scc-to-user privileged -z argo -n kubeflow
#oc adm policy add-scc-to-user privileged -z pipeline-runner -n kubeflow


echo $(date) "- Patch vizier-db deployment. Readiness check is logging to mysql with the wrong user"
oc patch deployment vizier-db -n kubeflow --type=json -p='[{ "op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command": [ "/bin/bash", "-c", "mysql -u root -D $$MYSQL_DATABASE -p$$MYSQL_ROOT_PASSWORD -e \"SELECT 1\"" ] }, "failureThreshold": 5, "initialDelaySeconds": 5, "periodSeconds": 2, "successThreshold": 1, "timeoutSeconds": 1} } ]'

echo $(date) "- Add finalizer to clusterrole notebooks-controller"
oc patch clusterrole notebooks-controller --type=json  -p '[{"op":"add", "path":"/rules/-", "value":{"apiGroups":["kubeflow.org"],"resources":["notebooks/finalizers"],"verbs":["*"]}}]'

echo $(date) "- Create route for Ambassador"
oc expose service/ambassador -n kubeflow