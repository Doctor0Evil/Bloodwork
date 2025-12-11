FROM rust:1.82-alpine AS build
WORKDIR /app
RUN apk add --no-cache musl-dev git build-base
COPY . .
RUN cargo build --release -p abo_api

FROM alpine:3.20
WORKDIR /srv
COPY --from=build /app/target/release/abo_api /usr/local/bin/abo_api
EXPOSE 8080
ENTRYPOINT ["abo_api"]
