# Dockerfile for docker skeleton (useful for running blackbox binaries, scripts, or python actions).
from centos:latest
RUN yum install -y epel-release
RUN yum install -y python-pip
RUN pip install --upgrade pip
RUN pip install --no-cache-dir gevent==1.1.2 flask==0.11.1 
ENV FLASK_PROXY_PORT 8080 
RUN mkdir -p /actionProxy
ADD actionproxy.py /actionProxy
RUN mkdir -p /action
ADD stub.sh /action/exec
RUN chmod +x /action/exec
CMD ["/bin/bash", "-c", "cd /actionProxy && python -u actionproxy.py"]
