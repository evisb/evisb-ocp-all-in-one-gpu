FROM nvidia/cuda:10.1-devel-centos7
RUN yum install -y cuda-samples-10-1 pciutils
RUN cd /usr/local/cuda-10.1/samples/1_Utilities/deviceQuery && make && \
    cd /usr/local/cuda-10.1/samples/1_Utilities/bandwidthTest && make
