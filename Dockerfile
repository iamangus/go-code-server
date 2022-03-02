FROM alpine:3.15

ENV GLIBC_VERSION 2.35

#install glibc
RUN \
   apk add --update curl && \
   curl -Lo glibc.apk "https://github.com/ljfranklin/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}-arm64/glibc-${GLIBC_VERSION}.apk" && \
   curl -Lo glibc-bin.apk "https://github.com/ljfranklin/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}-arm64/glibc-bin-${GLIBC_VERSION}.apk" && \
   apk add --allow-untrusted glibc-bin.apk glibc.apk && \
   /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
   echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
   apk del curl && \
   rm -rf glibc.apk glibc-bin.apk /var/cache/apk/*
   
 ENV \
   # container/su-exec UID \
   EUID=1001 \
   # container/su-exec GID \
   EGID=1001 \
   # container/su-exec user name \
   EUSER=vscode \
   # container/su-exec group name \
   EGROUP=vscode \
   # should user shell set to nologin? (yes/no) \
   ENOLOGIN=no \
   # container user home dir \
   EHOME=/home/vscode \
   # code-server version \
   VERSION=4.0.2

COPY code-server /usr/bin/
RUN chmod +x /usr/bin/code-server

# Install dependencies
RUN \
   apk --no-cache --update add \
   bash \
   curl \
   git \
   gnupg \
   nodejs \
   openssh-client

RUN \
   wget https://github.com/cdr/code-server/releases/download/v$VERSION/code-server-$VERSION-linux-amd64.tar.gz && \
   tar x -zf code-server-$VERSION-linux-amd64.tar.gz && \
   rm code-server-$VERSION-linux-amd64.tar.gz && \
   rm code-server-$VERSION-linux-amd64/node && \
   rm code-server-$VERSION-linux-amd64/code-server && \
   rm code-server-$VERSION-linux-amd64/lib/node && \
   mv code-server-$VERSION-linux-amd64 /usr/lib/code-server && \
   sed -i 's/"$ROOT\/lib\/node"/node/g'  /usr/lib/code-server/bin/code-server

ENTRYPOINT ["entrypoint-su-exec", "code-server"]
CMD ["--bind-addr 0.0.0.0:8080"]
