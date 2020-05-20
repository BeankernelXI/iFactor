require_relative 'ifactor.rb'

# a "factory" is a custom constructor idiom where we produce an object in exactly the state we want
# often even in otherwise invalid states
# these are exclusively for testing
def IFactor.factory(attributes={})
  # starting_moves: []
  # new_player: true
  # board: Hash.new(:available)
  # last_move: 0
  # current_player: :player_2
  # winner: :neither

  new.tap do |ifactor| # tap is one of my favorite weird methods. it always returns the object you called it on after passing it to a block
                       # mainly used for custom constructors but occasionally for chaining, ex obj.method.tap{|v| puts v}.more_methods
    attributes.each do |k,v|
      if [:board].include? k # being careful with objects that can't simply be clobbered
        ifactor.instance_variable_get("@#{k}").merge!(v) # the ! means it modifies in place, as opposed to creating a new object
      else
        ifactor.instance_variable_set("@#{k}",v)
      end
    end
  end
end


class Suite
  # just to show off, this is a totally general tiny testing framework :P

  def initialize(a_class, a_testing_module)
    make_attributes_public(a_class)
    self.class.include a_testing_module
    @tests = a_testing_module
  end

  def run_all_tests
    @tests.instance_methods.map do |method| # kinda advanced way to call every method in a class/module
      @method = method
      send(method)
    rescue StandardError => e
      puts "#{method} raised #{e.inspect}"
    end
  end

  def make_attributes_public(a_class)
    a_class.class_eval do # reopening classes is nothing special in ruby, tho doing it dynamically is a bit dangerous
                          # dangerous to do in "production" but extremely practical as a testing tool
      def method_missing(method, *args) # this is the behind the scenes method that gets called when the class doesn't recognize a method name
        if instance_variables.include? "@#{method}".to_sym
          self.class.attr_reader method # dynamically give us read access if we don't already
          return send(method) # would go infinite if I messed up this method :P
        end
        super # gotta always remember to call super when adding functionality by overwriting
      end
    end
  end

  # this is going to get run for every test, sometimes multiple times, to report the successes and failures in a managable way
  def guarentee(description="", &block) # this is what a method looks like that expects a block
    success = yield # keyword that calls the block
    test_name = @method.to_s.gsub(/_/, ' ') # replace underscores with spaces for printing
    test_name += " #{description}" unless description.empty?
    puts "#{test_name}: #{success ? 'pass' : 'fail'}"
  end

end

# module is like class, but has no state. you cannot call 'new' to instantiate one
# instead, because they are just collections of methods you can 'include' them into other classes or objects
# obviously the proper style is to have this is a separate file, but it's small and I'm lazy
module Tests
  # requirements:
  #   #guarentee

  def should_win
    attributes = {board: {1 => :player_1, 2 => :player_1, 3 => :player_1, 4 => :player_1, } }
    guarentee ("horizontally") {IFactor.factory(attributes).game_end? == :player_1}

    attributes = {board: {1 => :player_1, 7 => :player_1, 15 => :player_1, 25 => :player_1, } }
    guarentee ("vertically") {IFactor.factory(attributes).game_end? == :player_1}

    attributes = {board: {1 => :player_1, 8 => :player_1, 18 => :player_1, 30 => :player_1, } }
    guarentee ("diagonally") {IFactor.factory(attributes).game_end? == :player_1}
  end

  def should_stalemate
    attributes = {
      board: { 1 => :not_available, 2 => :not_available, 3 => :not_available, 4 => :not_available, 5 => :not_available,
               6 => :not_available, 7 => :not_available, 8 => :not_available, 9 => :not_available, 
             },
      last_move: 1
    }
    guarentee {IFactor.factory(attributes).game_end? == :draw}
  end

  def make_move_should
    attributes = {
      last_move: 1,
      current_player: :player_1,
    }
    f = IFactor.factory(attributes)
    f.make_move(2)
    guarentee("modify board") {f.board[2] == :player_1 }
    guarentee("advance player") {f.current_player == :player_2 }
    guarentee("keep last move up to date") {f.last_move == 2}
  end

  def rules_should
    f_new = IFactor.factory(new_player:true)
    f_returning = IFactor.factory(new_player:false)
    guarentee("be read to new players") {f_new.initial_player_prompt.include? IFactor::RULES}
    guarentee("not be read to returning players") {!f_returning.initial_player_prompt.include? IFactor::RULES}
  end

  # ...

end


if $0 == __FILE__

  Suite.new(IFactor, Tests).run_all_tests

end
