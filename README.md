# OCP-All-In-One-GPU
OpenShift All-in-One cluster with GPU support

## Ansible Roles

### nvidia-driver-install
This role will pull down the latest 3rd party NVIDIA driver and install it.
After having deployed OCP, run:
```ansible-playbook -i ./inventory/inventory -e hosts_to_apply="fast_nodes" ./playbooks/nvidia-driver-install.yaml```
where `fast_nodes` is the Ansible inventory groupname for your nodes with GPUs

### nvidia-container-runtime-hook
This playbook will install the nvidia-container-runtime-hook which is used to
mount libraries from the host into a pod whose dockerfile has certain
environment variables. It is invoked as the `nvidia-driver-install` playbook above.

### nvidia-device-plugin
This playbook will deploy the NVIDIA device-plugin daemonset, which allows you to schedule GPU pods. 
```ansible-playbook -i ./inventory/inventory -e hosts_to_apply="master_hostname" -e gpu_hosts="fast_nodes" ./playbooks/nvidia-device-plugin.yaml```

`master_hostname` is the inventory hostname of one of your masters. `fast_nodes` is the inventory groupname for your nodes with GPUs.

After deploying, run:
```oc describe node x.x.x.x | grep -A15 Capacity```.  You should see nvidia.com/gpu=N where N is the number of GPUs in the system.

### gpu-pod
This role will create a new pod that leverages Taints and Tolerations to run on the fastnode pool.  It consumes a GPU.  The pod sleeps indefinitely.  To test your GPU pod:
Also included is a basic Dockerfile that is based on the NVIDIA CUDA 9.1 CentOS7 image and includes the deviceQuery binary used below.

Run the deviceQuery command.  This demonstrates that the process in the pod has access to the GPU hardware.  If it did not, the Result at the bottom would indicate FAIL.
```
# oc rsh gpu-pod /usr/local/cuda-9.1/samples/1_Utilities/deviceQuery/deviceQuery
/usr/local/cuda-9.1/samples/1_Utilities/deviceQuery/deviceQuery Starting...

 CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 1 CUDA Capable device(s)

Device 0: "Tesla M60"
  CUDA Driver Version / Runtime Version          9.1 / 9.1
  CUDA Capability Major/Minor version number:    5.2
  Total amount of global memory:                 7619 MBytes (7988903936 bytes)
  (16) Multiprocessors, (128) CUDA Cores/MP:     2048 CUDA Cores
  GPU Max Clock rate:                            1178 MHz (1.18 GHz)
  Memory Clock rate:                             2505 Mhz
  Memory Bus Width:                              256-bit
  L2 Cache Size:                                 2097152 bytes
  Maximum Texture Dimension Size (x,y,z)         1D=(65536), 2D=(65536, 65536), 3D=(4096, 4096, 4096)
  Maximum Layered 1D Texture Size, (num) layers  1D=(16384), 2048 layers
  Maximum Layered 2D Texture Size, (num) layers  2D=(16384, 16384), 2048 layers
  Total amount of constant memory:               65536 bytes
  Total amount of shared memory per block:       49152 bytes
  Total number of registers available per block: 65536
  Warp size:                                     32
  Maximum number of threads per multiprocessor:  2048
  Maximum number of threads per block:           1024
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
  Maximum memory pitch:                          2147483647 bytes
  Texture alignment:                             512 bytes
  Concurrent copy and kernel execution:          Yes with 2 copy engine(s)
  Run time limit on kernels:                     No
  Integrated GPU sharing Host Memory:            No
  Support host page-locked memory mapping:       Yes
  Alignment requirement for Surfaces:            Yes
  Device has ECC support:                        Enabled
  Device supports Unified Addressing (UVA):      Yes
  Supports Cooperative Kernel Launch:            No
  Supports MultiDevice Co-op Kernel Launch:      No
  Device PCI Domain ID / Bus ID / location ID:   0 / 0 / 30
  Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 9.1, CUDA Runtime Version = 9.1, NumDevs = 1
Result = PASS
```

The gpu-pod role also includes a caffe2 Multi-GPU jupyter notebook demo.  Deploy the caffe2 environment like so:

```ansible-playbook -i inventory/inv playbooks/gpu-pod.yaml```

To access the jupyter webserver run the ```get_url.sh`` script on the master.

```
playbooks/gpu-pod/get_url.sh
```

get_url.sh will output a route and token.

Use the token to authenticate to route:
http://<route>/notebooks/caffe2/caffe2/python/tutorials/Multi-GPU_Training.ipynb?token=<token>