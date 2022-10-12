require "kemal"
require "digest/sha256"

require "./cas_options"

before_all do |env|
  env.response.content_type = "application/json"
end

get "/ping" do
  "{}"
end

def hash_path(hash)
  "#{hash[0..1]}/#{hash[2..3]}/#{hash}"
end

post "/:bucket/*" do |env|
  bucket = env.params.url["bucket"]
  filename = env.request.path.gsub("/#{bucket}", "").lstrip("/")

  halt(env, status_code: 403, response: ({"error": "Forbidden"}).to_json) if filename == ""

  token_hash = Digest::SHA256.digest(env.get("token").to_s).hexstring
  unless CasOptions.options.bucket_admin?(bucket, token_hash)
    halt(env, status_code: 403, response: ({"error": "Forbidden"}).to_json)
  end

  hash = ""
  HTTP::FormData.parse(env.request) do |upload|
    content = IO::Memory.new
    IO.copy(upload.body, content)
    hash = Digest::SHA256.digest(content.to_s).hexstring

    full_path = File.join [CasOptions.options.rootdir, bucket, filename]
    hash_path = File.join [CasOptions.options.rootdir, bucket, ".store", hash_path(hash)]
    hash_backend_path = File.join [CasOptions.options.rootdir, ".store", hash_path(hash)]

    Dir.mkdir_p Path[full_path].parent
    Dir.mkdir_p Path[hash_path].parent
    Dir.mkdir_p Path[hash_backend_path].parent

    if File.exists?(full_path)
      halt(env, status_code: 409, response: ({"error": "File already exists"}).to_json)
    end
  
    unless File.exists?(hash_backend_path)
      content.rewind
      File.open(hash_backend_path, "w") do |f|
        IO.copy(content, f)
      end
    end

    File.link(hash_backend_path, full_path)
    unless File.exists?(hash_path)
      File.link(hash_backend_path, hash_path)
    end
  end

  env.response.content_type = "application/json"
  {:hash => hash}.to_json
end

get "/:bucket/*" do |env|
  bucket = env.params.url["bucket"]
  filename = env.request.path.gsub("/#{bucket}", "").lstrip("/")

  # Try opening as index.html if filename is not specified
  filename = "index.html" if filename == ""

  token_hash = Digest::SHA256.digest(env.get("token").to_s).hexstring
  unless CasOptions.options.bucket_reader?(bucket, token_hash)
    halt(env, status_code: 403, response: ({"error": "Forbidden"}).to_json)
  end

  if /^[a-f0-9]{64}$/i =~ filename
    path = File.join [CasOptions.options.rootdir, bucket, ".store", hash_path(filename)]
  else
    path = File.join [CasOptions.options.rootdir, bucket, filename]
  end

  send_file env, path
end
