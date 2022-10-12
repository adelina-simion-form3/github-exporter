FROM 288840537196.dkr.ecr.eu-west-1.amazonaws.com/golang:1.19.2-alpine3.16 AS build
LABEL maintainer="Form3"

ENV GO111MODULE=on

COPY ./ /app
WORKDIR /app

COPY form3-palo-alto.crt /usr/local/share/ca-certificates/form3-palo-alto.crt
# hadolint ignore=DL3018
RUN apk --no-cache add ca-certificates git && update-ca-certificates

ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV AWS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

RUN GOPROXY=direct go mod download \
    && CGO_ENABLED=0 go test ./... \
    && GOOS=linux CGO_ENABLED=0 go build -o /bin/main

FROM 288840537196.dkr.ecr.eu-west-1.amazonaws.com/alpine:3.14.0

RUN apk --no-cache add ca-certificates \
     && addgroup exporter \
     && adduser -S -G exporter exporter
ADD VERSION .
USER exporter
COPY --from=build /bin/main /bin/main
ENV LISTEN_PORT=9171
EXPOSE 9171
ENTRYPOINT [ "/bin/main" ]
