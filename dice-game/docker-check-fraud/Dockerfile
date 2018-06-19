# used to build docker container schuhm/dice-demo-check

FROM schuhm/ow-docker-centos
# inherits openwhisk runtime for docker, __DO NOT__ overwrite CMD

#install python3, python3-pip, numpy, scipy
RUN yum -y install python34 python34-pip

RUN /usr/bin/pip3 install numpy scipy  
RUN /usr/bin/pip3 install matplotlib
RUN yum -y install python34-tkinter

# Plug in function
ADD check_fraud.py /action/exec
RUN chmod +x /action/exec


