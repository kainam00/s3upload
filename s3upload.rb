#!/usr/bin/env ruby
require 'aws-sdk'
require 'yaml'
require 'getoptlong'

# Check args
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT ]
)

config = ''
repetitions = 1
opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
s3upload.rb [OPTION] ... SOURCE-FILE DEST-BUCKET-URL

-h, --help:
   show help

--config filename.yaml, -c filename.yaml:
   filename of the config file, which should be a YAML file containing the following:
     access_key_id: MY_AWS_CREDENTIALS
     secret_access_key: MY_AWS_CREDENTIALS
     region: us-east-1

SOURCE-FILE: The file to upload.

DEST-BUCKET-URL: The destination bucket location URL, i.e. s3://mybucket/myfolder/myotherfolder/
      EOF
      exit 0
    when '--config'
      config = YAML.load(File.read(arg))
  end
end

if ARGV.length != 2
  puts "Missing source or destination args. Try running --help"
  exit 0
end

source = ARGV.shift
destination = ARGV.shift

# Figute out sources and destinations
filename = File.basename(source)

bucketname = destination.split("/")[2]
if destination[ -1,1 ] == "/"
  objectkey = destination.split("/")[3..destination.split("/").length-1].join("/") + "/" + filename
else
  objectkey = destination.split("/")[3..destination.split("/").length].join("/")
end

obj = Aws::S3::Object.new(
  # Pass credentials
  region: config["region"],
  # Below needs to get commented out if we're using roles
  credentials: Aws::Credentials.new(config["access_key_id"], config["secret_access_key"]), bucket_name: bucketname, key: objectkey
)
obj.upload_file(source)
obj.public_url
