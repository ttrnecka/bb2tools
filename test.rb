require 'nokogiri'
require './helpers.rb'

file = File.open(File.join(ROOT,"cache","gman","div1","fixtures.html"))

html_doc = Nokogiri::HTML(file)

puts html_doc.xpath("//a[contains(@href,'match_detail')]").map { |link| link['href'] }
