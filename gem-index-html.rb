#!/usr/bin/env ruby

require 'nokogiri'
require 'rubygems'

module GemIndex
  def self.index_html
    gems = Gem::Specification.sort_by {|g|g.name.downcase}

    ## filter our older versions?

    builder = Nokogiri::HTML::Builder.new do
      html {
        title "Gem Docs"
        table(:border => 1) {
          tr {
            th "Name"
            th "Version"
            th "Rdoc"
            th "Home"
            th "Summary"
          }
          gems.each do |gem|
            tr {
              td gem.name
              td gem.version
              td {
                a("local",
                  :href => File.join(gem.doc_dir, "rdoc", "index.html"))
              }
              td {
                a("www",
                  :href => gem.homepage)
              }
              td gem.summary
            }
          end
        }
      }
    end
    builder.to_html
  end
end

if __FILE__ == $0
  puts GemIndex.index_html
end

