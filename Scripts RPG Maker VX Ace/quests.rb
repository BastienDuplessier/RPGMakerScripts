# -*- coding: utf-8 -*-
# Quest : L'éveil des monts
Quest.create(id: 1, label: :fight, rank: 1, name: "L'éveil du mont", 
  desc: "Le volcan de Roda est de nouveau en activité. Vous pourriez aller étudier 
         ce phénomène? (Ah oui, faut aimer la chaleur!).", 
  cost: 1600, gold: 11400, item: [2, 3], cancellable: false)
# Quest : Le sablier d'or
Quest.create(id: 2, label: :fight, rank: 2, name: "Le sablier d'or", 
  desc: "Un brigand vend des copies de notre célèbre 'Sablier d'Or'. Faut l'arrêter ! 
         Le faussaire se trouve dans le désert Jeraw.", 
  cost: 2400, gold: 18000, weapons: [5], cancellable: false)
# Quest : Etoffe magique
Quest.create(id: 3, label: :dispatch, rank: 1, name: "Etoffe magique", 
  desc: "Bonjour, j'échange du tissu magik contre du coton magik. Vous en avez?", 
  cost: 1400, items: [5], req_items: [4], reco_job: [1], duration: 100, 
  duration_type: :steps, cancellable: false)
