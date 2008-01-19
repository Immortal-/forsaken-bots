# handles a priv message
class Irc::PrivMessage < Irc::Message

  attr_accessor :replyto, :channel, :source, :message, :to, :personal

  # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG MethBot :,hi 1 2 3
  # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG #tester :MethBot: hi 1 2 3
  # :Deadly_Methods!*@* PRIVMSG #GSP!Forsaken :ip
  def initialize(client, line)
    super(client, line)

    # working copy
#    line = @line.dup

    # :
    # garbage
    line.slice!(/^:/)

    # methods!1000@c-68-36-237-152.hsd1.nj.comcast.net 
    # Deadly_Methods!*@* PRIVMSG #GSP!Forsaken :ip
    # source
    @source = nil
    source = line.slice!(/[^ ]*/)
    # PRIVMSG #GSP!Forsaken :ip
    if source =~ /([^!]*)!([^@]*)@([^\n]*)/
      user = $2
      host = $3
      nick = $1
      # do we know this user allready?
      unless @source = Irc::User.find(client.server,nick) # has more information
        # create a mock user
        @source = Irc::User.new({:server => client.server,
                                 :user   => user,
                                 :host   => host,
                                 :nick   => nick })
      end
    end

    # check ignore list
    return if @client.ignored.include? @source.nick.downcase

    # " PRIVMSG "
    # #GSP!Forsaken :ip
    # garbage
    line.slice!(/ PRIVMSG /)

    # "(MethBot|#tester)"
    # #GSP!Forsaken :ip
    # where this line came from
    @to = line.slice!(/^[^ ]*/)

    # channel line ?
    @channel = (@to =~ /^#/) ? @to : nil

    # personal line ?
    @personal = @channel ? false : true

    # replyto
    @replyto = nil
    if @channel
      @replyto = @channel
    else
      @replyto = @source.nil? ? nil : @source.nick
    end

    # channel object
    @channel = client.channels[@channel.downcase] if @channel

    # " :"
    # ip
    # garbage
    line.slice!(/ :/)

    # ",hi 1 2 3"
    # "MethBot: hi 1 2 3"
    # the rest is the message
    @message = line

    # send it to the user
    @client.event.call('irc.message.privmsg',self)

  end

  def reply message
    @client.say @replyto, message
  end

  def reply_directly message
    @client.say @source.nick, message
  end

end
