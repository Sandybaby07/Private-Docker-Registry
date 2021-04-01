# Private-Docker-Registry

### Prepare self sign cert
1. [open ssl](https://blog.miniasp.com/post/2019/02/25/Creating-Self-signed-Certificate-using-OpenSSL)
---
### Start Registry Server
1. prepare docker-compose.yaml
2. vi /etc/docker/daemon.json
3. systemctl restart docker
---
### Connect to Register Service
##### 1. Add server host
add ```IP_ADDRESS sandy.registry.com``` to /etc/hosts/

##### 2. Add server cert
```cp server.crt /usr/local/share/ca-certificates/sandy.registry.com.crt```
##### 3. Update cert
```update-ca-certificates```
---
### Push Image
1. docker push `sandy.registry.com:443`/`IMAGE_NAME`:`TAG`
2. docker images
---
### Pull Image
1. docker pull `sandy.registry.com:443`/`IMAGE_NAME`:`TAG`
2. docker images
3. pull.sh
---
### Other APIs
1. curl -u testuser:testpassword -X GET "https://sandy.registry.com:443/v2/`IMAGE_NAME`/tags/list"
2. curl -u testuser:testpassword -X GET https://sandy.registry.com:443/v2/_catalog --cacert `CERT_NAME.crt`