require 'set'
require 'hangman_game'

# List of hangman words loaded from a text file (one word per line.)
class HangmanWordlist
   attr_reader :words

   # Creates a word list from the given file. The file should have one word per
   # line, and all of the words must pass HangmanGame.acceptable_word?. Those
   # that don't pass will be left out.
   def initialize file
      word_set = Set.new

      File.open(file, "r") do |f|
         f.each_line do |raw_line|
            line = raw_line.strip.upcase

            if HangmanGame.acceptable_word? line
               word_set.add line
            end
         end
      end

      @words = word_set.to_a.freeze

      Random.srand
   end

   def size
      @words.size
   end

   def random_word
      @words[Random.rand(self.size)]
   end
end
