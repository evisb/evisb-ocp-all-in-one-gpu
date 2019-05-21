# OCP-All-In-One-GPU
OpenShift All-in-One cluster with GPU support

## Ansible Roles

### nvidia-driver-install
This role will pull down the latest 3rd party NVIDIA driver and install it.
After having deployed OCP, run:
```
ansible-playbook -i ./inventory/inventory-oia -e hosts_to_apply="fast_nodes" ./playbooks/nvidia-driver-install.yaml
```
where `fast_nodes` is the Ansible inventory groupname for your nodes with GPUs

### nvidia-container-runtime-hook
This playbook will install the nvidia-container-runtime-hook which is used to
mount libraries from the host into a pod whose dockerfile has certain
environment variables. It is invoked by running following playbook:
```
ansible-playbook -i ./inventory/inventory-oia -e hosts_to_apply="fast_nodes" ./playbooks/nvidia-container-runtime-hook.yaml
```

### nvidia-device-plugin
This playbook will deploy the NVIDIA device-plugin daemonset, which allows you to schedule GPU pods. 
```
ansible-playbook -i ./inventory/inventory-oia -e hosts_to_apply="master_hostname" -e gpu_hosts="fast_nodes" ./playbooks/nvidia-device-plugin.yaml
```

`master_hostname` is the inventory hostname of one of your masters. `fast_nodes` is the inventory groupname for your nodes with GPUs.

After deploying, run:
```
oc describe node x.x.x.x | grep -A15 Capacity
```
You should see nvidia.com/gpu=N where N is the number of GPUs in the system.

### gpu-pod
To test your GPU there is also a basic Dockerfile that is based on the NVIDIA CUDA 10.0 CentOS7 image and includes the deviceQuery binary.
Run the deviceQuery command after having run the deployment script first.
```
ansible-playbook -i ./inventory/inventory-oia -e hosts_to_apply="fast_nodes" ./playbooks/gpu-pod.yaml
```

This demonstrates that the process in the pod has access to the GPU hardware.  If it does not, it results in a FAIL status.
```
oc rsh gpu-pod /usr/local/cuda-10.1/samples/1_Utilities/deviceQuery/deviceQuery
```

### Other scripts
There is an additional script to prep the machine before OCP deployment, a scripts to perform a full Kubeflow deployment and a template for Tensorflow with GPU support.