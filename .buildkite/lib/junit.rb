#!/usr/bin/env ruby

# Reads a list of junit files and returns a nice annotation on STDOUT
#
# Usage: junit.rb junit-1.xml junit-2.xml junit-3.xml

require 'nokogiri'
require 'tempfile'

class Failure < Struct.new(:name, :classname, :body, :job); end

rspec_files = ARGV
all_failures = []

rspec_files.each do |file|
  STDERR.puts "--- :junit: Parsing #{file}"
  job = file[/rspec-(.*).xml$/, 1]
  xml = File.read(file)
  doc = Nokogiri::XML(xml)

  doc.search('//testcase').each do |testcase|
    name = testcase['name']
    classname = testcase['classname']
    failures = testcase.search("failure")

    if failures.any?
      failures.each do |failure|
        all_failures << Failure.new(name, classname, failure.text.chomp.strip, job)
      end
    end
  end
end

STDERR.puts "--- ❓ Checking failures"

if all_failures.empty?
  STDERR.puts "No failures, all good!"
  exit 0
else
  STDERR.puts "There are #{all_failures.length} errors... (boo)"
end

STDERR.puts "--- ✍️ Preparing annotation"

buffer = ""

if all_failures.length > 10
  buffer << "There were #{all_failures.length} failures, showing the first 10:\n\n"
else
  buffer << "There were #{all_failures.length} failures:\n\n"
end

all_failures.first(10).each do |failure|
  buffer << "<details>\n"
  buffer << "<summary><code>#{failure.name} in #{failure.classname}</code></summary>\n\n"
  buffer << "<code><pre>#{failure.body}</pre></code>\n\n"
  buffer << %{in <a href="##{failure.job}">Job ##{failure.job}</a>\n}
  buffer << "</details>"
  buffer << "\n\n\n"
end

STDOUT.puts buffer
