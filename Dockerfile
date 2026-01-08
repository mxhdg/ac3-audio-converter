FROM alpine:3.19

RUN apk add --no-cache ffmpeg bash findutils

COPY ac3convert.sh /usr/local/bin/ac3convert
RUN chmod +x /usr/local/bin/ac3convert

ENTRYPOINT ["/usr/local/bin/ac3convert"]
