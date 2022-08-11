FROM ubuntu:latest

RUN apt update && apt install -y openssh-server sudo netcat
RUN apt install -y vim iproute2 inetutils-ping curl
RUN apt install -y wireguard

RUN groupadd -g 1000 lab
RUN useradd -rm -d /home/lab -s /bin/bash -g lab -G sudo -u 1000 lab
RUN echo 'lab:s3cr3t' | chpasswd

RUN service ssh start

EXPOSE 22

CMD ["/usr/sbin/sshd","-D"]
