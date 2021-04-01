# Docker API

## Push image
#### 1. Save image as `.tar.gz`
$ docker save -o `output package name` `image:tag`
*     docker save -o hello.tar.gz hello-world:1.0

#### 2. Comput sha256 value of `.tar.gz`
$ sha256sum < `output package name`
*     sha256sum < hello.tar.gz 

#### 3. Gunzip
$ gunzip < `output package name` | sha256sum
*     gunzip < hello.tar.gz | sha256sum
$ stat -c%s `output package name`
*     stat -c%s hello.tar.gz  ==> 24576
#### 4. Make config.json
diff_ids => ==From step 2.== [ sha256sum < `output package name` ]
```json
echo '{
      "architecture": "amd64",
      "os": "linux",
      "config": {
        "Entrypoint": ["sh", "/hello"]
      },
      "rootfs": {
        "type": "layers",
        "diff_ids": [
          "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        ]
      }
    }' > config.json
```
#### 5. Make manifest.json
##### :sunflower: compute digest
1. config.digest 
*     sha256sum < config.json
2. layers.digest 
*     sha256sum < hello.tar.gz

3. prepare manifest.json

```json
echo '{
      "schemaVersion": 2,
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "config": {
        "mediaType": "application/vnd.docker.container.image.v1+json",
        "size": 295,
        "digest": "sha256:8d06f10e328013cbab94877fd26138a950f93711335137aa06fa56143b103372"
      },
      "layers": [
        {
          "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
          "size": 24576,
          "digest": "sha256:20ff40e715b84e6c8c9dd665f4bad5fea13e1f9c45f34379ecd1310297e51f5b"
        }
      ]
    }' > manifest.json
```

---
### Upload image.tar.gz

#### 1.1 POST digest
*  digest : docker images --digests

==curl -L -u -X POST "https://sandy.registry.com:5000/v2/`IMAGE_NAME`/blobs/uploads/?digest=`sha256:xxxxx`==

* :small_red_triangle:export Location= (from returned)

#### 1.2 PATCH data-binary
==curl -u -L -X PATCH $Location --data-binary @`image.tar.gz` -H "Content-Type: application/octet-stream" -i==
* :small_red_triangle:export Location= (from returned)

#### 1.3 PUT 
* digest : sha256sum < hello.tar.gz

==$ curl -u -X PUT "$Location&digest=sha256:xxxxx" -i==

#### If success return `HTTP/1.1 201 Created`
---
### Upload config.json

#### 2.1 Get Location
==curl -L -u testuser:testpassword -X POST "https://sandy.registry.com:5000/v2/`IMAGE_NAME`/blobs/uploads/" -i==

* :small_red_triangle:export Location= (from returned)

#### 2.2 PATCH data-binary
==curl -u  $Location \
      -X PATCH \
      --data-binary `@config.json` \
      -H "Content-Type: application/octet-stream" -i==
* :small_red_triangle:export Location= (from returned)

#### 2.3 PUT
* digest : sha: sha256sum < config.json

==curl -u -X PUT "$Location&digest=`sha256:xxxx`" -i==
#### If success return `HTTP/1.1 201 Created`
---
### Upload manifest.json
==curl -u -X PUT "https://sandy.registry.com:5000/v2/`IMAGE_NAME`/manifests/`TAG`" \
      --data-binary `@manifest.json` \
      -H "Content-Type: application/vnd.docker.distribution.manifest.v2+json" -i==
#### If success return `HTTP/1.1 201 Created`
---
## Pull image

#### 1.Get image manifests
==curl -u https://sandy.registry.com:5000/v2/`IMAGE_NAME`/manifests/`TAG` \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -i==
#### If success return `HTTP/1.1 200 OK and Config`

:::spoiler config example
```
{
      "schemaVersion": 2,
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "config": {
        "mediaType": "application/vnd.docker.container.image.v1+json",
        "size": 295,
        "digest": "sha256:8d06f10e328013cbab94877fd26138a950f93711335137aa06fa56143b103372"
      },
      "layers": [
        {
          "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
          "size": 24576,
          "digest": "sha256:20ff40e715b84e6c8c9dd665f4bad5fea13e1f9c45f34379ecd1310297e51f5b"
        }
      ]
    }
```
:::

---

#### 2.Blobs config.json
* SHA256 : from ==Step 1.==config.digest

==curl -u https://sandy.registry.com:5000/v2/`IMAGE_NAME`/blobs/`SHA256` \
       -L \
       -o config.json==

* cat config.json
#### If success return `HTTP/1.1 200 OK and Config`
* LAYER ID `sha256:xxxx`, from ==Step 1.== layers.digest

:::spoiler returned example
```
HTTP/1.1 200 OK
Accept-Ranges: bytes
Cache-Control: max-age=31536000
Content-Length: 295
Content-Type: application/octet-stream
Docker-Content-Digest: sha256:8d06f10e328013cbab94877fd26138a950f93711335137aa06fa56143b103372
Docker-Distribution-Api-Version: registry/2.0
Etag: "sha256:8d06f10e328013cbab94877fd26138a950f93711335137aa06fa56143b103372"
X-Content-Type-Options: nosniff
Date: Tue, 05 May 2020 07:07:31 GMT

{
      "architecture": "amd64",
      "os": "linux",
      "config": {
        "Entrypoint": ["sh", "/hello"]
      },
      "rootfs": {
        "type": "layers",
        "diff_ids": [
          "LAYER ID",
        ]
      }
    }
```
:::


---
#### 3.Blobs layer.tar.gz
* LAYER ID `sha256:xxxx`, from ==Step 1.== layers.digest

==curl -u t https://sandy.registry.com:5000/v2/`IMAGE_NAME`/blobs/`sha256:xxxxx` \
      -L \
      -o layer.tar.gz==
#### If success return `HTTP/1.1 200 OK and Config`
---
#### 4.Make manifest.json
```json
echo '[
  {
    "Config":"config.json",
    "RepoTags":["IMAGE_NAME`:`TAG`"],
    "Layers": [
      "layer.tar.gz"
    ]
  }
]' > manifest.json
```
---
#### 5.tar

```
$ 
$ docker load < layer.tar.gz
$ docker run
```
---
### Other APIs
1. curl -u testuser:testpassword -X GET "https://sandy.registry.com:5000/v2/`IMAGE_NAME`/tags/list"
2. curl -u testuser:testpassword -X GET https://sandy.registry.com:5000/v2/_catalog

---
##### Ref.
1. https://peihsinsu.gitbooks.io/docker-note-book/content/docker-save-image.html
2. https://containers.gitbook.io/build-containers-the-hard-way/
3. https://pspdfkit.com/blog/2019/docker-import-export-vs-load-save/
4. https://docs.docker.com/registry/