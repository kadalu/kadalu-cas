upload_dir="tmp1"
token = "ABCD"
url = "http://localhost:4001"
bucket = "app"

Dir["#{upload_dir}/**/*"].each do |file|
  unless File.directory?(file)
    upload_name = file.gsub("#{upload_dir}/", "")
    puts "Uploading #{file}"
    puts `curl -i -XPOST -H "Authorization: Bearer #{token}" #{url}/#{bucket}/#{upload_name} -F "data=@#{file}"`
  end
end
