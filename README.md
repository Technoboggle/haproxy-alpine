# The following commands to build image and upload to dockerhub
```
docker build -f Dockerfile -t technoboggle/haproxy-alpine:2.4-3.13.2 .
docker run -it -d -p 8000:80 --rm --name myhaproxy technoboggle/haproxy-alpine:2.4-3.13.2
docker tag technoboggle/haproxy-alpine:2.4-3.13.2 technoboggle/haproxy-alpine:latest
docker login
docker push technoboggle/haproxy-alpine:2.4-3.13.2
docker push technoboggle/haproxy-alpine:latest
docker container stop -t 10 myhaproxy


# Supported tags and respective `Dockerfile` links

- [`2.4-dev4`, `2.4`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/2.4/Dockerfile)
- [`2.3.2`, `2.3`, `latest`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/2.3/Dockerfile)
- [`2.2.6`, `2.2`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/2.2/Dockerfile)
- [`2.1.10`, `2.1`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/2.1/Dockerfile)
- [`2.0.19`, `2.0`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/2.0/Dockerfile)
- [`1.9.16`, `1.9`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/1.9/Dockerfile)
- [`1.8.27`, `1.8`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/1.8/Dockerfile)
- [`1.7.12`, `1.7`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/1.7/Dockerfile)
- [`1.6.15`, `1.6`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/1.6/Dockerfile)
- [`1.5.19`, `1.5`](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/1.5/Dockerfile)

# Quick reference

- **Where to get help**:  
  [HAProxy mailing list](mailto:haproxy@formilux.org), [HAProxy Community Slack](https://slack.haproxy.org/) or [#haproxy on FreeNode](irc://chat.freenode.net:6697/haproxy)

- **Where to file issues**:  
  [https://github.com/haproxytech/haproxy-docker-alpine/issues](https://github.com/haproxytech/haproxy-docker-alpine/issues)

- **Maintained by**:  
  [HAProxy Technologies](https://github.com/haproxytech)

- **Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
  [`amd64`](https://hub.docker.com/r/amd64/haproxy/)

- **Image updates**:  
  [commits to `haproxytech/haproxy-docker-alpine`](https://github.com/haproxytech/haproxy-docker-alpine/commits/master), [top level `haproxytech/haproxy-docker-alpine` image folder](https://github.com/haproxytech/haproxy-docker-alpine)  

- **Source of this description**:  
  [README.md](https://github.com/haproxytech/haproxy-docker-alpine/blob/master/README.md)

# What is HAProxy?

HAProxy is the fastest and most widely used open-source load balancer and application delivery controller. Written in C, it has a reputation for efficient use of both processor and memory. It can proxy at either layer 4 (TCP) or layer 7 (HTTP) and has additional features for inspecting, routing and modifying HTTP messages.

It comes bundled with a web UI, called the HAProxy Stats page, that you can use to monitor error rates, the volume of traffic and latency. Features can be toggled on by updating a single configuration file, which provides a syntax for defining routing rules, rate limiting, access controls, and more.

Other features include:

* SSL/TLS termination
* Gzip compression
* Health checking
* HTTP/2
* gRPC support
* Lua scripting
* DNS service discovery
* Automatic retries of failed conenctions
* Verbose logging

![logo](https://www.haproxy.org/img/HAProxyCommunityEdition_60px.png)

# How to use this image

This image is being shipped with a trivial sample configuration and for any real life use it should be configured according to the [extensive documentation](https://cbonte.github.io/haproxy-dconv/) and [examples](https://github.com/haproxy/haproxy/tree/master/examples). We will now show how to override shipped haproxy.cfg with one of your own.

## Create a `Dockerfile`

```dockerfile
FROM haproxytech/haproxy-alpine:2.0
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
```

## Build the container

```console
$ docker build -t my-haproxy .
```

## Test the configuration file

```console
$ docker run -it --rm my-haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

## Run the container

```console
$ docker run -d --name my-running-haproxy my-haproxy
```

You will also need to publish the ports your HAProxy is listening on to the host by specifying the `-p` option, for example `-p 8080:80` to publish port 8080 from the container host to port 80 in the container.

## Use volume for configuration persistency

```console
$ docker run -d --name my-running-haproxy -v /path/to/etc/haproxy:/usr/local/etc/haproxy:ro haproxytech/haproxy-alpine:2.0
```

Note that your host's `/path/to/etc/haproxy` folder should be populated with a file named `haproxy.cfg` as well as any other accompanying files local to `/etc/haproxy`.

## Reloading config

To be able to reload HAProxy configuration, you can send `SIGHUP` to the container:

```console
$ docker kill -s HUP my-running-haproxy
```

To achieve seamless reloads it is required to use `expose-fd listeners` and socket transfers which are not enabled by default. More on this topic is in the blog post [Truly Seamless Reloads with HAProxy](https://www.haproxy.com/blog/truly-seamless-reloads-with-haproxy-no-more-hacks/).

## Enable Data Plane API

[Data Plane API](https://www.haproxy.com/documentation/hapee/2-2r1/reference/dataplaneapi/) sidecar is being distributed by default in all 2.0+ images and to enable it there are a few steps required:

1. define one or more users through `userlist`
2. enable dataplane api process through `program api`
3. enable haproxy.cfg to be read/write mounted in Docker, either by defining volume being r/w or by rebuilding image with your own haproxy.cfg
4. expose dataplane TCP port in Docker with `--expose`

Relevant part of haproxy.cfg is below:

```
userlist haproxy-dataplaneapi
    user admin insecure-password mypassword

program api
   command /usr/bin/dataplaneapi --host 0.0.0.0 --port 5555 --haproxy-bin /usr/sbin/haproxy --config-file /etc/haproxy/haproxy.cfg --reload-cmd "kill -SIGUSR2 1" --reload-delay 5 --userlist haproxy-dataplaneapi
   no option start-on-reload
```

To run such image we would use the following command (note that volume containing haproxy.cfg is mounted r/w and port tcp/5555 is being exposed):

```console
$ docker run -d --name my-running-haproxy --expose 5555 -v /path/to/etc/haproxy:/usr/local/etc/haproxy:rw haproxytech/haproxy-alpine
```

# License

View [license information](https://raw.githubusercontent.com/haproxy/haproxy/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).