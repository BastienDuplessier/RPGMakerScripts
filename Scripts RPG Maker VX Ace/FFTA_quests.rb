# -*- coding: utf-8 -*-
class Static_Quest
  # * Champs
  integer :rank
  string :conditions
  list :item, :req_items
  skill :req_skill
  actor_type :req_job
  list :actor_type, :reco_jobs
  list :actor_type, :forb_jobs
  integer :duration
  string :duration_type
  boolean :cancellable  
  
end

module Quest

  FIGHT = 116
  DISPATCH = 234

  #--------------------------------------------------------------------------
  # * Crée une quête
  #--------------------------------------------------------------------------
  def create(hash)
    id = hash[:id]
    name = hash[:name]
    desc = hash[:desc]
    gold = hash[:gold] || 0
    exp = hash[:exp] || 0
    items = hash[:items] || []
    weapons = hash[:weapons] || []
    armors = hash[:armors] || []
    cost = hash[:cost] || -1
    repeat = hash[:repeatable] || false
    fail = hash[:fail_trigger] || Goal::trigger([:nothing]){|*o|false}
    success = hash[:success_trigger] || Goal::trigger([:nothing]){|*o|false}
    verify = hash[:verify] || lambda{|*o|true}
    endt = hash[:end_action] || lambda{|*o|true}
    confirm = hash[:need_confirmation]|| false
    s_m = hash[:success_message] || Quest_Config::DEFAULT_SUCESS.call(name)
    s_f = hash[:fail_message] || Quest_Config::DEFAULT_FAIL.call(name)
    label = hash[:label] || "quest_#{id}".to_sym
    rank = hash[:rank] || 0
    conditions = hash[:conditions] || ""
    req_items = hash[:req_items] || []
    req_skill = hash[:req_skill] || nil
    req_job = hash[:req_job] || nil
    cancellable = hash[:cancellable].ptbo
    reco_jb = hash[:reco_jobs] || []
    forb_jb = hash[:forb_jobs] || []
    duration = (hash[:duration] || 0).to_i
    duration_type = (hash[:duration_type] || :steps).intern

    Static_Quest.insert(
      id, name, desc, gold, exp, cost, repeat, items, weapons, armors, success, 
      fail, s_m, s_f, verify, endt, confirm, label, success.clone, fail.clone, 
      rank, conditions, req_items, req_skill, req_job, reco_jb, forb_jb, duration, 
      duration_type, cancellable)
  end
end

class Window_QuestBuy
  
  alias nuki_init initialize
  def initialize(x, y, quests)
    nuki_init(x, y, fitting_height(quests.size), quests)
  end

  def window_width
    (Graphics.width * 0.75).round
  end

  #--------------------------------------------------------------------------
  # * Ecrit une quête
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    rect = item_rect(index)
    draw_item_icon(item, rect.x, rect.y)
    draw_item_name(item, rect.x + 24, rect.y, enable?(item))
    rect.width -= 4
    draw_text(rect, price(item), 2) if @f
  end

  def draw_item_icon(item, x, y)
    icon = Quest.const_get(item.label.to_s.upcase)
    draw_icon(icon, x, y)
  end
end

class Window_QuestDesc < Window_Base
end

class Window_QuestRequired < Window_Base
end

class Window_QuestReward < Window_Base
end

module FFTA
  class Scene_Quest_Shop < Scene_MenuBase
    #--------------------------------------------------------------------------
    # * Prepare
    #--------------------------------------------------------------------------
    def prepare(zangteam_quests)
      @quests = Static_Quest.all.select{|i, q| zangteam_quests.include?(q.id)}.values
    end
    #--------------------------------------------------------------------------
    # * Start
    #--------------------------------------------------------------------------
    def start
      super
      create_gold_window
      create_quests_list_window
      create_quest_info_windows
    end

    def create_quests_list_window
      @quests_window = Window_QuestBuy.new(0, 0, @quests)
      @quests_window.viewport = @viewport
      @quests_window.x = (Graphics.width  - @quests_window.width) / 2
      @quests_window.y = (Graphics.height - @quests_window.height) / 2
      @quests_window.activate
      @quests_window.money = money
      @quests_window.set_handler(:cancel,    method(:return_scene))
    end
                                           
    def create_quest_info_windows
      @desc_window = Window_QuestDesc.new(0,0,0,0)
      @required_window = Window_QuestRequired.new(0,0,0,0)
      @reward_window = Window_QuestReward.new(0,0,0,0)
    end
  
    def create_gold_window
      @gold_window = Window_Gold.new
      @gold_window.viewport = @viewport
      @gold_window.x = Graphics.width - @gold_window.width
      @gold_window.y = Graphics.height - @gold_window.height
    end
    #--------------------------------------------------------------------------
    # * Or
    #--------------------------------------------------------------------------
    def money
      @gold_window.value
    end
  end
end

#==============================================================================
# ** SceneManager
#------------------------------------------------------------------------------
#  Ajout du lancement du magasin de quêtes
#==============================================================================

module SceneManager
  #--------------------------------------------------------------------------
  # * Singleton
  #--------------------------------------------------------------------------
  class << self
    #--------------------------------------------------------------------------
    # * Lance un magasin de quête
    #--------------------------------------------------------------------------
    def questShop(ids)
      call(FFTA::Scene_Quest_Shop)
      scene.prepare(ids)  
    end
  end
end
