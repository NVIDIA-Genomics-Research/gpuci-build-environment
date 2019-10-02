#
# Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
#

ARG CUDA_VERSION=9.2
ARG LINUX_VERSION=ubuntu16.04
ARG CC_VERSION=5
ARG CXX_VERSION=5
ARG PYTHON_VERSION=3.6

FROM gpuci/rapidsai-base:cuda${CUDA_VERSION}-${LINUX_VERSION}-gcc${CC_VERSION}-py${PYTHON_VERSION}

# Install htslib dependencies
RUN apt-get update
RUN apt-get install -y tabix \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libcurl4-gnutls-dev

# Install htslib
RUN git clone --recursive https://github.com/samtools/htslib && cd htslib && make -j16 install


