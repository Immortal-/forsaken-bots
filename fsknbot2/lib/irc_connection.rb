require 'irc_handle_line'
require 'em_protocols_line_text_2'

#
# Public API
#

class IrcConnection < EM::Connection
  class <<self

    @@connection = nil

    def send_line line
      @@connection.send_line line unless @@connection.nil?
    end

    def close
      @@connection.close_connection unless @@connection.nil?
    end

    def privmsg targets, messages, type="PRIVMSG"
      [messages].flatten.each do |message|
        next if message.nil? or !message.respond_to?(:to_s) or message.empty?
        # shrink white space
        message.gsub!(/\s+/," ")
        # irc sends max of 512 bytes to sender
        # this should stop message from behind cut off
        message.to_s.scan(/.{1,230}[^ ]{0,150}/m){|chunk|
          # catch white space only lines
          next if chunk.gsub(/\s/,'').empty?
          # send the line
					[targets].flatten.each do |target|
      	    IrcConnection.send_line "#{type} #{target.downcase} :#{chunk}"
					end
        }
      end
    end

    def chatmsg channel, message, type="PRIVMSG"
      IrcConnection.privmsg channel, message, type
    end

    def who target
      IrcConnection.send_line "WHO #{target}"
    end

    def topic channel, str
      IrcConnection.send_line "TOPIC #{channel} :#{str}"
    end

    def join channels
      [channels].flatten.each do |channel|
        IrcConnection.send_line "JOIN #{channel}"
      end
    end

    def kick nick, message="pwned!", channel="#forsaken" 
      IrcConnection.send_line "KICK #{channel} #{nick} :#{message}"
    end

    def pong token
      IrcConnection.send_line "PONG #{token}"
    end

  end
end

#
#  Instance
#

class IrcConnection < EM::Connection

  include EM::Protocols::LineText2

  def initialize
    status "Startup"
  end

  def post_init
    status "Connected"
    @@connection = self
    send_line "PASS #{$passwd}"
    send_line "USER x x x :x"
    send_line "NICK #{$nick_proper}"
    IrcConnection.join $channels
  end

  def unbind
    status "Disconnected"
		sleep 1
    reconnect $server, $port
    post_init
  end

  def receive_line line
    t=Time.now
		puts
    puts "irc #{t.strftime("%m-%d-%y %H:%M:%S")} >>> (fsknbot2) #{line}"
    close_connection if line.split.first.downcase == "error"
    IrcHandleLine.new line
		puts "Took #{Time.now-t} seconds to process line."
		puts
  rescue Exception
    puts_error __FILE__,__LINE__
  end

end

