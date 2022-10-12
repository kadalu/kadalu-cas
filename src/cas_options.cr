require "yaml"

module CasOptions
  struct Bucket
    include YAML::Serializable

    property name = "", admins = [] of String, readers = [] of String, public = false
  end

  struct Options
    include YAML::Serializable

    property port = 3001, global_admins = [] of String, buckets = [] of Bucket, rootdir = "./tmp"

    def bucket_admin?(bucket_name, token)
      return true if @global_admins.includes?(token)

      bucket = @buckets.find {|b| b.name == bucket_name}
      return false if bucket.nil?

      bucket.admins.includes?(token)
    end

    def bucket_reader?(bucket_name, token)
      bucket = @buckets.find {|b| b.name == bucket_name}
      return false if bucket.nil?

      return true if bucket.public
      return true if bucket_admin?(bucket_name, token)
      bucket.readers.includes?(token)
    end

    def initialize
    end
  end

  class_property options = Options.new
end
