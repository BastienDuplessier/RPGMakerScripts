#==============================================================================
# ** Dynamic TP choice
#------------------------------------------------------------------------------
#  Allow to chose when to activate TP system using methods.
#    - $game_system.enable_tp  : Enable tp system
#    - $game_system.disable_tp : Disable tp system 
#==============================================================================

class Game_System
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :tp_enabled            # TP gauges displayed
  #--------------------------------------------------------------------------
  # * Post-Load Processing
  #--------------------------------------------------------------------------
  alias old_after_load on_after_load
  def on_after_load
    old_after_load
    $data_system.opt_display_tp = @tp_enabled unless @tp_enabled.nil?
  end
  #--------------------------------------------------------------------------
  # * Enable tp system
  #--------------------------------------------------------------------------
  def enable_tp
    $data_system.opt_display_tp = @tp_enabled = true
  end
  #--------------------------------------------------------------------------
  # * Disable tp system
  #--------------------------------------------------------------------------
  def disable_tp
    $data_system.opt_display_tp = @tp_enabled = false
  end
end
