require "kemal"
require "digest/sha256"

require "./cas_options"

before_all do |env|
  env.response.content_type = "application/json"
end

get "/ping" do
  "{}"
end

post "/*" do |env|
  token_hash = Digest::SHA256.digest(env.get("token").to_s).hexstring
  if CasOptions.options.admins.size > 0 && !CasOptions.options.admins.includes?(token_hash)
    halt(env, status_code: 403, response: ({"error": "Forbidden"}).to_json)
  end

  filename = env.request.path.lstrip("/")
  
  halt(env, status_code: 403, response: ({"error": "Forbidden"}).to_json) if filename == ""

  hash = ""
  HTTP::FormData.parse(env.request) do |upload|
    content = IO::Memory.new
    IO.copy(upload.body, content)
    hash = Digest::SHA256.digest(content.to_s).hexstring

    full_path = File.join [CasOptions.options.rootdir, "files", filename]
    hash_path = File.join [CasOptions.options.rootdir, "hashes", hash]

    Dir.mkdir_p Path[full_path].parent
    Dir.mkdir_p Path[hash_path].parent

    if File.exists?(full_path)
      halt(env, status_code: 409, response: ({"error": "File already exists"}).to_json)
    end
  
    unless File.exists?(hash_path)
      content.rewind
      File.open(hash_path, "w") do |f|
        IO.copy(content, f)
      end
    end

    File.link(hash_path, full_path)
  end

  env.response.content_type = "application/json"
  {:hash => hash}.to_json
end
