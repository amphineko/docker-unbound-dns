FROM alpine:3.13 AS build

RUN apk add --no-cache curl

WORKDIR /usr/src/unbound

ARG UNBOUND_URL=https://www.nlnetlabs.nl/downloads/unbound/unbound-1.14.0.tar.gz
ARG UNBOUND_SHA256=6ef91cbf02d5299eab39328c0857393de7b4885a2fe7233ddfe3c124ff5a89c8

RUN curl -fsSL --retry 3 "${UNBOUND_URL}" -o unbound.tar.gz \
	&& echo "${UNBOUND_SHA256}  unbound.tar.gz" | sha256sum -c - \
	&& tar xzf unbound.tar.gz --strip 1

RUN apk add --no-cache alpine-sdk expat-dev hiredis-dev libevent-dev libmnl-dev libsodium-dev openssl-dev protobuf-c-dev

RUN ./configure \
	--disable-rpath \
	--enable-cachedb \
	--enable-dnscrypt \
	--enable-dnstap \
	--enable-pie \
	--enable-subnet \
	--enable-relro-now \
	--enable-tfo-client \
	--enable-tfo-server \
	--libdir=/usr/lib \
	--with-libevent \
	--with-pidfile=/run/unbound.pid \
	--with-pthreads \
	--with-dnstap-socket-path=/run/dnstap.sock \
	--with-libhiredis \
	--with-rootkey-file=/var/lib/unbound/root.key

ARG BUILD_CONCURRENCY=1

RUN make -j ${BUILD_CONCURRENCY} && make install DESTDIR=/build

FROM alpine:3.13

COPY --from=build /build /

RUN set -ex \
	# add dependencies
	&& apk add --no-cache ca-certificates dns-root-hints dnssec-root expat hiredis libevent libmnl libsodium openssl protobuf-c tini \
	# add run-time user
	&& addgroup -S unbound \
	&& adduser -SG unbound unbound \
	# add run-time paths
	&& mkdir -p /var/lib/unbound \
	&& cp /usr/share/dns-root-hints/named.root /var/lib/unbound/named.root \
	&& cp /usr/share/dnssec-root/trusted-key.key /var/lib/unbound/root.key \
	&& chown -R unbound:unbound /var/lib/unbound \
	# add privilege
	&& setcap 'cap_setgid+ep cap_net_bind_service+ep' /usr/local/sbin/unbound

USER unbound

EXPOSE 53

ENTRYPOINT [ "/sbin/tini", "--" ]

CMD [ "/usr/local/sbin/unbound", "-c", "/usr/local/etc/unbound/unbound.conf", "-d" ]
