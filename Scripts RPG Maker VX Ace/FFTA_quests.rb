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

  FIGHT_ICON = 116
  DISPATCH_ICON = 234

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

class Scene_FFTA_Quest_Shop < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Prepare
  #--------------------------------------------------------------------------
  def prepare(zangteam_quests)
    @quests = zangteam_quests
  end
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  def start
    super
    create_quests_list_window
    create_quest_info_window
    create_gold_window
  end

  def create_quests_list_window
  end
  
  def create_quest_info_window
  end
  
  def create_gold_window
    @gold_window = Window_Gold.new
    @gold_window.viewport = @viewport
    @gold_window.x = Graphics.width - @gold_window.width
    @gold_window.y = Graphics.height - @gold_window.height
  end
end
