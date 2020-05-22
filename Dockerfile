FROM golang:1.14-alpine AS builder
LABEL maintainer="Exagone313"

RUN apk add --update gcc musl-dev git \
	&& addgroup -S build \
	&& adduser -S build -G build

USER build
ENV GOPATH /tmp/buildcache
ARG GIT_COMMIT=19069f50ec854414d78d5fe3a985aee72d02835f
RUN git clone https://github.com/joohoi/acme-dns.git /tmp/acme-dns \
	&& cd /tmp/acme-dns \
	&& git checkout $GIT_COMMIT \
	&& CGO_ENABLED=1 go build

FROM alpine:latest

RUN mkdir -p /etc/acme-dns /var/lib/acme-dns \
	&& apk --no-cache add ca-certificates \
	&& update-ca-certificates \
	&& addgroup -S acmedns \
	&& adduser -S acmedns -G acmedns

COPY --from=builder --chown=root:root /tmp/acme-dns/acme-dns /tmp/acme-dns/LICENSE /usr/local/bin/
RUN chmod 755 /usr/local/bin/acme-dns

USER acmedns
ENTRYPOINT ["/usr/local/bin/acme-dns"]
