FROM golang:1.22-alpine AS build
WORKDIR /app
COPY . .
RUN go build -o gateway main.go

FROM alpine:3.20
WORKDIR /srv
COPY --from=build /app/gateway /usr/local/bin/gateway
EXPOSE 8090
ENTRYPOINT ["gateway"]
