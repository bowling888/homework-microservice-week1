FROM alpine:3.20
WORKDIR /app
RUN apk add --no-cache bash socat

COPY server.sh /app/server.sh
RUN chmod +x /app/server.sh

EXPOSE 8080
CMD ["sh","-c","socat TCP-LISTEN:8080,reuseaddr,fork EXEC:\"/app/server.sh\""]

