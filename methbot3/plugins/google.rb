
IrcCommandManager.register ['google','g'],
                           'google <search>' do |m|
  m.reply GoogleCommand.run(m)
end

IrcCommandManager.register 'news', 'news <search>' do |m|
  m.reply GoogleNewsCommand.run(m)
end

IrcCommandManager.register ['desc','d'], 'desc <search>' do |m|
  m.reply GoogleCommand.desc(m.args.join(' '))
end

require 'mechanize'
class GoogleCommand
  class << self
    @@max_results = 3
    @@agent = WWW::Mechanize.new
    @@page = @@agent.get('http://google.com')
    @@form = @@page.form_with(:name => 'f')
	def desc query
		query = "site:wikipedia.org #{query}"
	      form = @@form.dup
	      form.q = query
	      result = form.submit
		links = result.links.select{|l|l.attributes['class']=='l'}
		return "No results found" if links.empty?
		link = GoogleLink.parse links.first.href
		parser = result.parser
		content = parser.search('div.s').first
		return "No results found" if content.nil?
		content.css('cite, span.gl').each { |n| n.remove }
		content.content + " #{link}"
	end
    def run m
      query = m.args.join(' ')
      return m.reply("Missing search") if query.empty?
      count = 0
      links = search( query )
      return "No results found" if links.empty?
      formatted = ""
      links[0..(@@max_results-1)].each do |link|
        t = GoogleLink.parse( link.href )
        r = "(#{count+=1}) #{link.text} #{t}"
        # keep limited to one line of irc
        break if formatted.length + r.length > 230
        formatted += "#{r} "
      end
      "Results: #{formatted}"
    end
    def search query
      form = @@form.dup
      form.q = query
      result = form.submit
      result.links.select{|l|l.attributes['class']=='l'}
    end
  end
end

require 'uri'
require 'rss'
class GoogleNewsCommand
  class << self

    @@max_results = 3
    @@search = "http://www.google.com/news"+
               "?hl=en&ned=us&q=[[query]]&ie=UTF-8&nolr=1&output=rss"

    def run m
      search m.args.join(' ')
    end

    def search query
      count = 0
      formatted = ""
      parsed = parse(query)
      return "Query failed" if parsed.nil?
      items = parsed.items
      return "No results found" if item.nil? or items.empty?
      items[0..(@@max_results-1)].each do |item|
        link = GoogleLink.parse(item.link.split('url=')[1])
        title = WWW::Mechanize::Util::html_unescape( item.title )
        r = "(#{count+=1}) #{title} #{link}"
        # keep limited to one line of irc
        break if formatted.length + r.length > 230
        formatted += "#{r} "
      end
      "Results: #{formatted}"
    end

    def url query
      query = URI.escape query
      @@search.sub('[[query]]',query)
    end

    def parse query
      rss = RSS::Parser.parse(url(query))
    rescue RSS::InvalidRSSError
      RSS::Parser.parse(url(query),false)
    end

  end
end

class GoogleLink
  class << self
    def parse url
      return url if url.length < 40
      t = TinyUrl.new( url )
      t.tiny || t.original
    end
  end
end

