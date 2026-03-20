FROM golang:1.22-bookworm AS builder
WORKDIR /app
COPY go.mod ./
COPY main.go ./
RUN go build -o go_service .

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/go_service /app/go_service
EXPOSE 8080
CMD ["/app/go_service"]

