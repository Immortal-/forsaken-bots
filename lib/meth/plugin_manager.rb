class Meth::PluginManager

  attr_reader :bot, :glob, :plugins

  def initialize(bot)
    # we belong to this bot instance
    @bot = bot
    # path to plugins
    @glob = "#{DIST}/#{bot.config['plugins_path']}/*.rb"
    # plugin instances
    @plugins = {}
    # load plugins
    startup
  end

  # load all the plugins
  def startup
    enabled.each do |plugin|
      begin
        _load plugin
        constant = Object.const_get(plugin.camel_case)
        @plugins[plugin.snake_case] = constant.new(@bot)
      rescue Exception
        puts "----------------------"
        puts "#{$!}\n#{$@.join("\n")}"
        puts "----------------------"
      end
      false
    end
  end

  # list of plugins
  def list
    Dir[@glob].map do |plugin|
      File.basename(plugin).gsub('.rb','')
    end
  end
    
  # path to plugin
  def path plugin
    @glob.gsub('*',plugin.snake_case)
  end

  # plugin executable?
  def executable? plugin
    FileTest.executable?(path(plugin))
  end

  # list of enabled plugins
  def enabled
    list.select{|plugin| plugin if enabled?(plugin) }
  end

  # plugin enabled?
  def enabled? plugin
    return true if @plugins[plugin]
    return true if executable?(plugin)
    false
  end

  # plugin exists?
  def detect plugin
    list.detect{|p| p.downcase == plugin.downcase }
  end

  # loads a plugin
  def _load plugin
    load path(plugin)
    @bot.logger.info "Bot (#{bot.name}) Loaded Plugin (#{plugin.snake_case})"
  end

end