#==============================================================================
# ** Ring Menu
#------------------------------------------------------------------------------
#  This is a simple ring menu.
#          - Core classes are in module Zangther including
#                  - Scene_RingMenu
#                  - Spriteset_Iconring
#                  - Sprite_Icon
#          - Configuration is in the module Zangther::Config::RingMenu
#          - You can change fade_in and fade_out methods, they are into Zangther::Config::RingMenu::Fade
#          - Some edits to Scene_Map, Scene_Item, Scene_File and Scene_End are made at the end of the file in 
#               order to make them compatible with this ring menu. 
#                     (#call_menu for Scene_Map and #return_scene for the others)
#------------------------------------------------------------------------------
# Version : 1.0 by Zangther
#     If any questions, contact me at zangther@gmail.com
#==============================================================================
module Zangther
  module Config
    module RingMenu
      # Menus's commands
      MENU_COMMAND = [
      # :name => "Name", :icon => ID, :action => lambda { new scene }
        {:name => "Items", :icon => 159, :action => lambda { Scene_Item.new }},
        {:name => "File", :icon => 133, :action => lambda { Scene_File.new(true, false, false) }},
        {:name => "Exit", :icon => 137, :action => lambda { Scene_End.new }}
      ]
      
      # Angle de base
      START_ANGLE = 1.5 * Math::PI
      # Distance
      DISTANCE = 50
      
      module Fade
        #--------------------------------------------------------------------------
        # * Fade in
        #--------------------------------------------------------------------------
        def fade_in(distance)
          distance = distance.to_i
          total_spin
          dist_step = (distance - @distance) / (6.28 / @step)
          opa_step = 255 / (6.28 / @step)
          recede(distance,  dist_step)
          change_opacity(255, opa_step)
          @state = :openning
        end
        #--------------------------------------------------------------------------
        # * Fade out
        #--------------------------------------------------------------------------
        def fade_out(distance)
          distance = distance.to_i
          total_spin
          dist_step = (distance - @distance) / (6.28 / @step)
          opa_step = 255 / (6.28 / @step)
          approach(distance,  dist_step)
          change_opacity(0, -opa_step)
          @state = :closing
        end
      end
    end
  end
  #==============================================================================
  # ** Scene_RingMenu
  #------------------------------------------------------------------------------
  #  This scene used to be an adventurer like you, but then it took an arrow in the knee.
  #==============================================================================
  class Scene_RingMenu < Scene_Base
    #--------------------------------------------------------------------------
    # * Start processing
    #--------------------------------------------------------------------------
    def initialize(index = 0)
      @index = index.to_i
    end
    #--------------------------------------------------------------------------
    # * Start processing
    #--------------------------------------------------------------------------
    def start
      super
      create_menu_background
      create_command_ring
      create_command_name
    end
    #--------------------------------------------------------------------------
    # * Termination Processing
    #--------------------------------------------------------------------------
    def terminate
      super
      dispose_menu_background
      dispose_command_name
    end
    #--------------------------------------------------------------------------
    # * Frame Update
    #--------------------------------------------------------------------------
    def update
      super
      if @command_ring.closed?
        @command_ring.dispose
        change_scene
      else
        @command_ring.update
        update_command_name
        update_command_selection
      end 
      update_menu_background
    end
    
    private
    #--------------------------------------------------------------------------
    # * Create Command Ring
    #--------------------------------------------------------------------------
    def create_command_ring
      icons = Array.new
      Config::RingMenu::MENU_COMMAND.each do |command|
        icons.push(icon = Sprite_Icon.new)
        icon.bitmap = Cache.system("Iconset")
        index = command[:icon]
        x = index % 16 * 24
        y = (index / 16).truncate * 24
        icon.src_rect = Rect.new(x,y,24,24)
      end
      x = $game_player.screen_x - 28
      y = $game_player.screen_y - 44
      distance = Config::RingMenu::DISTANCE
      angle = Config::RingMenu::START_ANGLE
      @command_ring = Spriteset_Iconring.new(x, y, distance, 10, angle, icons, @index)
    end
    #--------------------------------------------------------------------------
    # * Create Command Text
    #--------------------------------------------------------------------------
    def create_command_name
      @command_name = Sprite.new
      distance = Config::RingMenu::DISTANCE
      width = distance * 2
      @command_name.bitmap = Bitmap.new(width, 24)
      @command_name.x = $game_player.screen_x  - distance
      @command_name.y = $game_player.screen_y + distance
    end
    #--------------------------------------------------------------------------
    # * Update Command Selection
    #--------------------------------------------------------------------------
    def update_command_selection
      if Input.trigger?(Input::B)
        Sound.play_cancel
        block = lambda {Scene_Map.new}
        prepare_scene {block}
      elsif Input.trigger?(Input::LEFT)
        @command_ring.spin_left
      elsif Input.trigger?(Input::RIGHT)
        @command_ring.spin_right
      elsif Input.trigger?(Input::C)
        Sound.play_decision
        command = Config::RingMenu::MENU_COMMAND[@command_ring.index]
        prepare_scene {command[:action]}
      end
    end
    #--------------------------------------------------------------------------
    # * Update Command Text
    #--------------------------------------------------------------------------
    def update_command_name
      rect = @command_name.src_rect
      command = Config::RingMenu::MENU_COMMAND[@command_ring.index]
      bitmap = @command_name.bitmap
      bitmap.clear
      bitmap.draw_text(rect, command[:name], 1)
    end
    #--------------------------------------------------------------------------
    # * Dispose Command Text
    #--------------------------------------------------------------------------
    def dispose_command_name
      @command_name.dispose
    end
    #--------------------------------------------------------------------------
    # * Prepare transition for new scene
    #--------------------------------------------------------------------------
    def prepare_scene
      @scene = yield.call
      @command_ring.pre_terminate
    end  
    #--------------------------------------------------------------------------
    # * Execute transition to new scene
    #--------------------------------------------------------------------------
    def change_scene
      $scene = @scene
    end
  end
  #==============================================================================
  # ** Sprite_Icon
  #------------------------------------------------------------------------------
  #  Just inherit from Sprite and add a place method for placement
  #==============================================================================
  class Sprite_Icon < Sprite
    #--------------------------------------------------------------------------
    # * Place the sprite
    #--------------------------------------------------------------------------
    def place(x, y, distance, angle)
      # Force values to numeric
      distance = distance.to_i
      angle = angle.to_f
      # Polar coordinations calculation
      self.x = x.to_i + (Math.cos(angle)*distance)
      self.y = y.to_i + (Math.sin(angle)*distance)
      update
    end 
  end
  #==============================================================================
  # ** Spriteset_Iconring
  #------------------------------------------------------------------------------
  #  This class manages Sprite_Icon and make then spin around a point.
  #==============================================================================
  class Spriteset_Iconring
    #--------------------------------------------------------------------------
    # * Module inclusions
    #--------------------------------------------------------------------------
    include Config::RingMenu::Fade
    #--------------------------------------------------------------------------
    # * Public Instance Variables
    #--------------------------------------------------------------------------
    attr_reader :x
    attr_reader :y
    attr_reader :distance
    attr_reader :angle
    attr_reader :direction
    attr_reader :actual_direction
    attr_reader :index
    #--------------------------------------------------------------------------
    # * Public Instance Variables
    #--------------------------------------------------------------------------
    PI_2 = 6.28
    #--------------------------------------------------------------------------
    # * Constructor
    #--------------------------------------------------------------------------
    def initialize(x, y, distance, speed, angle, sprites, index = 0, direction=:trigo)
      # Argument test
      sprites = Array(sprites)
      unless sprites.all? { |sp| (sp.is_a?(Sprite_Icon)) }
        raise(ArgumentError, "sprite isn't an array of Sprite_Icons") 
      end
      # Adjust numeric arguments
      @x = x.to_i + 16
      @y = y.to_i + 16
      @distance = @future_distance = 0
      @speed = speed.to_i
      @angle = (angle.to_f - (index * (PI_2 / sprites.size))).modulo PI_2
      # Settings
      @shift = {:trigo => 0, :antitrigo => 0}
      @direction = @actual_direction = direction
      @index = index.to_i
      @opacity = @future_opacity = 0
      @icons = sprites
      @state = :closed
      self.step = :default
      fade_in(distance)
      update(true)
    end
    #--------------------------------------------------------------------------
    # * Update
    # need_refresh : force refresh
    #--------------------------------------------------------------------------
    def update(need_refresh=false)
      return unless @icons
      if moving?
        if spinning?
          reverse_direction if need_reverse?
          update_angle
        end
        update_distance
        need_refresh = true
      end
      update_opacity
      update_state
      refresh if need_refresh
    end
    #--------------------------------------------------------------------------
    # * Dispose
    #--------------------------------------------------------------------------
    def pre_terminate
      fade_out(0)
    end
    #--------------------------------------------------------------------------
    # * Dispose
    #--------------------------------------------------------------------------
    def dispose
      @icons.each {|icon| icon.dispose}
    end
    #--------------------------------------------------------------------------
    # * Refresh
    #--------------------------------------------------------------------------
    def refresh
      @icons.size.times do |i|
        icon = @icons[i]
        angle = @angle + ((PI_2/(@icons.size))*i)
        icon.place(@x,@y,@distance,angle)
        icon.opacity = @opacity
        icon.update
      end
    end
    #--------------------------------------------------------------------------
    # * Spin
    #--------------------------------------------------------------------------
    def spin
      unless spinning?
        number_of_icons = @icons.size
        @shift[@direction] += PI_2/number_of_icons
        if @direction == :trigo
          @index += 1
        else
          @index -= 1
        end
        @index = @index.modulo number_of_icons
      end
    end
    #--------------------------------------------------------------------------
    # * Change direction
    #     direction :  :trigo, :antitrigo, :+, :-, :positif, :negatif
    #--------------------------------------------------------------------------
    def change_direction(direction)
      case direction
      when :trigo, :+, :positif
        @direction = :trigo
      when :antitrigo, :-, :negatif
        @direction = :antitrigo
      end
    end
    #--------------------------------------------------------------------------
    # * Change center
    #   x,y : Entiers
    #--------------------------------------------------------------------------
    def changer_centre(x, y)
      @x = x.to_i
      @y = y.to_i
    end
    #--------------------------------------------------------------------------
    # * Définir distance
    #--------------------------------------------------------------------------
    def angle=(angle)
      if angle > PI_2 || angle < 0
        angle = 0
      end
      @angle = angle.to_f
    end
    #--------------------------------------------------------------------------
    # * Maj step
    #--------------------------------------------------------------------------
    def step=(step=1)
      if step == :default
        number_of_icons = @icons.size
        @step = PI_2 / (number_of_icons*100) * @speed 
      else
        @step = step.to_f * @speed
      end
    end
    #--------------------------------------------------------------------------
    # * Spin right
    #--------------------------------------------------------------------------
    def spin_right
      change_direction(:+)
      spin
    end
    #--------------------------------------------------------------------------
    # * Spin right
    #--------------------------------------------------------------------------
    def spin_left
      change_direction(:-)
      spin
    end
    #--------------------------------------------------------------------------
    # * Move away from center
    #--------------------------------------------------------------------------
    def recede(distance, step = 1)
      @future_distance = distance.to_i
      @distance_step = step.abs
    end
    #--------------------------------------------------------------------------
    # * Move back to center
    #--------------------------------------------------------------------------
    def approach(distance, step = 1)
      @future_distance = distance.to_i
      @distance_step = - step.abs
    end
    #--------------------------------------------------------------------------
    # * Changes opacity
    #--------------------------------------------------------------------------
    def change_opacity(opacity, step = 1)
      if opacity > 255
        @future_opacity = 255
      elsif opacity < 0
        @future_opacity = 0
      else
        @future_opacity = opacity.to_i
      end
      @opacity_step = step.to_i
    end
    #--------------------------------------------------------------------------
    # * Is closed ?
    #--------------------------------------------------------------------------
    def closed?
      @state == :closed
    end
    #--------------------------------------------------------------------------
    # * Is opened ?
    #--------------------------------------------------------------------------
    def opened?
      @state == :opened
    end

    private
    #--------------------------------------------------------------------------
    # * Updates angle positionning
    #--------------------------------------------------------------------------
    def update_angle
      direction = @actual_direction
      shift = @shift[direction]
      step = @step > shift ? shift : @step
      step *= -1 if direction == :trigo
      temp = @angle + step
      if direction == :trigo && temp < 0
        temp += PI_2
      elsif direction == :antitrigo && temp > PI_2
        temp -= PI_2
      end
      @angle = temp
      @shift[direction] = shift-@step
      @shift[direction] = 0 if @shift[direction] < 0
    end
    #--------------------------------------------------------------------------
    # * Updates distance positionning
    #--------------------------------------------------------------------------
    def update_distance
      return if @future_distance == @distance
      temp = @distance + @distance_step
      # Checks if @future_distance is between temp and @distance
      # If so, that's mean that @distance_step is bigger than the gap between @distance & @future_distance
      if (@distance..temp).include?(@future_distance) || (temp..@distance).include?(@future_distance)
        @distance = @future_distance
      else
        @distance += @distance_step
      end
    end
    #--------------------------------------------------------------------------
    # * Updates opacity
    #--------------------------------------------------------------------------
    def update_opacity
      shift = @future_opacity - @opacity
      return if shift == 0
      @opacity += @opacity_step
      if shift > 0
        @opacity = @future_opacity if @opacity > @future_opacity
      else
        @opacity = @future_opacity if @opacity < @future_opacity
      end
    end
    #--------------------------------------------------------------------------
    # * Updates state
    #--------------------------------------------------------------------------
    def update_state
      unless spinning?
        if @state == :closing
          @state = :closed
        elsif @state == :openning
          @state = :opened
        end
      end
    end
    #--------------------------------------------------------------------------
    # * Reverse the direction 
    #--------------------------------------------------------------------------
    def reverse_direction
      @actual_direction = (@actual_direction == :trigo ? :antitrigo : :trigo)
    end
    #--------------------------------------------------------------------------
    # * Need revesing direction ?
    #--------------------------------------------------------------------------
    def need_reverse?
      @shift[@actual_direction] <= 0
    end
    #--------------------------------------------------------------------------
    # * Spinning
    #--------------------------------------------------------------------------
    def spinning?
      @shift.any? {|key,val| val > 0}
    end
    #--------------------------------------------------------------------------
    # * Moving ?
    #--------------------------------------------------------------------------
    def moving?
      spinning? || (@future_distance != @distance)
    end
    #--------------------------------------------------------------------------
    # * Make one complete spin
    #--------------------------------------------------------------------------
    def total_spin
        @shift[@direction] += PI_2 unless spinning?
    end
  end	
end 
#==============================================================================
# ** Scene_Map
#------------------------------------------------------------------------------
#  Edit #call_menu
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Switch to Menu Screen
  #--------------------------------------------------------------------------
  def call_menu
    if $game_temp.menu_beep
      Sound.play_decision
      $game_temp.menu_beep = false
    end
    $game_temp.next_scene = nil
    $scene = Zangther::Scene_RingMenu.new
  end
end
#==============================================================================
# ** Scenes
#------------------------------------------------------------------------------
#  Edits #return_scene
#==============================================================================
class Scene_End < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(2)
  end
end

class Scene_Item < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(0)
  end
end
  
class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    if @from_title
      $scene = Scene_Title.new
    elsif @from_event
      $scene = Scene_Map.new
    else
      $scene = Zangther::Scene_RingMenu.new(1)
    end
  end
end