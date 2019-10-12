###
### copied base from paperspace/fastai-docker but didnt want all their layers
###
FROM nvidia/cuda:10.1-base

LABEL com.nvidia.volumes.needed="nvidia_driver"

RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update && apt-get install -y --allow-downgrades --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         ca-certificates \
         libnccl2=2.4.8-1+cuda10.1 \
         libnccl-dev=2.4.8-1+cuda10.1 \
         libjpeg-dev \
	       zip \
	       unzip \
         libpng-dev &&\
     rm -rf /var/lib/apt/lists/*

ENV PYTHON_VERSION=3.6
RUN curl -o ~/miniconda.sh -O  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh && \
    /opt/conda/bin/conda install conda-build
#RUN apt-get install python3.7


ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
# set conda 
ENV PATH=/opt/conda/bin:$PATH

WORKDIR /home/ubuntu

# install dependencies
COPY requirements.txt .

RUN which pip
RUN pip install --upgrade pip

#RUN conda install --yes --file requirements.txt 
RUN pip install -r requirements.txt 

# install vim keyamps for notebooks
#RUN jupyter labextension install jupyterlab_vim


WORKDIR /home/ubuntu

ENV PATH=$PATH:~/.local/bin


# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "-s", "--"]

