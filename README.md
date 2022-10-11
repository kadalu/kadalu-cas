# Kadalu Content Addressable Storage

Build the `kadalu-cas` binary by running

```
shards build
```

Generate a Admin Token by running `uuidgen` command.

```console
$ uuidgen
3dfdf4b9-3130-4264-ba2e-570afe74dd08
$ echo -n 3dfdf4b9-3130-4264-ba2e-570afe74dd08 | sha256sum
8ac62d75482d5d64df768d7cc863a71a33ef2d58f2b8ec5aac3eb9595324b1b0 -
```

Add the admin token hash and root directory (Mount path) of Kadalu Storage or GlusterFS Volume.

```yaml
# File: kadalu.cas.vol1.yml
port: 4001
admins:
  - 8ac62d75482d5d64df768d7cc863a71a33ef2d58f2b8ec5aac3eb9595324b1b0
rootdir: "/mnt/vol1"
```

Now start the Kadalu CAS server by running

```console
$ ./bin/kadalu-cas kadalu.cas.vol1.yml
```

Upload a file using the curl command

```
$ curl -i -XPOST -H "Authorization: Bearer 3dfdf4b9-3130-4264-ba2e-570afe74dd08" \
    http://localhost:4001/hello.png -F "data=@/tmp/hello.png"
HTTP/1.1 200 OK
Connection: keep-alive
X-Powered-By: Kemal
Content-Type: application/json
Content-Length: 75

{"hash":"e67413efc0bb83f7f1e46179448d4f586567949d4d6496928950ded66a7d7f08"}
```

Now access the file using path or hash as required.

```
$ curl -i -XGET -H "Authorization: Bearer 3dfdf4b9-3130-4264-ba2e-570afe74dd08" \
    http://localhost:4001/e67413efc0bb83f7f1e46179448d4f586567949d4d6496928950ded66a7d7f08
HTTP/1.1 200 OK
Connection: keep-alive
X-Powered-By: Kemal
Content-Type: application/octet-stream
Accept-Ranges: bytes
X-Content-Type-Options: nosniff
Content-Length: 2550

Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
```

```
$ curl -i -XGET -H "Authorization: Bearer 3dfdf4b9-3130-4264-ba2e-570afe74dd08" \
    http://localhost:4001/hello.png
HTTP/1.1 200 OK
Connection: keep-alive
X-Powered-By: Kemal
Content-Type: image/png
Accept-Ranges: bytes
X-Content-Type-Options: nosniff
Content-Length: 2550

Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
```
