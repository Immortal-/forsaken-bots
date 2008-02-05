class Reload < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("reload",self)
  end
  def help(m=nil, topic=nil)
    "reload [plugin] => Reloads the given [plugin]"
  end
  def command m
=begin
    begin
      ip = Resolv.getaddress('chino.homelinux.org')
    rescue Resolv::Error
      m.reply "Sorry, I had an error..."
      Irc::Client.logger.error "#{$!}\n#{$@.join('\n')}"
      return
    end
    if ip.nil? || m.source.ip != ip
      puts "Unauthorized: #{m.source.ip}"
      m.reply "Unauthorized"
      return
    end
=end
    command = m.params.shift
    case command
    when "",nil
      plugins = @bot.plugin_manager.reload_all
      m.reply "Reloaded Plugins: #{plugins.join(', ')}"
    else
      # use command name to find plugin
      if c = @bot.command_manager.commands[command]
        plugin = c[:obj].class.name.snake_case
      # default use plugin name
      else
        plugin = command
      end
      #
      unless @bot.plugin_manager.exists?(plugin)
        m.reply "Plugin '#{plugin}' does not exist."
        return
      end
      unless @bot.plugin_manager.enabled?(plugin)
        m.reply "Plugin '#{plugin}' is not enabled."
        return
      end
      unless @bot.plugin_manager.plugins[plugin]
        if (error = @bot.plugin_manager._load(plugin)) === true
          m.reply "Plugin '#{plugin}' loaded"
        else
          m.reply "Plugin '#{plugin}' failed to load.  " +
                  error
        end
        return
      end
      if (error = @bot.plugin_manager.plugins[plugin].reload) === true
        m.reply "Plugin '#{plugin}' reloaded"
      else
        m.reply "Plugin '#{plugin}' failed to reload:  "+
                error
      end
    end
  end
end
