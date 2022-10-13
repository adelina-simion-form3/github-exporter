FROM 288840537196.dkr.ecr.eu-west-1.amazonaws.com/tech.form3/golang:1.19.2-alpine3.16-f3-1.0.2 AS build
LABEL maintainer="Form3"

ENV GO111MODULE=on

COPY ./ /app
WORKDIR /app

# hadolint ignore=DL3018
RUN apk --no-cache add git

RUN go mod download \
    && CGO_ENABLED=0 go test ./... \
    && GOOS=linux CGO_ENABLED=0 go build -o /bin/main

FROM 288840537196.dkr.ecr.eu-west-1.amazonaws.com/tech.form3/alpine:3.16.2-f3-1.0.2

RUN apk --no-cache add ca-certificates \
     && addgroup exporter \
     && adduser -S -G exporter exporter
ADD VERSION .
USER exporter
COPY --from=build /bin/main /bin/main
ENV LISTEN_PORT=9171
EXPOSE 9171
ENTRYPOINT [ "/bin/main" ]
