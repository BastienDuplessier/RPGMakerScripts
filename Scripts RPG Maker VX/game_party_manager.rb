#==============================================================================
# ** Game_Party_Manager
#------------------------------------------------------------------------------
#  This class is about party management. Now, you can have many parties and switch one to 
#    another easily.
#    Use $game_party_manager.new_party to initialize a new party
#    Use $game_party_manager.switch_to(n) to switch to the nth party.
#==============================================================================

class Game_Party_Manager
  #--------------------------------------------------------------------------
  # * Initialization
  #--------------------------------------------------------------------------
  def initialize
    @parties = [$game_party]
  end
  #--------------------------------------------------------------------------
  # * Create a new party
  #--------------------------------------------------------------------------
  def new_party
    @parties.push(Game_Party.new)
  end
  #--------------------------------------------------------------------------
  # * Switch to another party
  #--------------------------------------------------------------------------
  def switch_to(party_index)
      $game_party = @parties.fetch(party_index.to_i, @parties.first)
      $game_player.refresh
  end
end
#==============================================================================
# ** Scene_Title
#------------------------------------------------------------------------------
#  This class performs the title screen processing.
#==============================================================================

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # * Create Game Objects
  #--------------------------------------------------------------------------
  alias old_create create_game_objects
  def create_game_objects
    old_create
    $game_party_manager        = Game_Party_Manager.new
  end
end
#==============================================================================
# ** Scene_File
#------------------------------------------------------------------------------
#  This class performs the save and load screen processing.
#==============================================================================

class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # * Write Save Data
  #     file : write file object (opened)
  #--------------------------------------------------------------------------
  alias old_w write_save_data
  def write_save_data(file)
    old_w(file)
    Marshal.dump($game_party_manager,         file)
  end
  #--------------------------------------------------------------------------
  # * Read Save Data
  #     file : file object for reading (opened)
  #--------------------------------------------------------------------------
  alias old_r read_save_data
  def read_save_data(file)
    old_r(file)
    $game_party_manager         = Marshal.load(file)
  end
end
