require 'rubygems'
require 'listen'
require 'highline/import'


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

say "Charon is transporting the dead."
rulebook=[]
rulebook << Rule.new("Rechnungen", 100, /Rechnung/i, "10_Rechnungen")
rulebook << Rule.new("Versicherungen", 50, /Versicherung/i, "11_Versicherung")
rulebook << Rule.new("Banken", 60, /Banken/i, "12_Banken")

rulebook.sort! { |a,b| a.prio <=> b.prio }
rulebook.each{|r|
  puts r.describe
}

listener = Listen.to('00_Eingang') do |modified, added, removed|
  puts "modified: #{modified}"
  puts "added: #{added}"
  puts "removed: #{removed}"
end

listener.start
sleep

# Load PDF

# candidates = rulebook.select{ |x| x.match(text) }
candidates = rulebook

# Ask the user which rule to apply
candidates.each_with_index {|c, i|
  say "#{i} - #{c.describe}"
}
action = ask("Please select action", Integer) {|q|
  q.in = 0..candidates.length-1
}
say "Applying rule #{candidates[action].describe}"
