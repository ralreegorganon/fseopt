FROM alpine:3.12

RUN apk --no-cache add ca-certificates

ADD bin/linux/fseopt /bin/fseopt
ADD /migrations /migrations
ENV FSEOPT_MIGRATIONS_PATH=file:///migrations

ENTRYPOINT ["fseopt"]