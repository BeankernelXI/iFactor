class IFactor
  # Connect Four variant where the available plays are limited based on your opponents last move.
  RULES = <<~RULES
    Here's a quick rundown of the rules:
      Each turn you will choose a number.
      The space you put your piece on is the PRODUCT of the number you chose and your opponent's last choice
      You are not allowed to pick a number that would reuse a space, and if that means you have no available moves then the game is a draw.
      A player wins if they make a 4-in-a-row!
      To start, player 2 must choose a number without placing a piece so that Player 1 has something to multiply with.
    The board looks like this, each possible product of the numbers 1-9 in a 6x6 grid
     1  2  3  4  5  6
     7  8  9 10 12 14
    15 16 18 20 21 24
    25 27 28 30 32 35
    36 40 42 45 48 49
    54 56 63 64 72 81
  RULES


  WHITE_PLAYER = "\u25ef " # full width unicode prints poorly if not followed by a space
  BLACK_PLAYER = "\u2b24 "

  NUMBERS = (1..9).flat_map{|n| (1..9).map{|m| n*m }}.uniq.sort # set of products up to 81

  # providing the default value with a colon makes the caller have to use the name too (see the very bottom of this file for an example)
  # the advantage is that they can provide their choice of options without worrying about order
  def initialize(starting_moves:[], new_player: true)
    @starting_moves = starting_moves
    @new_player = new_player  # for deciding whether to print out the rules
    @board = Hash.new(:available) # set default value to something more descriptive than nil (totally unnecessary but I like to do this)
                                  # in a larger program 'board' would get its own class and so would each member of the board 
    @last_move = 0
    @current_player = :player_2
    @winner = :neither
  end

  def board_str
    NUMBERS.each_slice(6).map do |row| # takes the array 6 at a time
      row.map do |n|
        if( @board[n] == :available )
          n.to_s.rjust(2) # pads single digit numbers with a space
        elsif( @board[n] == :player_1 )
          WHITE_PLAYER
        else # :player_2
          BLACK_PLAYER
        end
      end.join(' ') # join a single row
    end.join("\n") # join all rows
  end

  # the default way to play this game will be
  # IFactor.new.play
  def play # "main"
    @last_move = get_move(:initial) # this was its own method but I combined two because they ended up very similar
    next_player
    loop do
      draw_board
      break if game_end?
      make_move( get_move )
    end
    make_closing_remarks
  end

  # checks for 4-in-a-rows by the same player or stalemate
  def game_end?
    # we're being lazy and setting winner as a global instead of carefully passing it back up the stack

    grid = NUMBERS.map{|n|@board[n]}.each_slice(6).to_a # nested arrays, inside is rows
    grid_t = grid.transpose # inside is columns

    # think of this as assigning a block to a variable
    compare_four = Proc.new do |a,b,c,d|
      [:player_1, :player_2].each do |player|
        return(@winner = player) if [a,b,c,d].all?(player) # normally to leave a block you would use 'break' or 'next', but not in a Proc :facepalm: I know
      end
      false
    end

    # check rows and one diagonal of the normal grid and then the same for the transpose      
    [grid,grid_t].each do |a_grid| # DRYer this way but a bit messy
      a_grid.each do |row|
        # each_cons passes every combination of n consecutive elements to the block
        row.each_cons(4) do |args|
          result = compare_four.call(args) # blocks and procs automatically expand arrays if they were expecting multiple args and only got an array. (you can do this explicitly with *args)
          return result if result
        end
      end
      (0...6).each_cons(4) do |args| # same as [[0, 1, 2, 3], [1, 2, 3, 4], [2, 3, 4, 5]].each
        result = compare_four.call(args.map{ |i| a_grid[i][i] }) # check diagonal
        return result if result
      end
    end

    return(@winner = :draw) if available_moves.none?

    false
  end

  def make_move(n)
    # Philosophical Note:
    # its tempting to put input validation in methods like this.
    # however, if you trust that the caller is passing good data avoid unecessary input validation
    # and if you don't trust the caller, adding the validation upstream is often more effective
    @board[ n * @last_move ] = @current_player
    @last_move = n
    next_player
  end

  # slightly overloaded method, but way better than repeating basically the same code twice
  def get_move(initial=nil) # this is what a normal default value looks like
    puts initial ? initial_player_prompt : player_prompt
    loop do # if they can't manage to give us a valid move we just keep asking :P

      input = @starting_moves.shift || gets.chomp # optional starting_moves for easier debugging

      return input.to_i if is_valid? input.to_i
      puts player_scold(input)
    end
  end

  # there are so many other ways to do this, but this is the simple way
  def next_player
    if @current_player == :player_2
      @current_player = :player_1 
    else
      @current_player = :player_2
    end
  end

  ## For example, here's a fun way
  # PLAY_ORDER = {player_1: :player_2, player_2: player_1}
  # def next_player
  #   @current_player = PLAY_ORDER[@current_player]
  # end

  def available_moves
    (1..9).select{ |move| @board[move * @last_move] == :available }
  end

  def is_valid?(move)
    available_moves.include?(move)
  end

  def draw_board
    puts board_str # giving this its own method makes it easier to break board out into its own class later
  end

  def make_closing_remarks
    unless @winner == :neither
      puts outro_winner
    else
      puts outro_draw
    end
  end

  def initial_player_prompt
    <<~GAMESTART
      Welcome to iFactor, a Connect Four variant where you defeat your opponent with math. Better sharpen your multiplication tables!
      #{RULES if @new_player}
      Player 2 please choose the first number: 1 2 3 4 5 6 7 8 or 9
    GAMESTART
  end

  def player_prompt
    <<~PROMPT
      Your turn, Player #{@current_player == :player_1 ? 1 : 2}
      Please choose a number: #{available_moves.insert(-2,"or").join(' ')}
      Your opponent's last number was #{@last_move}
    PROMPT
  end

  def player_scold(input)
    <<~SCOLD
      Sorry but that wasn't one of the available choices
      I interpretted what you typed as "#{input.inspect}"
      Please try again, your options are still #{available_moves.insert(-2,"or").join(' ')}
    SCOLD
  end

  def outro_winner
    <<~OUTRO_WINNER
      Player #{@winner == :player_1 ? 1 : 2} Wins!
      Congratulations!
    OUTRO_WINNER
  end

  def outro_draw
    <<~DRAW
      A stalemate! I guess you'll just have to play again :P
    DRAW
  end

end


# here's a cute trick
if $0 == __FILE__ # $0 is the source file's path and __FILE__ is the current file's path
# there's a list of all the unexpected pre-assigned variables here: https://ruby-doc.org/docs/ruby-doc-bundle/UsersGuide/rg/globalvars.html

  # run the code here with whatever options I want.
  # for when I'm not running the automated tests
  IFactor.new(starting_moves:[],new_player:true).play

  # it wasn't useful for this program, but starting an irb session from within a file can be an efficient way to play with your code
  # 
  # require 'irb'
  # IRB.start
  # 
  # if you do this, be aware that irb can't access global variables unless they are @ variables

end
