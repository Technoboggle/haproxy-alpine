#####################################################################
# use the following commands to build image and upload to dockerhub #
```
#####################################################################
docker build -f build-haproxy.Dckerfile -t technoboggle/haproxy-alpine:2.4-3.12.3 . 
docker run -it -d -p 8000:80 -p 4430:443 --rm --name haproxy technoboggle/haproxy-alpine:2.4-3.12.3
docker tag technoboggle/haproxy-alpine:2.4-3.12.3
docket tag technoboggle/haproxy-alpine:latest
docker login
docker push technoboggle/haproxy-alpine:2.4-3.12.3
docker push technoboggle/haproxy-alpine:latest
docker container stop -t 10 haproxy
#####################################################################
```
