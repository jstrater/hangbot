require 'set'

# Game logic & state. Create an instance to start a game, then use the #guess!
# method to progress. The #won? and #lost? methods will tell when the game is
# over, and #partial_solution shows the parts of the target word that have been
# guessed correctly so far.
class HangmanGame
   attr_reader :word, :guess_limit

   # Creates a new game with +word+ as the target.
   #
   # Raises an ArgumentError if +word+ is invalid.
   def initialize word, guess_limit=6
      @word = HangmanGame.guard_word(word).freeze

      # Letters used in the target word. These are the letters the user needs
      # to guess correctly to win.
      @correct_letters = Set.new(
         @word.chars.find_all {|char| HangmanGame.acceptable_guess? char }
      ).freeze

      @guessed_letters = Set.new

      if guess_limit <= 0
         raise ArgumentError, "guess_limit must be higher than 0"
      end

      @guess_limit = guess_limit.freeze
   end

   # Returns a Set containing all of the incorrect guesses so far.
   def incorrect_guesses
      @guessed_letters - @correct_letters
   end

   # Returns a Set of all the correct guesses so far.
   def correct_guesses
      @guessed_letters & @correct_letters
   end

   # Returns a Set of all guesses so far.
   def guesses
      @guessed_letters.clone
   end

   # Returns the remaining number of missed guesses before the game is lost.
   def remaining_misses
      @guess_limit - incorrect_guesses.size
   end

   # Returns an array representing the target word. Letters that have already
   # been guessed are included; letters that have not yet been guessed are nil.
   # Any other characters (spaces, dashes) are included.
   def partial_solution
      @word.chars.map do |letter|
         if HangmanGame::ACCEPTABLE_LETTER =~ letter
            # Letters of the alphabet
            if @guessed_letters.include? letter
               letter
            else
               nil
            end
         else
            # Non-alpha characters
            letter
         end
      end
   end

   # Guesses a letter. Returns true if the letter is in the target word, false
   # if not.
   #
   # Raises HangmanGame::StateError if the game has already ended or the letter
   # has already been guessed.
   def guess! raw_letter
      letter = HangmanGame.guard_guess(raw_letter)

      # Make sure this guess is valid for the current game state
      if self.finished?
         raise HangmanGame::StateError, "guess! called after game ended"
      end
      if self.guessed? letter
         raise HangmanGame::StateError, "letter already guessed: #{letter}"
      end

      @guessed_letters.add letter
      @correct_letters.include? letter
   end

   # Returns true if the letter has already been guessed.
   def guessed? raw_letter
      letter = HangmanGame.guard_guess(raw_letter)

      @guessed_letters.include? letter
   end

   # True if the game has been won.
   def won?
      !self.lost? && @guessed_letters >= @correct_letters
   end

   # True if the game has been lost.
   def lost?
      self.incorrect_guesses.size >= @guess_limit
   end

   # True if the game has concluded.
   def finished?
      self.lost? || self.won?
   end

   # Checks to see if a string constitutes a valid target word. That means any
   # string of plain letters (A-Z), optionally separated by hyphens, spaces, and apostrophes.
   #
   # Note that this doesn't check any kind of dictionary. Right now we're just
   # interested in limiting the character set.
   def self.acceptable_word? word
       HangmanGame::ACCEPTABLE_WORD =~ HangmanGame.normalize(word)
   end

   def self.acceptable_guess? letter
      HangmanGame::ACCEPTABLE_LETTER =~ HangmanGame.normalize(letter)
   end

   # Readable dump of the game state for debugging and that sort of thing
   def dump
      word_with_blanks = self.partial_solution.map{ |c| c || '_' }.join('')
      <<-END
      target word: #{@word}
          guessed: #{word_with_blanks}
        incorrect: [#{self.incorrect_guesses.to_a.join ', '}]
      END
   end

   # Indicates that something was done at the wrong time in the game, like
   # guessing a letter after winning.
   class StateError < StandardError; end

private

   ACCEPTABLE_LETTER = /^[A-Z]$/
   ACCEPTABLE_WORD = /^[A-Z]([- ']?[A-Z])*$/

   def self.normalize word_or_letter
      word_or_letter.strip.upcase
   end

   def self.guard_guess raw_letter
      letter = HangmanGame.normalize raw_letter

      unless HangmanGame.acceptable_guess? letter
         raise ArgumentError, "Invalid guess: \"#{letter}\" (only plain letters allowed)"
      end

      letter
   end

   def self.guard_word raw_word
      word = HangmanGame.normalize raw_word

      unless HangmanGame.acceptable_word? word
         raise ArgumentError, "Invalid word: \"#{word}\" (only plain letters A-Z separated by spaces and hyphens allowed)"
      end

      word
   end
end
