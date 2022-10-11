require "yaml"

module CasOptions
  struct Options
    include YAML::Serializable

    property port = 3001, admins = [] of String, readers = [] of String, rootdir = "./tmp"

    def initialize
    end
  end

  class_property options = Options.new
end
