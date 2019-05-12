#!/bin/sh

echo $(date) "- Creating kf directory to host the deployment artifacts"
mkdir /root/kf
export KFAPP=/root/kf
cd ${KFAPP}

echo $(date) "- Creating nfs share for kubeflow"
mkdir /srv/nfs/kubeflow
chown nfsnobody:nfsnobody /srv/nfs/kubeflow/
chmod -R 777 /srv/nfs/kubeflow/
echo '"/srv/nfs/kubeflow" *(rw,root_squash)' >> /etc/exports.d/openshift-ansible.exports
systemctl restart nfs

echo $(date) "- Creating yaml files for the necessary pv objects in kubeflow"
cat > pv1.yaml <<EOF
kind: PersistentVolume
apiVersion: v1
metadata:
  name: kf1-volume
  labels:
    storage: kubeflow
  annotations:
  finalizers:
    - kubernetes.io/pv-protection
spec:
  capacity:
    storage: 10Gi
  nfs:
    server: ocp.eb.gpu.gr.clus
    path: /srv/nfs/kubeflow
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
EOF

cat > pv2.yaml <<EOF
kind: PersistentVolume
apiVersion: v1
metadata:
  name: kf2-volume
  labels:
    storage: kubeflow
  annotations:
  finalizers:
    - kubernetes.io/pv-protection
spec:
  capacity:
    storage: 20Gi
  nfs:
    server: ocp.eb.gpu.gr.clus
    path: /srv/nfs/kubeflow
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
EOF

cat > pv3.yaml <<EOF
kind: PersistentVolume
apiVersion: v1
metadata:
  name: kf3-volume
  labels:
    storage: kubeflow
  annotations:
  finalizers:
    - kubernetes.io/pv-protection
spec:
  capacity:
    storage: 20Gi
  nfs:
    server: ocp.eb.gpu.gr.clus
    path: /srv/nfs/kubeflow
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
EOF

echo $(date) "- Creating pv objects in Openshift"
oc create -f pv1.yaml
oc create -f pv2.yaml
oc create -f pv3.yaml

echo $(date) "- Deploy Kubeflow"
wget https://github.com/kubeflow/kubeflow/releases/download/v0.5.0/kfctl_v0.5.0_linux.tar.gz -O kfctl.tar.gz
tar -xvf kfctl.tar.gz
mv -f kfctl /usr/bin/kfctl
rm -f /root/kf/* #kfctl.tar.gz
kfctl init ${KFAPP}
kfctl generate all -V
kfctl apply all -V

echo $(date) "- Applying correct scc to service accounts in the kubeflow project"
oc adm policy add-scc-to-group anyuid system:serviceaccounts:kubeflow
oc adm policy add-scc-to-group privileged system:serviceaccounts:kubeflow

echo $(date) "- Patch vizier-db deployment. Readiness check is logging to mysql with the wrong user"
oc patch deployment vizier-db -n kubeflow --type=json -p='[{ "op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command": [ "/bin/bash", "-c", "mysql -u root -D $$MYSQL_DATABASE -p$$MYSQL_ROOT_PASSWORD -e 'SELECT 1'" ] }, "failureThreshold": 5, "initialDelaySeconds": 5, "periodSeconds": 2, "successThreshold": 1, "timeoutSeconds": 1} } ]'