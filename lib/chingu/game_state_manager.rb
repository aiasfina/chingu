module Chingu
  #
  # GameStateManger is responsible for keeping track of game states with a simple pop/push stack.
  #
  # Related blogpost: http://gamedevgeek.com/tutorials/managing-game-states-in-c/
  #
  # Chingu::Window automatically creates a @game_state_manager and makes it accessible in our game loop.
  # By default the game loop calls update() / draw() on @game_state_manager
  #
  class GameStateManager
    attr_accessor :inside_state
    attr_reader :states, :created_states
    
    def initialize
      @inside_state = nil
      @states = []
      @created_states = {}
    end

    #
    # Gets the currently active gamestate (top of stack)
    #
    def current_state
      @states.last
    end

    #
    # Switch to a given game state, _replacing_ the current active one.
    #
    def switch_state(state, options = {})
      options = {:setup => true, :finalize => true}.merge(options)

      new_state = object_to_state(state)
      
      if new_state
        # Give the soon-to-be-disabled state a chance to clean up by calling finalize() on it.
        current_state.finalize  if current_state.respond_to?(:finalize) && options[:finalize]
        
        # Call setup
        new_state.setup         if new_state.respond_to?(:setup) && options[:setup]
        
        # Replace last (active) state with new one
        @states[-1] = new_state
      end
    end

    #
    # Adds a state to the game state-stack and activates it
    #
    def push_state(state, options = {})
      options = {:setup => true, :finalize => true}.merge(options)

      new_state = object_to_state(state)
      
      if new_state
        # Give the soon-to-be-disabled state a chance to clean up by calling finalize() on it.
        current_state.finalize  if current_state.respond_to?(:finalize) && options[:finalize]
        
        # Call setup
        new_state.setup         if new_state.respond_to?(:setup) && options[:setup]
        
        # Push new state on top of stack and therefore making it active
        @states.push(new_state)
      end
    end
    
    #
    # Pops a state off the game state-stack, activating the previous one.
    #
    def pop_state(options = {})
      options = {:setup => true, :finalize => true}.merge(options)
      
      #
      # Give the soon-to-be-disabled state a chance to clean up by calling finalize() on it.
      #
      current_state.finalize    if current_state.respond_to?(:finalize) && options[:finalize]
      
      #
      # Activate the game state "bellow" current one with a simple Array.pop
      #
      @states.pop

      # Call setup on the new current state
      current_state.setup       if current_state.respond_to?(:setup) && options[:setup]
    end

    #
    # Returns a GameState-instance from either a class or object
    #
    def object_to_state(state)
      new_state = nil
      #
      # If state is a GameState-instance, just queue it
      #
      if state.is_a? Chingu::GameState
        new_state = state
      #
      # If state is a GameState-class, create/initialize it once (@created_states keeps track of this)
      #        
      elsif state.superclass == Chingu::GameState
        
        if @created_states[state.to_s]
          new_state = @created_states[state.to_s]
        else
          new_state = state.new({})
          @created_states[state.class.to_s] = new_state
        end
      end
      
      return new_state
    end


    #
    # Returns the previous game state
    #
    def previous_state
      @states[@states.index(current_state)-1]
    end
    alias :prev_state previous_state
    
    #
    # Remove all game states from stack
    #
    def clear_states
      @states.clear
    end
    
    #
    # Pops through all game states until matching a given game state
    #
    def pop_until_game_state(new_state)
      while (state = @states.pop)
        break if state == new_state
      end
    end
    
    #
    # Bellow follows a set of auto-called Gosu::Window methods.
    # We define them game_state_manager so Gosu::Window can call them here.
    # Then the game_state_manager is responsible to resend them to the active state. 
    # Or in the future many states.
    #
    
    #
    # Called before #update when the user pressed a button while the window had the focus. 
    #
    def button_down(id)
      current_state.button_down(id) if current_state
    end
    
    #
    # Called when the user released a button. 
    #
    def button_up(id)
      current_state.button_up(id)   if current_state
    end
    
    #
    # Calls #update on the current gamestate, if there is one.
    #
    def update(time = 1)
      current_state.update(time)  if current_state
    end
    #
    # Calls draw() on the current gamestate, if there is one.
    #
    def draw
      current_state.draw    if current_state
    end
  end
end