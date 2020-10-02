#
# Copyright (c) 2019-2020, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
#

ARG FROM_IMAGE=gpuci/miniconda-cuda
ARG CUDA_VERSION=10.1 
ARG LINUX_VERSION=ubuntu18.04
ARG CC_VERSION=7
ARG IMAGE_TYPE=base
ARG PYTHON_VERSION=3.6

FROM ${FROM_IMAGE}:${CUDA_VERSION}-${IMAGE_TYPE}-${LINUX_VERSION}

# Capture argument used for FROM
ARG CC_VERSION
ARG CUDA_VERSION
ARG PYTHON_VERSION

# Update environment for gcc/g++ builds
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV CUDAHOSTCXX=/usr/bin/g++
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/lib
# Enables "source activate conda"
SHELL ["/bin/bash", "-c"]

# Install gcc version
RUN apt update && apt-get -y install g++-${CC_VERSION} gcc-${CC_VERSION} vim cmake make 
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${CC_VERSION} 1000 --slave /usr/bin/g++ g++ /usr/bin/g++-${CC_VERSION}

# Installing cuda
RUN apt update && apt-get -y install cuda-toolkit-$(echo "${CUDA_VERSION}" | sed -e "s/\./-/g" | cut -d- -f1-2)

# Add a condarc for channels and override settings
RUN echo -e "\
ssl_verify: False \n\
channels: \n\
  - gpuci \n\
  - conda-forge \n\
  - nvidia \n\
  - defaults \n" > /conda/.condarc \
      && cat /conda/.condarc ;

# Create rapids conda env and make default
RUN source activate base \
    && conda install -y gpuci-tools \
    && gpuci_conda_retry create --no-default-packages --override-channels -n rapids \
      -c nvidia \
      -c conda-forge \
      -c defaults \
      -c gpuci \
      git \
      gpuci-tools \
      python=${PYTHON_VERSION} \
      "setuptools<50" \
    && sed -i 's/conda activate base/conda activate rapids/g' ~/.bashrc ;

# Install the packages needed to build with.
# Install htslib dependencies
RUN apt-get install -y tabix \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libcurl4-gnutls-dev \
        wget \
        libssl-dev      # VariantWorks `cyvcf2` dependency

# Install htslib
RUN wget https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 && tar xvf htslib-1.9.tar.bz2 && cd htslib-1.9 && ./configure && make -j16 install

# ADD source dest
# Create symlink for old scripts expecting `gdf` conda env
RUN ln -s /opt/conda/envs/rapids /opt/conda/envs/gdf

# Clean up pkgs to reduce image size
RUN conda clean -afy \
    && chmod -R ugo+w /opt/conda

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]
