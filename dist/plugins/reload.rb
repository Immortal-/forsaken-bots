class Reload < Meth::Plugin
  def help m=nil
    "reload [plugin] => Reloads the given [plugin]"
  end
  def command m
    if m.source.ip != Resolv.getaddress('chino.homelinux.org')
      puts "Unauthorized: #{m.source.ip}"
      m.reply "Unauthorized"
      return
    end
    plugin = m.params.shift
    case plugin
    when "",nil
      m.reply help
    else
      unless @bot.plugin_manager.enabled?(plugin)
        m.reply "Plugin is not loaded"
        return
      end
      if @bot.plugin_manager._load(plugin)
        m.reply "Plugin '#{plugin}' reloaded"
      else
        m.reply "Plugin '#{plugin}' failed to reload."
      end
    end
  end
end
