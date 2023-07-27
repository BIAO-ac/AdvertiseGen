FROM nvidia/cuda:10.2-cudnn8-runtime-ubuntu18.04
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse \n" \
	"deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse \n" \
	"deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse \n" \
	"deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse \n" \
	"deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse \n" \
	"deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse \n" \
	"deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse \n" \
	"deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse \n" \
	"deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse \n" \
	"deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse" > /etc/apt/sources.list

RUN mv /etc/apt/sources.list.d/cuda.list /etc/apt/sources.list.d/cuda.list.bk

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Asia/Shanghai apt-get -y install tzdata
RUN echo "Asia/Shanghai" > /etc/timezone && rm /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get -y install xz-utils
COPY ./misc/Python-3.8.13.tar.xz /
RUN mkdir -p /usr/src/python \
    && cd / && tar --extract --directory /usr/src/python --strip-components=1 --file Python-3.8.13.tar.xz \
    && rm Python-3.8.13.tar.xz

RUN apt-get install -y --no-install-recommends autoconf automake bzip2 dpkg-dev file g++ gcc imagemagick \
    libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev libevent-dev libffi-dev libgdbm-dev libglib2.0-dev \
    libgmp-dev libjpeg-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev libmaxminddb-dev \
    libncurses5-dev libncursesw5-dev libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool \
    libwebp-dev libxml2-dev libxslt-dev libyaml-dev make patch unzip xz-utils zlib1g-dev \
    vim netcat iputils-ping libsasl2-dev libsasl2-2 libsasl2-modules-gssapi-mit tofrodos libgl1-mesa-glx \
    tree man-db rsync cron
RUN apt install -y openssh-server net-tools wget

RUN cd /usr/src/python \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure --build="$gnuArch" --enable-loadable-sqlite-extensions --enable-optimizations --enable-option-checking=fatal --enable-shared --with-system-expat --without-ensurepip \
    && nproc="$(nproc)" \
    && make -j "$nproc" PROFILE_TASK='-m test.regrtest --pgo test_fstring test_hashlib test_io test_time test_traceback test_unicode' \
    && make install

RUN cd /usr/src/python; bin="$(readlink -ve /usr/local/bin/python3)"; dir="$(dirname "$bin")"; mkdir -p "/usr/share/gdb/auto-load/$dir"; cp -vL Tools/gdb/libpython.py "/usr/share/gdb/auto-load/$bin-gdb.py";
RUN rm -rf /usr/src/python
RUN ldconfig

RUN python3 -m ensurepip --upgrade
RUN ln -s /usr/local/bin/python3 /usr/bin/python && ln -s /usr/local/bin/pip3 /usr/bin/pip
RUN pip install --upgrade pip -i https://mirrors.cloud.tencent.com/pypi/simple

# jdk, hadoop, hive
ADD ./misc /home/misc
WORKDIR /home/misc
RUN unzip apache-hive-1.2.1-bin.zip
RUN unzip hadoop-3.3.4.zip
RUN unzip jdk1.8.0_152.zip
RUN mv /home/misc/*-site.xml /home/misc/hadoop-3.3.4/etc/hadoop/
RUN mv /home/misc/krb5.conf /etc/
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install krb5-user
RUN echo 'export JAVA_HOME=/home/misc/jdk1.8.0_152\n\
export HADOOP_HOME=/home/misc/hadoop-3.3.4\n\
export HIVE_HOME=/home/misc/apache-hive-1.2.1-bin\n\
export PATH=$PATH:$HIVE_HOME/bin:$JAVA_HOME/bin:$HADOOP_HOME/bin\n\
kinit -kt /home/misc/game_ai.keytab game_ai/dev@HADOOP.HZ.NETEASE.COM' >> /root/.bash_profile

ADD ./requirements.txt /home/
RUN pip install -r /home/requirements.txt -i https://pypi.mirrors.ustc.edu.cn/simple/

ADD ./code /root/diguozhanji/code
WORKDIR /root/diguozhanji

CMD ["sh", "-c", "cat /home/misc/hosts >> /etc/hosts && systemctl enable ssh && /etc/init.d/ssh restart && sleep infinity"]