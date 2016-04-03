require 'net/http'
require 'json'
require 'uri'
require 'thread'

$appId = "ki2K34CINHsa6YwHkQyQR3TL-gzGzoHsz"
$appKey = "N4yp6ICJwu5O1cQOQhBmAFgu"
$uri = URI.parse("https://api.leancloud.cn/1.1/classes/Faces")
$http = Net::HTTP.new($uri.host, $uri.port)
$http.use_ssl = true

$THREAD_LIMIT = 16

def createObject(name, value)
#create http request
req = Net::HTTP::Post.new($uri.request_uri, initheader = {
	'X-LC-Id' => $appId,
	'X-LC-Key' => $appKey,
	'Content-Type' => 'application/json'
	})
req.body = {
	name: name, 
	base64: value
	}.to_json

#send request
res = $http.request(req)
puts "response #{res.body}"
end

#image object array
#separate by maually added delimiter %
base64File = File.open("base64.txt").read.split("%")
count = 1
#threading elements
tags = []
mutex = Mutex.new

packs = []
for data in base64File
	dataArr = data.split("@")
	name = dataArr[0]
	base64 = dataArr[1]
	#puts "file No.#{count} - #{name.gsub("\n", "")}"
	if count > 442 && count < 954 then
		#createObject(name, base64)
		puts "file No.#{count} - #{name.gsub("\n", "")}"
		packs << [name, base64]
	end
	count = count + 1
end

$THREAD_LIMIT.times.map {
  Thread.new(packs, tags) do |packs, tags|
    while pack = mutex.synchronize { packs.pop }
      #tag = pack[0];
      name = pack[0];
      base64 = pack[1];
      mutex.synchronize { createObject(name, base64) }
      #createObject(name, base64) 
    end
  end
}.each(&:join)

