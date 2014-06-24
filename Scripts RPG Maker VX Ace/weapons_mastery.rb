#==============================================================================
#  Weapons mastery
#------------------------------------------------------------------------------
#  Version 1.0 - 23/04/2013
#      - Original Release VXace
#------------------------------------------------------------------------------
# This is a VXace adaptation of a VX script
#   Original author : ASHKA
#   Link : http://www.rpg-maker.fr/scripts-428-evolution-arme-competence.html
#------------------------------------------------------------------------------
# What does it do :
#   Weapons types now have levels. Each time an Actor use a weapon or a skill 
#   that require a equipped weapon he will gain a certain amout of experience. 
#   The higher the weapon mastery is the the higher weapon boost will be. The 
#   current progression of masteries can be viewed on the status screen by 
#   pressing the confirm key. Weapon boost is not applied by default. 
#==============================================================================
# How to use ?
#   - Configure WEAPON_TYPE array in the Config module.
#   - Add the 'a.wboost' parameter in battle formulas.
#         1 >= 'a.wboost' 
#   - You can display info with Window_WeaponsMastery. Parameter is an Actor
#         @weapons_mastery_window = Window_WeaponsMastery.new(@actor)
#         Default display is in status screen by pressing confirm key.
#==============================================================================

#==============================================================================
# ** Scene_Shop
#------------------------------------------------------------------------------
#  This class performs shop screen processing.
#==============================================================================
module Zangther
  module WeaponsMastery
    module Config
      # Concerned Weapon types
      # Hash with weapoon type and their icons (ID => Icon)
      WEAPON_TYPES = { 1 => 144, 2 => 145, 3 => 146, 4 => 147, 5 => 148, 
                       6 => 149, 7 => 150, 8 => 412, 9 => 152, 10 => 153 }
      
      # Message displayed in battle when level up
      #    %hero : Actor name
      #    %weapon : WeaponType name
      MESSAGE = "%hero matrise mieux l'arme [%weapon]"
      # Level displayed in status 
      STATUS_LEVEL = "Niv : %d - Exp %2d"

      # Experience gain when normal attack
      ATK_GAIN = 3
      # Experience gain when skill with weapon required
      SKILL_GAIN = 5
      # Experience needed to level up
      LEVEL_UP_NEED = 100
      # Max level
      LEVEL_MAX = 10
      # Damage boost for one level
      DAMAGE_BOOST = 0.5
    end
  end
end
#==============================================================================
# ** WeaponMastery
#------------------------------------------------------------------------------
#  The weapon mastery item that store level and exp
#==============================================================================
class WeaponMastery
  #--------------------------------------------------------------------------
  # * Readers
  #--------------------------------------------------------------------------
  attr_reader :wtype, :level, :exp
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize(wtype)
    @wtype = wtype
    @level = 1
    @exp = 0
  end
  #--------------------------------------------------------------------------
  # * Add experience
  #--------------------------------------------------------------------------
  def add_exp(amount)
    return if is_level_max?
    @exp += amount
    if @exp >= Zangther::WeaponsMastery::Config::LEVEL_UP_NEED
      @exp = 0
      @level += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Bonus Rate
  #--------------------------------------------------------------------------
  def bonus_rate
    Zangther::WeaponsMastery::Config::DAMAGE_BOOST * (@level - 1) + 1
  end
  
  private
  #--------------------------------------------------------------------------
  # * Is level maximum ?
  #--------------------------------------------------------------------------
  def is_level_max?
    @level >= Zangther::WeaponsMastery::Config::LEVEL_MAX
  end
end
#==============================================================================
# ** RPG::Skill
#------------------------------------------------------------------------------
#  Add some calculated attributes
#==============================================================================
class RPG::Skill
  #--------------------------------------------------------------------------
  # * Is a normal attack ?
  #--------------------------------------------------------------------------
  def is_normal_attack?
    !(effects.find{ |effect| effect.data_id == 0 }).nil?
  end
  #--------------------------------------------------------------------------
  # * Are weapons required ?
  #--------------------------------------------------------------------------
  def weapons_required?
    !(required_wtype_id1.nil? && required_wtype_id2.nil?)
  end
  #--------------------------------------------------------------------------
  # * Required weapons
  #--------------------------------------------------------------------------
  def required_weapons
    [required_wtype_id1, required_wtype_id2].compact
  end 
