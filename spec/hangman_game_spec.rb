require 'minitest/autorun'
require 'hangman_game'

describe HangmanGame do
   before do
      @game = HangmanGame.new('pinkerton', 3)
   end

   describe "when initialized" do
      it "must reject invalid words" do
         ['', '   ', '- -', 'af2', 'wnmkl.df'].each do |word|
            proc { HangmanGame.new(word) }.must_raise ArgumentError
         end
      end

      it "must accept valid words" do
         ['toothless', ' turtle\'s ', 'tor-pe-do', 'torte truck'].each do |word|
            HangmanGame.new(word).wont_be_nil
         end
      end

      it "must allow at least one guess" do
         proc { HangmanGame.new('foo', 0) }.must_raise ArgumentError
      end
   end

   describe "when a player guesses" do
      it "must detect correct guesses" do
         @game.guess! 'p'
         @game.correct_guesses.must_include 'P'
         @game.guess! 'o'
         @game.correct_guesses.must_include 'O'
         @game.incorrect_guesses.must_be_empty
      end

      it "must detect incorrect guesses" do
         @game.guess! 'z'
         @game.incorrect_guesses.must_include 'Z'
         @game.correct_guesses.must_be_empty
      end

      it "must detect a win" do
         'plinkerdto'.each_char{ |c| @game.guess! c }

         assert @game.won?
         assert @game.finished?
         assert !@game.lost?
      end

      it "must detect a loss" do
         'plinkerdtu'.each_char{ |c| @game.guess! c }

         assert !@game.won?
         assert @game.finished?
         assert @game.lost?
      end

      it "must complain if the game's already ended" do
         proc {
            'plinkerdtug'.each_char{ |c| @game.guess! c }
         }.must_raise HangmanGame::StateError
      end

      it "must reject invalid guesses" do
         ['', '-', '  ', 'fw'].each do |guess|
            proc { @game.guess! guess }.must_raise ArgumentError
         end
      end

      it "must reject duplicate guesses" do
         proc {
            @game.guess! 'z'
            @game.guess! 'Z'
         }.must_raise HangmanGame::StateError
      end
   end
end
