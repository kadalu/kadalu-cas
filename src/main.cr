require "option_parser"

require "kemal"

require "./routes"
require "./cas_options"

config_file = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: kadalu-cas CONFIG_FILE [arguments]"
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end

  parser.unknown_args do |pargs|
    if pargs.size == 0
      STDERR.puts "Config file not provided"
      exit 1
    end
    config_file = pargs[0]
  end
end

if config_file == ""
  STDERR.puts "Invalid Config file"
  exit 1
end

CasOptions.options = CasOptions::Options.from_yaml(File.read(config_file))

def unauthorized(env, message)
  env.response.status_code = 401
  env.response.content_type = "application/json"
  env.response.print ({"error": "Unauthorized. #{message}"}).to_json
end

class AuthHandler < Kemal::Handler
  exclude ["/ping"], "GET"

  def call(env)
    return call_next(env) if exclude_match?(env)

    auth = env.request.headers["Authorization"]?
    token = ""
    unless auth.nil?
      bearer, _, token = auth.partition(" ")
      if bearer.downcase != "bearer" || token == ""
        return unauthorized(env, "Invalid Authoriation header")
      end
    end
    env.set("token", token)

    call_next(env)
  end
end

add_handler AuthHandler.new

Kemal.run do |config|
  server = config.server.not_nil!
  server.bind_tcp "0.0.0.0", CasOptions.options.port, reuse_port: true
end
