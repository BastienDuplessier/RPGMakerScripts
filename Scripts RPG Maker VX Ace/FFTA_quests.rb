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

    Static_Quest.insert(
      id, name, desc, gold, exp, cost, repeat, items, weapons, armors, success, fail, 
      s_m, s_f, verify, endt, confirm, label, success.clone, fail.clone,
      rank, conditions, req_items, req_skill, req_job, cancellable)
  end
end
