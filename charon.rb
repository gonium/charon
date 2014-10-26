#!/usr/bin/env ruby
#
################# Configuration ########################################
$num_preview_lines = 30
$basedir = ENV['CHARON_BASEDIR']
########################################################################

require 'rubygems'
require 'listen'
require 'pdf/reader'
require 'highline/import'
require 'fileutils'

trap("SIGINT") { exit! }

if $basedir == nil or not File.directory?($basedir)
  puts "Please define the CHARON_BASEDIR environment variable to point to your document root."
  exit
end

class Rule
  attr_accessor :name, :prio, :regex, :destination
  def initialize(name, prio, regex, destination)
    @name=name
    @prio=prio
    @regex=regex
    @destination=destination
  end
  def match(document)
    if document =~ regex
      return true
    else
      return false
    end
  end
  def describe
    return "#{@name}(#{prio}): Destination #{@destination}"
  end
end

rulebook=[]
rulebook << Rule.new("Versicherungen", 50, /Versicherung/i, "11_Versicherung")
rulebook << Rule.new("Banken", 60, /Banken/i, "12_Banken")
rulebook << Rule.new("Rechnungen", 100, /Rechnung|R E C H N U N G/i, "10_Rechnungen")
rulebook << Rule.new("Sendungsinformation", 110, /Sendungsinformation/i, "90_Gorleben")

rulebook.sort! { |a,b| a.prio <=> b.prio }
#rulebook.each{|r|
#  puts r.describe
#}

say "Charon is transporting the dead."
listener = Listen.to(File.join($basedir, '00_Eingang')) do |modified, src, removed|
  #puts "added files: #{src}" unless src
  src.each do |srcfile|
    # Load PDF
    current_file = File.basename(srcfile)
    puts current_file
    #srcfile = File.join($basedir, '00_Eingang', current_file)
    foo = ask("File #{current_file}: Is the OCR complete?")
    reader = PDF::Reader.new(srcfile)
    text = ""
    reader.pages.each do |page|
      puts "Adding page."
      text += page.text
    end
    # Print the first few lines of the text
    say "####################### Preview of the document #{srcfile} ###################"
    #TODO: The preview is broken.
    #linecnt = 0
    #text.each_line{|line|
    #  if linecnt < $num_preview_lines
    #    say "#{linecnt}: #{line}"
    #    linecnt += 1
    #  end
    #}
    say "##########################################################################"

    candidates = rulebook.select{ |x| x.match(text) }

    if candidates.length() == 0
      say "Sorry, don't know what to do with this"
    else
      # Ask the user which rule to apply
      candidates.each_with_index {|c, i|
        say "#{i} - #{c.describe}"
      }
      action = ask("Please select rule to apply", Integer) {|q|
        q.in = 0..candidates.length-1
      }
      say "Applying rule #{candidates[action].describe}"
      dest_dir = File.join($basedir, candidates[action].destination)
      FileUtils::mkdir_p dest_dir unless File.directory?(dest_dir)
      FileUtils.mv(srcfile, File.join(dest_dir, current_file))
    end
  end
end
listener.start
sleep
