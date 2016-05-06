require 'net/http'
require 'json'
require 'uri'
require 'pathname'

$appId = "-"
$appKey = "-"
$fileApi_prefix = "https://api.parse.com/1/files/"
$objectApi = "https://api.parse.com/1/classes/Faces"

$counter = 1

def uploadFile(fname, value)
#create http request
uri = URI.parse($fileApi_prefix + fname)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
req = Net::HTTP::Post.new(uri.request_uri, initheader = {
	'X-Parse-Application-Id' => $appId,
	'X-Parse-REST-API-Key' => $appKey,
	'Content-Type' => 'image/png'
	})
req.body = value
#send request
res = http.request(req)
data = JSON.parse(res.body)
#puts "response #{res.body}"
associateObject(fname, data['name'])
end

def associateObject(fname, fileAddress)
#create http request
uri = URI.parse($objectApi)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
req = Net::HTTP::Post.new(uri.request_uri, initheader = {
	'X-Parse-Application-Id' => $appId,
	'X-Parse-REST-API-Key' => $appKey,
	'Content-Type' => 'application/json'
	})
req.body = {
	name: fname,
	tag: "new",
	picture: {
		'name' => fileAddress,
		'__type' => "File"
	}
	}.to_json
#send request
res = http.request(req)
puts "#{$counter}. response #{res.body}"
$counter += 1
end

#list all png names
pngs = `ls`.split("\n")
for png in pngs
	if png.include? "png" then
		f = File.read(png)
		uploadFile(png, f)
	end
end



