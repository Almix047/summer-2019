require 'httparty'
require 'nokogiri'
require 'open-uri'
require_relative 'util'
require 'pry'

#:reek:InstanceVariableAssumption
class Repo
  URI = 'https://api.github.com/search/repositories'.freeze

  attr_reader :used_by

  def initialize(gem_name)
    collect_repository_info_for gem_name
    @used_by = used_by_count
  end

  def rows
    [
      @repo['name'].to_s,
      "used by #{@used_by}",
      "watched by #{watched_by_count}",
      "#{@repo['watchers_count']} stars",
      "#{@repo['forks_count']} forks",
      "#{contributors_count} contributors",
      "#{@repo['open_issues_count']} issues"
    ]
  end

  private

  def collect_repository_info_for(gem_name)
    api_response = HTTParty.get(URI, query: { q: gem_name })
    @repo = api_response.to_hash['items'].first
    @html = Util.parse_html @repo['html_url']
    @repo
  end

  def contributors_count
    contributors = @html.css("a span[class='num text-emphasized']").last.text
    parse_int(contributors)
  end

  def watched_by_count
    watched_by_count = @html.xpath('/html/body/div[4]/div/main/div[1]/div/ul/li').select do |el|
      el.text.include? 'Watch'
    end.first.text
    parse_int(watched_by_count)
  end

  def used_by_count
    html = Util.parse_html "#{@repo['html_url']}/network/dependents"
    used_by = html.css('a.btn-link:nth-child(1)').text
    parse_int(used_by)
  end

  def parse_int(num_string)
    num_string.gsub(/[^0-9]/, '').to_i
  end
end
