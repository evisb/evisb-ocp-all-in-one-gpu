#!/bin/sh

echo $(date) "- Creating kf directory to host the deployment artifacts"
mkdir /root/kf
export KFAPP=/root/kf
export HOST=ocp.eb.gpu.gr.clus
cd ${KFAPP}

#echo $(date) "- Creating nfs share for kubeflow"
#mkdir /srv/nfs/kubeflow
#chown nfsnobody:nfsnobody /srv/nfs/kubeflow/
#chmod -R 777 /srv/nfs/kubeflow/
#echo '"/srv/nfs/kubeflow" *(rw,root_squash)' >> /etc/exports.d/openshift-ansible.exports
#systemctl restart nfs

echo $(date) "- Create kubeflow local storage "
mkdir /mnt/kubeflow

echo $(date) "- Create dir for pv files"
mkdir /root/pvs

echo $(date) "- Creating storage class for local storage"
cat << EOF > /root/pvs/storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

echo $(date) "- Creating yaml files for 25 pv objects of 1Gi in kubeflow"
export volsize="1Gi"
for volume in pv-1-{1..25}; \
do \
mkdir -p /mnt/kubeflow/${volume} 
cat << EOF > /root/pvs/${volume}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${volume} 
spec:
  capacity:
    storage: ${volsize} 
  accessModes:
  - ReadWriteOnce 
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow/${volume} 
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${HOST}
EOF
     echo "Created yaml file for ${volume}"; \
done

echo $(date) "- Creating yaml files for 20 pv objects of 2Gi in kubeflow"
export volsize="2Gi"
for volume in pv-2-{1..20}; \
do \
mkdir -p /mnt/kubeflow/${volume} 
cat << EOF > /root/pvs/${volume}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${volume} 
spec:
  capacity:
    storage: ${volsize} 
  accessModes:
  - ReadWriteOnce 
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow/${volume} 
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${HOST}
EOF
     echo "Created yaml file for ${volume}"; \
done

echo $(date) "- Creating yaml files for 10 pv objects of 5Gi in kubeflow"
export volsize="5Gi"
for volume in pv-5-{1..10}; \
do \
mkdir -p /mnt/kubeflow/${volume} 
cat << EOF > /root/pvs/${volume}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${volume} 
spec:
  capacity:
    storage: ${volsize} 
  accessModes:
  - ReadWriteOnce 
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow/${volume} 
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${HOST}
EOF
     echo "Created yaml file for ${volume}"; \
done

echo $(date) "- Creating yaml files for 10 pv objects of 10Gi in kubeflow"
export volsize="10Gi"
for volume in pv-10-{1..10}; \
do \
mkdir -p /mnt/kubeflow/${volume} 
cat << EOF > /root/pvs/${volume}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${volume} 
spec:
  capacity:
    storage: ${volsize} 
  accessModes:
  - ReadWriteOnce 
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow/${volume} 
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${HOST}
EOF
     echo "Created yaml file for ${volume}"; \
done

echo $(date) "- Creating yaml files for 5 pv objects of 20Gi in kubeflow"
export volsize="20Gi"
for volume in pv-10-{1..5}; \
do \
mkdir -p /mnt/kubeflow/${volume} 
cat << EOF > /root/pvs/${volume}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${volume} 
spec:
  capacity:
    storage: ${volsize} 
  accessModes:
  - ReadWriteOnce 
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/kubeflow/${volume} 
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${HOST}
EOF
     echo "Created yaml file for ${volume}"; \
done

echo $(date) "- Creating kubeflow project"
oc new-project kubeflow

echo $(date) "- Creating storage class and pv objects in Openshift"
for filename in /root/pvs/*; \
do \
oc create -f $filename
done

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

echo $(date) "- Create scc for hostpath adhoc storage"
cat > hostpath-scc.yaml <<EOF
kind: SecurityContextConstraints
apiVersion: v1
metadata:
  name: hostpath
allowPrivilegedContainer: true
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
users:
groups:
EOF
oc create -f hostpath-scc.yaml

echo $(date) "- Set the allowHostDirVolumePlugin parameter to true for the hostpath scc"
oc patch scc hostpath -p '{"allowHostDirVolumePlugin": true}'

echo $(date) "- Grant access to this SCC to all users"
oc adm policy add-scc-to-group hostpath system:authenticated
