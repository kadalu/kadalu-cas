# Kadalu Content Addressable Storage

## Features

- Works with any back end(Directory, Kadalu Storage, GlusterFS) that provides mounted path and supports hard links.
- Buckets authentication is managed using a config file. No other state needs to be persisted.
- De-duplication - No duplicate storage across the buckets.
- Content based addressing - If the hash of the file is known, read the content by using the hash.

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

Add the admin token hash and root directory. Root directory can be any path that supports hardlinks or mount path of Kadalu Storage/GlusterFS Volume.

```yaml
# File: kadalu.cas.vol1.yml
port: 4001
global_admins:
  - 8ac62d75482d5d64df768d7cc863a71a33ef2d58f2b8ec5aac3eb9595324b1b0
rootdir: "/mnt/vol1"
buckets:
  - name: app
    public: true
  - name: photos
    admins:
      - a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
    readers:
      - b3a8e0e1f9ab1bfe3a36f231f676f78bb30a519d2b21e6c530c0eee8ebb4a5d0
```

Now start the Kadalu CAS server by running

```console
$ ./bin/kadalu-cas kadalu.cas.vol1.yml
```

Upload a file using the curl command

```
$ curl -i -XPOST -H "Authorization: Bearer 3dfdf4b9-3130-4264-ba2e-570afe74dd08" \
    http://localhost:4001/photos/hello.png -F "data=@/tmp/hello.png"
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
    http://localhost:4001/photos/e67413efc0bb83f7f1e46179448d4f586567949d4d6496928950ded66a7d7f08
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
    http://localhost:4001/photos/hello.png
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

Upload all files from a directory easily by writing simple scripts (Example: Ruby)

```ruby
upload_dir="/home/ubuntu/projects/webapp"
token = "b0bffbc9-044e-465b-9eb9-df40745e877f"
url = "http://localhost:4001"
bucket = "app"

Dir["#{upload_dir}/**/*"].each do |file|
  unless File.directory?(file)
    upload_name = file.gsub("#{upload_dir}/", "")
    puts "Uploading #{file}"
    puts `curl -i -XPOST -H "Authorization: Bearer #{token}" #{url}/#{bucket}/#{upload_name} -F "data=@#{file}"`
  end
end
```

If the bucket is public as shown in the config example, the webapp can be accessed as http://localhost:4001/app
