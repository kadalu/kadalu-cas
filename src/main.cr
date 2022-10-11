require "option_parser"
require "yaml"

require "kemal"

config_file = ""

struct CasOptions
  include YAML::Serializable

  property port = 3001, admins = [] of String, readers = [] of String

  def initialize
  end
end

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

opts = CasOptions.from_yaml(File.read(config_file))

Kemal.config.port = opts.port
Kemal.run
