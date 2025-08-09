require 'open-uri'
require 'json'

DICTIONARY_URL = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt"
DICTIONARY_FILE = "google-10000-english-no-swears.txt"
SAVE_FILE = "hangman_save.dat"
MAX_ATTEMPTS = 6

class HangmanGame
  attr_accessor :secret_word, :correct_guesses, :incorrect_guesses, :remaining_attempts

  def initialize(secret_word)
    @secret_word = secret_word.downcase
    @correct_guesses = []
    @incorrect_guesses = []
    @remaining_attempts = MAX_ATTEMPTS
  end

  def display
    masked_word = @secret_word.chars.map { |c| @correct_guesses.include?(c) ? c : "_" }.join(" ")
    puts "\nWord: #{masked_word}"
    puts "Incorrect guesses: #{@incorrect_guesses.join(', ')}"
    puts "Remaining attempts: #{@remaining_attempts}"
  end

  def guess(letter)
    letter.downcase!
    if @secret_word.include?(letter)
      @correct_guesses << letter unless @correct_guesses.include?(letter)
    else
      unless @incorrect_guesses.include?(letter)
        @incorrect_guesses << letter
        @remaining_attempts -= 1
      end
    end
  end

  def won?
    @secret_word.chars.all? { |c| @correct_guesses.include?(c) }
  end

  def lost?
    @remaining_attempts <= 0
  end
end

def download_dictionary
  unless File.exist?(DICTIONARY_FILE)
    puts "Downloading dictionary..."
    URI.open(DICTIONARY_URL) do |file|
      File.write(DICTIONARY_FILE, file.read)
    end
    puts "Download complete."
  end
end

def load_words(min_length = 5, max_length = 12)
  words = File.readlines(DICTIONARY_FILE).map(&:strip)
  words.select { |word| word.length.between?(min_length, max_length) }
end

def save_game(game)
  File.open(SAVE_FILE, "wb") { |f| Marshal.dump(game, f) }
  puts "Game saved to #{SAVE_FILE}!"
end

def load_game
  if File.exist?(SAVE_FILE)
    Marshal.load(File.read(SAVE_FILE))
  else
    puts "No save file found."
    nil
  end
end

download_dictionary

puts "=== Hangman Game ==="
puts "1. New Game"
puts "2. Load Game"
print "Choose an option: "
option = gets.chomp

if option == '2'
  game = load_game
  if game.nil?
    puts "Could not load game. Starting a new one."
    option = '1'
  end
end

if option == '1'
  words = load_words
  secret_word = words.sample
  game = HangmanGame.new(secret_word)
end

until game.won? || game.lost?
  game.display
  print "\nEnter a letter (or type 'save' to save): "
  input = gets.chomp.downcase

  if input == 'save'
    save_game(game)
    puts "Exiting after save..."
    exit
  elsif input.length == 1 && input.match?(/[a-z]/i)
    if game.correct_guesses.include?(input) || game.incorrect_guesses.include?(input)
      puts "You've already guessed that letter."
    else
      game.guess(input)
    end
  else
    puts "Invalid input. Please enter a single letter."
  end
end

game.display
if game.won?
  puts "\n🎉 You won! The word was '#{game.secret_word}'."
else
  puts "\n💀 You lost. The word was '#{game.secret_word}'."
end
