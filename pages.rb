require 'rubygems'
require 'fattr'
require 'redcloth'
require 'facets/file/write'
require 'haml'

module FromHash
  def from_hash(ops)
    ops.each do |k,v|
      send("#{k}=",v)
    end
  end
  def initialize(ops={})
    from_hash(ops)
  end
end

class Page
  include FromHash
  attr_accessor :raw_text, :page_num, :notes
  fattr(:text) do 
    raw_text.gsub(/\|\|$/,"|").gsub(/\|\|/,"|_. ").gsub(/"git(.*?)"/,'<span class="git-cmd">"git\1"</span>')
  end
  fattr(:raw_html) do
    doc = RedCloth.new(text)
    doc.to_html
  end
  fattr(:final_html) do
    haml = Haml::Engine.new(File.new("page_template.haml").read)
    haml.render(self)
  end
  fattr(:title) { text.scan(/h1.(.*)/).flatten.first.strip }
  fattr(:filename) { File.dirname(__FILE__) + "/pages/page#{page_num}.html" }
  def write!
    File.create(filename,final_html)
    File.create(File.dirname(__FILE__) + "/empty/public/page#{page_num}.html",final_html)
    File.create(File.dirname(__FILE__) + "/pages/page#{page_num}.txt",text)
  end
  def first?
    page_num == 1
  end
  def last?
    page_num == notes.pages.size
  end
end

class Notes
  fattr(:text) do
    File.new("notes.txt").read
  end
  fattr(:pages) do
    res = []
    text.split("h1.")[1..-1].map { |x| "h1." + x }.each_with_index { |x,i| res << Page.new(:raw_text => x, :page_num => i+1, :notes => self) }
    res.reject { |x| x.title == 'Ideas' }
  end
  def create_pages!
    pages.each { |x| x.write! }
  end
end


  Notes.new.create_pages!