end
#==============================================================================
# ** Game_BattlerBase
#------------------------------------------------------------------------------
#  Add wboost, default is 1
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Access Method by Parameter Abbreviations
  #--------------------------------------------------------------------------
  def wboost;  1;   end               # wboost  Weapon Mastery Boost
end
#==============================================================================
# ** Game_Actor
#------------------------------------------------------------------------------
#  Add weapon mastery handling
#==============================================================================
class Game_Actor
  #--------------------------------------------------------------------------
  # * Reader
  #--------------------------------------------------------------------------
  attr_reader :weapons_mastery
  #--------------------------------------------------------------------------
  # * Setup
  #--------------------------------------------------------------------------
  alias old_setup setup
  def setup(actor_id)
    old_setup(actor_id)
    init_weapons_mastery
  end
  #--------------------------------------------------------------------------
  # * Initialize Weapons Mastery
  #--------------------------------------------------------------------------
  def init_weapons_mastery
    @weapons_mastery = []
    Zangther::WeaponsMastery::Config::WEAPON_TYPES.each_key do |wtype|
      @weapons_mastery << WeaponMastery.new(wtype)
    end
    @levelup_weapons_mastery = []
  end
  #--------------------------------------------------------------------------
  # * Weapon boost
  #     return current weapon mastery boost.
  #     if two weapons (or more) will return the average value
  #--------------------------------------------------------------------------
  def wboost
    all_boost = weapons_types.inject(0) do |sum, wtype|
      mastery = @weapons_mastery.find { |wmastery| wmastery.wtype == wtype }
      sum += mastery.bonus_rate
    end
    all_boost / weapons_types.size
  end
  #--------------------------------------------------------------------------
  # * Weapon Types
  #--------------------------------------------------------------------------
  def weapons_types
    weapons.map do |weapon|
      weapon.wtype_id 
    end
  end
  #--------------------------------------------------------------------------
  # * Did any weapon mastery leveled up ?
  #--------------------------------------------------------------------------
  def weapons_mastery_leveled_up?
    !@levelup_weapons_mastery.empty?
  end
  #--------------------------------------------------------------------------
  # * Reset level up infos
  #--------------------------------------------------------------------------
  def reset_weapons_mastery_leveled_up
    @levelup_weapons_mastery = []
  end 
  #--------------------------------------------------------------------------
  # * Add exp to equipped weapons type
  #--------------------------------------------------------------------------
  def add_exp_equipped_weapons(amount)
    weapons_types.each do |wtype|
      add_exp_weapon(wtype, amount)
    end
  end
  #--------------------------------------------------------------------------
  # * Add exp to a weapon type
  #--------------------------------------------------------------------------
  def add_exp_weapon(wtype, amount)
    mastery = @weapons_mastery.find { |wmastery| wmastery.wtype == wtype }
    return if mastery.nil?
    
    old_level = mastery.level
    mastery.add_exp(amount)
    @levelup_weapons_mastery << mastery if mastery.level != old_level    
  end
  #--------------------------------------------------------------------------
  # * Text for level up
  #--------------------------------------------------------------------------
  def weapons_mastery_levelup_text
    message = Zangther::WeaponsMastery::Config::MESSAGE
    with_hero = message.gsub("%hero", name)
    with_hero.gsub("%weapon", @levelup_weapons_mastery.map do |mastery|
      $data_system.weapon_types[mastery.wtype]
    end.join(", "))
  end
end
#==============================================================================
# ** Window BattleLog
#------------------------------------------------------------------------------
#  Add display method about weapon mastery level up
#==============================================================================
class Window_BattleLog
  #--------------------------------------------------------------------------
  # * Display Weapon Mastery level up message
  #--------------------------------------------------------------------------
  def display_weapon_level_up(subject)
    add_text(subject.weapons_mastery_levelup_text)
    subject.reset_weapons_mastery_leveled_up
    wait
  end
