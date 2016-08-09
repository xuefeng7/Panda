
class Launcher

  def initialize(commands_list)
    #Expected to be an array of command string
    @commands_list = commands_list
  end

    def execute
    p_threads = @commands_list.map do |command|
      Process.detach(Process.spawn(command))
    end
    p_threads.each(&:join)
   end

end

#api keys
apiKeys = [ 
  "2ca7f036e1c5e15e5d6d0d85b13da721", 
  "c8d58ff8a0a76f8ffcbe11e214a8beb3",
  "a9278032efdf15b8cbbecdf7fccb526b"]
apiSecrets = [ 
  "X-L2kZIOEkcw77_lHPB-bNZBJpupclOF", 
  "4HEITQKfUg-uPA1e7qn82q3hd__RU_Jz",
  "XXByJ2S115vEHTlK5hqKFCwnoFD2V_gg"]
  
maxFile = 3

# create command lines
command_list = []

for index in 1..maxFile
	command_list << "ruby timelineProcessing.rb #{index} #{apiKeys[index - 1]} #{apiSecrets[index - 1]} 0"
end 

launcher = Launcher.new(command_list)
launcher.execute()