# 베이스 이미지로 Ubuntu를 사용합니다.
FROM ubuntu:20.04

# 기본 패키지 업데이트 및 설치
RUN apt-get update && apt-get install -y \
    openssh-server \
    wget \
    tar

# SSH 서버 설정
RUN mkdir /var/run/sshd
RUN echo 'ubuntu:G06gcxB1KF' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 필요한 디렉토리 생성
RUN mkdir -p /usr/local/frp

# FRP 클라이언트 다운로드 및 설치
RUN wget -qO- https://github.com/fatedier/frp/releases/download/v0.41.0/frp_0.41.0_linux_amd64.tar.gz | tar -xz -C /usr/local/frp --strip-components=1

# FRP 클라이언트 설정
RUN echo '
[common]
server_addr = 146.56.180.111
server_port = 80

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 25520

[custom_port]
type = tcp
local_ip = 127.0.0.1
local_port = 25565
remote_port = 25596
' > /usr/local/frp/frpc.ini

# Entrypoint 스크립트 작성
RUN echo '#!/bin/bash\n\
/usr/local/frp/frpc -c /usr/local/frp/frpc.ini &\n\
/usr/sbin/sshd -D\n' > /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# 컨테이너 시작 시 SSH 서버와 FRP 클라이언트 실행
CMD ["/usr/local/bin/start.sh"]

# 도커 컨테이너에서 노출할 포트
EXPOSE 22 25520 25596