end
#==============================================================================
# ** Window_WeaponsMastery
#------------------------------------------------------------------------------
#  Displays weapons mastery with level and exp points
#==============================================================================
class Window_WeaponsMastery < Window_Base
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize(actor)
    super(82, 43, 380, 320)
    self.hide
    @actor = actor
    draw_masteries
  end
  #--------------------------------------------------------------------------
  # * Set actor
  #--------------------------------------------------------------------------
  def actor=(actor)
    @actor = actor
    draw_masteries
  end
  #--------------------------------------------------------------------------
  # * Draw masteries
  #--------------------------------------------------------------------------
  def draw_masteries
    self.contents.clear
    @actor.weapons_mastery.each_with_index do |mastery, i|
      draw_mastery(mastery, i)
    end
  end
  #--------------------------------------------------------------------------
  # * Draw one mastery
  #--------------------------------------------------------------------------
  def draw_mastery(mastery, i)
    draw_mastery_icon(mastery, i)
    draw_mastery_name(mastery, i)
    draw_level_text(mastery, i)
  end
  #--------------------------------------------------------------------------
  # * Draw Icon
  #--------------------------------------------------------------------------
  def draw_mastery_icon(mastery, i)
    # Data
    icon_index = Zangther::WeaponsMastery::Config::WEAPON_TYPES[mastery.wtype]
    # Coords
    x = 0
    y = i * 30
    # Draw
    process_draw_icon(icon_index, :x => 0, :y => y)    
  end
  #--------------------------------------------------------------------------
  # * Draw Name
  #--------------------------------------------------------------------------
  def draw_mastery_name(mastery, i)
    # Data
    type_name = $data_system.weapon_types[mastery.wtype]
    # Coords
    x = 30
    y = i * 30
    # Draw
    draw_text(x, y, 150, line_height, type_name)
  end
  #--------------------------------------------------------------------------
  # * Draw Level and Exp info
  #--------------------------------------------------------------------------
  def draw_level_text(mastery, i)
    # Data
    text = Zangther::WeaponsMastery::Config::STATUS_LEVEL
    level_text = sprintf(text, mastery.level, mastery.exp)
    level_text_size = text_size(level_text).width
    # Coords
    x = contents_width - level_text_size
    y = i * 30
    # Draw
    draw_text(x, y, level_text_size, line_height, level_text)
  end
  #--------------------------------------------------------------------------
  # * Switch visibility
  #--------------------------------------------------------------------------
  def switch_visibility
    visible ? hide : show
  end
end
#==============================================================================
# ** Scene_Battle
#------------------------------------------------------------------------------
#  Patch apply_item_effects, add exp and display message after
#==============================================================================
class Scene_Battle
  #--------------------------------------------------------------------------
  # * Prepare
  #--------------------------------------------------------------------------
  alias :aie :apply_item_effects
  def apply_item_effects(target, item)
    aie(target, item)
    
    if @subject.is_a?(Game_Actor) && item.is_a?(RPG::Skill)
      # Add exp
      if item.is_normal_attack?
        @subject.add_exp_equipped_weapons(
          Zangther::WeaponsMastery::Config::ATK_GAIN)
      elsif item.weapons_required?
        item.required_weapons.each do |weapon|
          @subject.add_exp_weapon(weapon, 
            Zangther::WeaponsMastery::Config::SKILL_GAIN)
        end
      end
      # Display level up
      if @subject.weapons_mastery_leveled_up?
        @log_window.display_weapon_level_up(@subject)
      end
    end
  end
end
#==============================================================================
# ** Scene_Status
#------------------------------------------------------------------------------
#  Add Weapons Mastery window
#==============================================================================
class Scene_Status
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  alias :old_start :start
  def start
    old_start
    @weapons_mastery_window = Window_WeaponsMastery.new(@actor)
    @status_window.set_handler(:ok,   method(:switch_weapons_mastery))
  end
  #--------------------------------------------------------------------------
  # * Change Actors
  #--------------------------------------------------------------------------
  def switch_weapons_mastery
    @weapons_mastery_window.switch_visibility
    @status_window.activate
  end
  #--------------------------------------------------------------------------
  # * Change Actors
  #--------------------------------------------------------------------------
  alias :ooac :on_actor_change
  def on_actor_change
    ooac
    @weapons_mastery_window.actor = @actor
  end
end
