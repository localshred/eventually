$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'eventually'

class SentenceParser
  include Eventually
  
  def initialize(document)
    @document = document
  end
  
  def parse!
    lines = @document.split(/\r?\n/)
    lines.each do |line|
      emit(:line, line)
      words = line.split(/\s+/)
      words.each do |word|
        emit(:word, word)
      end
    end
    self
  end
end

document = %Q{Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus dapibus elit et ligula vestibulum porttitor. Vestibulum tristique suscipit sem eu cursus. Aenean sit amet ligula elit. Morbi venenatis scelerisque viverra. Cras at nisl quis libero rutrum accumsan.

Aenean et nisl felis, nec convallis erat. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus nec purus nunc, sit amet ornare purus. Vestibulum laoreet mattis sem non malesuada. Nunc vitae lectus neque. Duis sit amet velit non nulla facilisis sodales.

Aenean ultrices sapien ac enim lacinia euismod eleifend pulvinar urna. Nulla leo metus, viverra non lacinia at, posuere at leo. Nullam dictum venenatis tristique. Fusce pellentesque felis vitae libero gravida at interdum est lacinia. Nam rhoncus, diam at gravida dictum, odio velit rutrum erat, vitae laoreet nisl tortor at magna.}

parser = SentenceParser.new(document)
parser.on(:line) do |line|
  puts 'Found line with %d characters' % line.length
  puts 'Line = %s' % line
end
parser.on(:word) do |word|
  puts 'Found word = %s' % word
end
parser.parse!

# output
#
# Found line with 264 characters
# Line = Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus dapibus elit et ligula vestibulum porttitor. Vestibulum tristique suscipit sem eu cursus. Aenean sit amet ligula elit. Morbi venenatis scelerisque viverra. Cras at nisl quis libero rutrum accumsan.
# Found word = Lorem
# Found word = ipsum
# Found word = dolor
# ...