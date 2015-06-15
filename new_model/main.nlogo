;; 2015/01/19: 
;;   1. Add three agent: Firm, University, II

;; 2015/01/30:
;;   1. Add tick concept
;;   2. save the attributes of each agent
;;   3. save the network matrix        


;; 2015/03/07
;;   1. Add Friend circle radius for every agent (means the coverage of agent)
;;   2. Add the reqeust and response collaboration behavior (firm and university)
;;   3. Add the slider for adjusting the probability of successfully collaborating 
;;   4. Add the slider for adjusting the probability of termination collaborating (probability-of-terminate-collaboration)
;;   5. Add terminate_collaboration procedure
;;   6. Add screening_for_technology_with_potential procedure (intermediary)
;;   7. Add screening_for_potential_actors procedure (intermediary)
;;   8. random change the color of link


;; 2015/03/24
;;  1. Record the value of network level to output file
;;  2. University will collaborate once it's research-maturity-level over threshold

;; 2015/04/07
;;  1. Fix bug in save-record
;;  2. Modified the collaboration behavior of firm and university
;;  3. Add customize matrix output (csv file)


;; 2015/04/14
;;  1. sort agent in record-attribute
;;  2. fix the color of link: source -> U(yellow)
;;                            source -> F(lime)
;;                            source -> TT -> target (cyan)
;;  3. add friendRadius of each role of agent


;; 2015/05/05
;; 1. Assign value to parameters automaitcally

;; 2015/06/03
;; 1. Export view and interface in every tick
;; 2. Add monitor (plot)


;; 2015/06/15
;; 1. delete agent function
;; 2. add agent function (initialise-firms; initialise-universities; initialise-TTs)



extensions [nw table pathdir]


;; the comment variables are set via user in the controll panel.
globals [
  ;   nFirms                      ; the number of firms initially
  ;   big-firms-percent           ; the percentage of firms that will be big firm
  ;   initial-firm-capital        ; the capital that a firm starts with
  initial-capital-for-big-firms   ; the amount of start-up capital for those firms set to be 'big'
  
  
  ;   nUniversities                      ; the number of universities initially
  ;   big-universities-percent           ; the percentage of firms that will be big firm
  ;   initial-university-capital         ; the capital that a university starts with
  initial-capital-for-big-universities   ; the amount of start-up capital for those universities set to be 'big'
  
  ;   nTTs                      ; the number of TTs initially
  ;   big-TTs-percent           ; the percentage of firms that will be big firm
  ;   initial-TT-capital        ; the capital that a TT starts with
  initial-capital-for-big-TTs   ; the amount of start-up capital for those TTs set to be 'big'
  
  
  track-record-value
  absorptive-capacity-value
  
  ;   FirmFriendRadius
  ;   UniversityFriendRadius
  ;   IntermediaryFriendRadius
  ;   probability-of-confirm-collaboration               ; the probability that the reqeusted collaboration agent will confirm
  ;   probability-of-terminate-collaboration             ; the probability that the collabration will be terminated
  
  ;   potentialReputaionThreshold                        ; string. the threshold that determine whether add the university to collaboration candidate agentset or not
  ;   potentialResearchMaturityLevelThreshold            ; numeric. the threshold that determine whether add the university to collaboration candidate agentset or not
  ;   potentialCapitalThreshold                          ; numeric. the threshold that determine whether add the firm to collaboration candidate agentset or not
  ;   potentialNumberOfProductInPipelineThreshold        ; numeric. the threshold that determine whether add the firm to collaboration candidate agentset or not
  
  ;   attempToCollaborateThresholdForUniversity        ; numeric, the threshold that determine whether university will reqeust collaboration 
  
  ;   technicalDomainMatchingThreshold                 ; numeric, the threshold that determine whether two agent will be matched or not
  
  ;   increaseResearchMaturityLevelProbability         ; numeric, the propability that determine whether increase research maturity level of university or not
  
  datetimeOfThisProcess                               ; string, the datetime of current running process
  
  output-file-path-prefix
]


breed [ firms firm ]
breed [ universities university ]
breed [ TTs TT ]


directed-link-breed [ partners partner ]

firms-own [
  capital
  track-record                ;; <high, medium, low>
  staff-number                ;; numeric, staff amount
  absorptive-capacity         ;; <high, medium, low>
  number-of-patent
  number-of-product-in-pipeline   ;; numeric
  technical-domain            ;; a list
  friend-circle-radius        ;; numeric, to compute the coverage of this agent
  current-collaborators       ;; a turtle-set that record partners are currently collaboraing with
  previous-collaborators      ;; a turtle-set that record partners that had collaborated with
  age
  major-investor              ;; a list
]

universities-own [
  capital
  track-record                ;; a string, <high, medium, low>
  staff-number                ;; staff amount
  number-of-patent
  technical-domain            ;; a list
  friend-circle-radius        ;; numeric, to compute the coverage of this agent
  current-collaborators       ;; a list that record partners are currently collaboraing with
  previous-collaborators      ;; a list that record partners that had collaborated with
  age
  reputation                  ;; a string, <high, medium, low>
  research-maturity-level     ;; numeric
]

TTs-own [
  capital
  track-record                ;; <high, medium, low>
  staff-number                ;; staff amount
  number-of-patent
  number-of-product-in-pipeline
  technical-domain            ;; a list  
  friend-circle-radius        ;; numeric, to compute the coverage of this agent;  the friend-circle-radius of TT is twice of other agent
  age
  with-lab?                   ;; <Y/N>
  
]

partners-own [ aggregation ]



to setup
  clear-all
  reset-ticks
  
  set datetimeOfThisProcess formating-date-time date-and-time
  set output-file-path-prefix (word "output-" datetimeOfThisProcess)
  pathdir:create(word output-file-path-prefix pathdir:get-separator "matrix")
  
  if automatically-assigns-parameters [
    ifelse not empty? inputFileName [ 
      assigns_values_of_parameters_from_csv inputFileName
    ] [ 
      user-message (word "No specified input file name") 
      set inputFileName user-input "Please type input file name"
      assigns_values_of_parameters_from_csv inputFileName
    ]
    
  ]
  
  set track-record-value list "high" "medium"
  set track-record-value lput "low" track-record-value
  set absorptive-capacity-value list "high" "medium"
  set absorptive-capacity-value lput "low" absorptive-capacity-value
  
  set initial-capital-for-big-firms 10 * initial-firm-capital
  set initial-capital-for-big-universities 10 * initial-university-capital
  set initial-capital-for-big-TTs 10 * initial-TT-capital
  

  
  
  
  initialise-firms nFirms
  initialise-universities nUniversities
  initialise-TTs nTTs
end



;; Assigns the vlaues of parameters (setting by user) from csv file
to assigns_values_of_parameters_from_csv [file-name]
  file-open file-name
  let dict table:make
  
  while [not file-at-end?] [
    ;read one line
    let items split file-read-line ","
    table:put dict (item 0 items) (try-to-read item 1 items)
  ]
  show dict
  file-close
  
  set nFirms table:get dict "nFirms"
  set big-firms-percent table:get dict "big-firms-percent"
  set initial-firm-capital table:get dict "initial-firm-capital"
  set nUniversities table:get dict "nUniversities"
  set big-universities-percent table:get dict "big-universities-percent"
  set initial-university-capital table:get dict "initial-university-capital"
  set nTTs table:get dict "nTTs"
  set big-TTs-percent table:get dict "big-TTs-percent"
  set initial-TT-capital table:get dict "initial-TT-capital"
  set FirmFriendRadius table:get dict "FirmFriendRadius"
  set UniversityFriendRadius table:get dict "UniversityFriendRadius"
  set IntermediaryFriendRadius table:get dict "IntermediaryFriendRadius"
  set probability-of-confirm-collaboration table:get dict "probability-of-confirm-collaboration"
  set probability-of-terminate-collaboration table:get dict "probability-of-terminate-collaboration"
  set potentialReputaionThreshold table:get dict "potentialReputaionThreshold"
  set potentialResearchMaturityLevelThreshold table:get dict "potentialResearchMaturityLevelThreshold"
  set potentialCapitalThreshold table:get dict "potentialCapitalThreshold"
  set potentialNumberOfProductInPipelineThreshold table:get dict "potentialNumberOfProductInPipelineThreshold"
  set attempToCollaborateThresholdForUniversity table:get dict "attempToCollaborateThresholdForUniversity" 
  set increaseResearchMaturityLevelProbability table:get dict "increaseResearchMaturityLevelProbability"
  set technicalDomainMatchingThreshold table:get dict "technicalDomainMatchingThreshold"
  
  file-open (word output-file-path-prefix pathdir:get-separator file-name)
  foreach table:keys dict [
    let key ?
    file-print (word key "," table:get dict key)
  ]
  file-close
  
  
  
  
  
  ;let dict table:make
  ;table:put dict "turtle" "cute"
  ;table:put dict "bunny" "cutest"
  ;print dict
  
  ;print table:get dict "turtle"
end


to go
  
  if initial-capital-for-big-firms != (10 * initial-firm-capital) [ setup ]
  ;;clear-all
  clear-links
  
  ask firms [
    
    ifelse display-firms != true [ 
      set hidden? true 

      if count out-partner-neighbors > 0 [
;;        let neignbor one-of out-partner-neighbors
;;        ask out-partner-to neignbor [ set hidden? false ]
           ;; get outlink neighbor
          ask out-partner-neighbors [ 
            let partner self
            ask myself [ ask out-partner-to partner [ set hidden? true ] ]
          ]
      ]
      
      if count in-partner-neighbors > 0 [
        ask in-partner-neighbors [
          let partner self
          ask myself [ ask in-partner-from partner [ set hidden? true ] ]
        ]
      ]
      
   ] [
       request_for_research_collaboration(universities)
       request_for_development_collaboration(other firms)
   ]
    
    terminate_collaboration
    
    set friend-circle-radius FirmFriendRadius ;; set friend-circle-radius again for real time adjusting
  ]
  
  ask universities [
    
    ifelse display-universities != true [ 
      set hidden? true
      ;; get outlink neighbor
      
      if count out-partner-neighbors > 0 [
;;       let neignbor one-of out-partner-neighbors
;;       ask out-partner-to neignbor [ set hidden? false ]
          ;; get outlink neighbor
         ask out-partner-neighbors [ 
           let partner self
           ask myself [ ask out-partner-to partner [ set hidden? true ] ]
         ]
      ]
      
      if count in-partner-neighbors > 0 [
        ask in-partner-neighbors [
          let partner self
          ask myself [ ask in-partner-from partner [ set hidden? true ]]
        ]
      ]
      
    ] [
    
      if research-maturity-level >= attempToCollaborateThresholdForUniversity [
;;         show(word self ": request collaboration")
         request_for_development_collaboration(firms)
         request_for_research_collaboration(other universities)
       ]
    ]
    
    terminate_collaboration
    
    if increase-research-maturity-level? [ set research-maturity-level research-maturity-level + 1 ]
    
    
    set friend-circle-radius UniversityFriendRadius ;; set friend-circle-radius again for real time adjusting
  ]
  
  ask TTs [
    
    ifelse display-TTs != true [ 
      set hidden? true 
      ;; get outlink neighbor
      let neignbor one-of out-partner-neighbors
      ask out-partner-to neignbor [ set hidden? true ]
    ] [
    
      let potential-universities screening_for_technology_with_potential  ;; find the universities that have potential research
      let potential-firms screening_for_potential_actors                  ;; find the firms that have potential technology to implement research
;;    show word "potential-universities: " potential-universities
;;      show word "potential-firms: " potential-firms
      ifelse (random 2) > 0 [
        matching potential-firms potential-universities                     ;; start matching procedure
      ] [
        matching potential-universities potential-firms                     ;; start matching procedure
      ]

      
    ]
    
    set friend-circle-radius IntermediaryFriendRadius ;; set friend-circle-radius again for real time adjusting
    
  ]
  
  nw:set-context turtles links
  
;;  show map sort nw:get-context
  
  let filename (word output-file-path-prefix pathdir:get-separator "matrix" pathdir:get-separator "matrix-" ticks ".csv")
  
;;  nw:save-matrix filename
  save-matrix filename
  
  
  set filename (word output-file-path-prefix pathdir:get-separator "angent_and_attri.txt")
  
  record-attribute filename
  
  redraw
  
  ask turtle 1 [ repeat 1 [ fd 1 wait 1  ] ]
  
  ;; export view & interface
  export-view (word output-file-path-prefix pathdir:get-separator "view")
  export-interface (word output-file-path-prefix pathdir:get-separator "interface")
 
  tick
end


to clean-up
  clear-all
end

to redraw
  
  ifelse display-firms != true [ 
    ask firms [ 
      set hidden? true
     if count out-partner-neighbors > 0 [
;;      let neignbor one-of out-partner-neighbors
;;      ask out-partner-to neignbor [ set hidden? false ]
        ;; get outlink neighbor
        ask out-partner-neighbors [ 
          let partner self
          ask myself [ ask out-partner-to partner [ set hidden? true ] ]
        ]
      ]
    ] 
  ] [
    ask firms [ 
      set hidden? false

      if count out-partner-neighbors > 0 [
;;      let neignbor one-of out-partner-neighbors
;;      ask out-partner-to neignbor [ set hidden? false ]

        ;; get outlink neighbor
        ask out-partner-neighbors [ 
          let partner self
          ask myself [ ask out-partner-to partner [ set hidden? false ] ]
        ]
      ]

    ] 
  ]
  
  ifelse display-universities != true [ 
    ask universities [ 
      set hidden? true
      
      if count out-partner-neighbors > 0 [
;;      let neignbor one-of out-partner-neighbors
;;      ask out-partner-to neignbor [ set hidden? false ]
        ;; get outlink neighbor
        ask out-partner-neighbors [ 
          let partner self
          ask myself [ ask out-partner-to partner [ set hidden? true ] ]
        ]
      ]
    ] 
  ] [
    ask universities [ 
      set hidden? false
      if count out-partner-neighbors > 0 [
;;      let neignbor one-of out-partner-neighbors
;;      ask out-partner-to neignbor [ set hidden? false ]

        ;; get outlink neighbor
        ask out-partner-neighbors [ 
          let partner self
          ask myself [ ask out-partner-to partner [ set hidden? false ] ]
        ]
      ]
    ] 
  ]
  
  ifelse display-TTs != true [ 
    ask TTs [ 
      set hidden? true
      
      if count out-partner-neighbors > 0 [
        ;; get outlink neighbor
        ask out-partner-neighbors [ 
          let partner self
          ask myself [ ask out-partner-to partner [ set hidden? true ] ]
        ]
      ]
    ] 
  ] [
    ask TTs [ 
      set hidden? false
      
      if count out-partner-neighbors > 0 [
        ;; get outlink neighbor
        ask out-partner-neighbors [ 
          let partner self
          ask myself [ ask out-partner-to partner [ set hidden? false ] ]
        ]
      ]
    ] 
  ]
end





to ring
  generate task [ nw:generate-ring firms partners nFirms]
end


to betweenness
  centrality task nw:betweenness-centrality
end

to eigenvector
  centrality task nw:eigenvector-centrality
end

to closeness
  centrality task nw:closeness-centrality
end

to page-rank
  centrality task nw:page-rank
end

;;to weighted-closeness
 ;; centrality task nw:weighted-closeness-centrality
;;end


;; observer procedure
to initialise-firms [number]
  create-firms number [
    set capital initial-firm-capital
    set track-record one-of track-record-value
    set staff-number (random 100)                       
    set absorptive-capacity one-of absorptive-capacity-value
    set number-of-patent (random 100)
    set number-of-product-in-pipeline (random 100)
    set technical-domain list (random 10) (random 10) 
    set shape "circle"
    setxy random-pxcor random-pycor
    set friend-circle-radius FirmFriendRadius
    set current-collaborators (turtle-set)
    set previous-collaborators (turtle-set)
    set major-investor (turtle-set)
  ]
  
  ;  make some of them large firms, with extra initial capital
  ask n-of round ((big-firms-percent / 100) * nFirms) firms [ ;;bug fix for v 5-32: added /100
    ;; n-of size agnetset/list => Randomly chose n agents
    set capital initial-capital-for-big-firms
  ]
  
end

;; observer procedure
to initialise-universities [number]
  create-universities number [
    set capital initial-university-capital
    set track-record one-of track-record-value
    set staff-number (random 100)                       
    set number-of-patent (random 100)
    set technical-domain list (random 10) (random 10)
    set shape "triangle"
    setxy random-pxcor random-pycor
    set friend-circle-radius UniversityFriendRadius
    set current-collaborators (turtle-set)
    set previous-collaborators (turtle-set)
    set reputation one-of (list "high" "medium" "low")
    set research-maturity-level (random 10)   
  ]
  
    ;  make some of them large firms, with extra initial capital
  ask n-of round ((big-universities-percent / 100) * nUniversities) universities [ ;;bug fix for v 5-32: added /100
    ;; n-of size agnetset/list => Randomly chose n agents
    set capital initial-capital-for-big-universities
  ]
end

;; observer procedure
to initialise-TTs [number]
  create-TTs number [
    set capital initial-tt-capital
    set track-record one-of track-record-value
    set staff-number (random 100)                       
    set number-of-patent (random 100)
    set number-of-product-in-pipeline (random 100)
    set technical-domain list (random 10) (random 10)
    set shape "target"
    setxy random-pxcor random-pycor
    set friend-circle-radius IntermediaryFriendRadius
  ]
  
      ;  make some of them large firms, with extra initial capital
  ask n-of round ((big-TTs-percent / 100) * nTTs) TTs [ ;;bug fix for v 5-32: added /100
    ;; n-of size agnetset/list => Randomly chose n agents
    set capital initial-capital-for-big-TTs
  ]
end



to generate [ generator-task ]
  ; we have a general "generate" procedure that basically just takes a task 
  ; parameter and run it, but takes care of calling layout and update stuff
  set-default-shape turtles "circle"
  run generator-task
  update-plots
end








;; Takes a centrality measure as a reporter task, runs it for all nodes
;; and set labels, sizes and colors of turtles to illustrate result
to centrality [ measure ]
  nw:set-context turtles partners
  ask turtles [
    let res (runresult measure) ;; run the task for the turtle
    ifelse is-number? res [
      set label precision res 2
      set size res ;; this will be normalized later
;;      show label
  ;;    show self
    ]
    [ ;; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
      set label res
      set size 1
    ;;  show label
;;      show self
    ]
  ]
  normalize-sizes-and-colors
end


to normalize-sizes-and-colors
  if count turtles > 0 [
    let sizes sort [ size ] of turtles ;; initial sizes in increasing order
    let delta last sizes - first sizes ;; difference between biggest and smallest
    ifelse delta = 0 [ ;; if they are all the same size
      ask turtles [ set size 1 ]
    ]
    [ ;; remap the size to a range between 0.5 and 2.5
      ask turtles [ set size ((size - first sizes) / delta) * 2 + 0.5 ]
    ]
    ask turtles [ set color scale-color red size 0 5 ] ; using a higher range max not to get too white...
  ]
end



;; firm and university procedure (target: university )
;; parameter: unversities (turtle-set)
;; F/U -> U color of link: yellow = 45
to request_for_research_collaboration [candicate-universities]
  let myself-current-collaborators current-collaborators
  
  let selected-candicate best_fit_university candicate-universities
  
  if selected-candicate != nobody [
    ;; User define probability
    if confirm-to-collaborate? [
      ask selected-candicate [
        set myself-current-collaborators (turtle-set myself-current-collaborators self)  ;; save university to current partner to list
        set current-collaborators (turtle-set current-collaborators myself)   ;; save firm to current partner list          
      ]
    ]
  ]
  
  
  set current-collaborators myself-current-collaborators ;; save agentset back
  
  
  ask current-collaborators [
    let partner self
    ;let link-color (list (random 256) (random 256) (random 256))
    let link-color 45
    ask myself [ create-partner-to partner [ set color link-color ] ] ;; create link
  ]
  
end



;; firm/university procedure (target: firm)
;; parameter: firms (turtle-set)
;; F/U -> F color of link: lime = 65
to request_for_development_collaboration [candicate-firms]
  let myself-current-collaborators current-collaborators
  
  let selected-candicate best_fit_firm candicate-firms
  
  if selected-candicate != nobody [
    ;; User define probability
    if confirm-to-collaborate? [
      ask selected-candicate [
        set myself-current-collaborators (turtle-set myself-current-collaborators self)  ;; save university to current partner to list
        set current-collaborators (turtle-set current-collaborators myself)   ;; save firm to current partner list          
      ]
    ]
  ]
  
  
  set current-collaborators myself-current-collaborators ;; save agentset back
  
  ask current-collaborators [
    let partner self
;;    let link-color (list (random 256) (random 256) (random 256))
    let link-color 65
    ask myself [ create-partner-to partner [ set color link-color ] ]
  ]
  
end



;; firm procedure
to accept_development_collaboration
end

;; university procedure
to accept_research_collaboration
end


;; firm and university procedure
;; 目前先隨機從current-collaborators 挑選 partner來終止合作，之後改成對特定partner終止合作
to terminate_collaboration
  let myself-previous-collaborators previous-collaborators
  let myself-current-collaborators current-collaborators
  ask current-collaborators [
    if terminate-to-collaborate? [
      set current-collaborators current-collaborators with [ self != myself ]  ;; remove I from partner's current-collaborators
      set previous-collaborators (turtle-set previous-collaborators myself)      ;; save I to partner's previous-collaborators
      let partner self
      ask myself [ 
        let links-on-the-path nw:path-to partner
        foreach links-on-the-path [
;;          show(word "die: " ?)
          ask ? [ die ]
        ]
;;        if out-link-neighbor? partner [ 
;;          show(word "die: " partner)
;;          ask out-partner-to partner [ die ] 
;;        ] 
      ]
      set myself-previous-collaborators (turtle-set myself-previous-collaborators partner)  ;; save the current-partner to previous-collaborators
      set myself-current-collaborators myself-current-collaborators with [ self != partner ]  ;; remove the partner from current-collaborators
    ]
  ]
  
 
  set previous-collaborators myself-previous-collaborators
  set current-collaborators myself-current-collaborators
  
end


;; delete particular agent
to delete-agent [agent]
  ask agent [die]
end




;; intermediary reporter, to find the universities who have the potential to research technology. return an agentset
to-report screening_for_technology_with_potential
  let potential-candidates (turtle-set)
  ask universities in-radius friend-circle-radius [
;;    show(word "potential u: reputation: " reputation ", research-maturity-level: " research-maturity-level)
    ifelse potentialReputaionThreshold = "high" [
      if (reputation = "high" and research-maturity-level >= potentialResearchMaturityLevelThreshold) [ set potential-candidates (turtle-set potential-candidates self) ]
    ] [
      ifelse potentialReputaionThreshold = "medium" [
        if ((reputation = "high" or reputation = "medium") and research-maturity-level >= potentialResearchMaturityLevelThreshold) [ set potential-candidates (turtle-set potential-candidates self) ] 
      ] [
        ifelse potentialReputaionThreshold = "low" [
          if ((reputation = "high" or reputation = "medium" or reputation = "low") and research-maturity-level >= potentialResearchMaturityLevelThreshold) [ set potential-candidates (turtle-set potential-candidates self) ] 
        ] [
        ]
      ]
    ]
  ]
  report potential-candidates
end

;; intermediary procedure, to find the firms who have the potential to implement research. return an agentset
to-report screening_for_potential_actors
  let potential-candidates (turtle-set)
  ask firms in-radius friend-circle-radius [
    if capital >= potentialCapitalThreshold and number-of-product-in-pipeline >= potentialNumberOfProductInPipelineThreshold [ set potential-candidates (turtle-set potential-candidates self)]
  ]
  report potential-candidates
end

;; intermediary procedure, to match firm and university
;; link-color: cyan = 85
to matching [potential-sources potential-targets]
  let current-intermediary self
  
  ask potential-sources [
    let current-source self
    let source-current-collaborators current-collaborators
   ;; show(word "in matching; current-university" current-university)
    ask potential-targets [
      let current-target self 
      let target-current-collaborators current-collaborators
      
      
      if not member? current-source current-collaborators [  ;; if they are not collaborating cuurently
        let score compare-technical-domain ([technical-domain] of current-source) ([technical-domain] of current-target)
        if score >= (technicalDomainMatchingThreshold / 100) [  ;; collaborate
          set source-current-collaborators (turtle-set source-current-collaborators current-target)  ;; save the collaborator to current-collaborators list
          set target-current-collaborators (turtle-set target-current-collaborators current-source)  ;; save the collaborator to current-collaborators list
          
          ;; create link connect firm and university through intermediary
;;          let link-color (list (random 256) (random 256) (random 256)) ;; set color of link
          let link-color 85
          
          show(word "matching source: " current-source ", dest: " current-target )
          
          ask current-source [ create-partner-to current-intermediary [ set color link-color ] ]
          ask current-intermediary [ create-partner-to current-target [ set color link-color ] ]
        ]
      ]
    ;;  show(word "in matching; current-university" current-firm)
    
      set current-collaborators target-current-collaborators    
    ]
    
    set current-collaborators source-current-collaborators 
  ]
  
end





;; Observer procedure
to record-attribute [filename]
;  file-open "output/angent_count_and_attribute.txt"
  file-open filename
  file-print(word "================tick: " ticks " ================")
  file-print(word "total agent: " count turtles)
  file-print(word "count firm: " count firms)
  file-print(word "count university: " count universities)
  file-print(word "count TT: " count TTs)
  
  nw:set-context turtles partners
  
  file-print(word "############## Firm Attribute ############")
  
  foreach sort firms [
    ask ? [
        let prefix (word self)
        file-print(word prefix "capital: " capital)
        file-print(word prefix "track-record: " track-record)
        file-print(word prefix "staff-number: " staff-number)
        file-print(word prefix "absorptive-capacity: " absorptive-capacity)
        file-print(word prefix "number-of-patent: " number-of-patent)
        file-print(word prefix "number-of-product-in-pipeline: " number-of-product-in-pipeline) 
        file-print(word prefix "technical-domain: " technical-domain)
        
        ;; record the betweenness
        let res (runresult task nw:betweenness-centrality)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "betweenness-centrality: " res)
        
        ;; record the eigenvector
        set res (runresult task nw:eigenvector-centrality)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "eigenvector-centrality: " res)
        
        
        ;; record the closeness
        set res (runresult task nw:closeness-centrality)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "closeness-centrality: " res)
        
        ;; record the page-rank
        set res (runresult task nw:page-rank)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "page-rank: " res)
        
        file-print ""
    ]
  ]


  
  file-print(word "############## University Attribute ##############")  
  
  foreach sort universities [
      ask ? [
        let prefix (word self)
        file-print(word prefix "capital: " capital)
        file-print(word prefix "track-record: " track-record)
        file-print(word prefix "staff-number: " staff-number)
        file-print(word prefix "number-of-patent: " number-of-patent)
        file-print(word prefix "technical-domain: " technical-domain)
        
        ;; record the betweenness
        let res (runresult task nw:betweenness-centrality)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "betweenness-centrality: " res)
        
        ;; record the eigenvector
        set res (runresult task nw:eigenvector-centrality)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "eigenvector-centrality: " res)
        
        ;; record the closeness
        set res (runresult task nw:closeness-centrality)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "closeness-centrality: " res)
        
        
        ;; record the page-rank
        set res (runresult task nw:page-rank)
        if is-number? res [ set res precision res 2 ]
        file-print(word prefix "page-rank: " res)
        
        
        file-print ""
      ]
  ]
  

  
  file-print(word "##############TT Attribute ##############")
  
foreach sort TTs [
  ask ? [
    let prefix (word self)
    file-print(word prefix "capital: " capital)
    file-print(word prefix "track-record: " track-record)
    file-print(word prefix "staff-number: " staff-number)
    file-print(word prefix "number-of-patent: " number-of-patent)
    file-print(word prefix "number-of-product-in-pipeline: " number-of-product-in-pipeline) 
    file-print(word prefix "technical-domain: " technical-domain)
    
    ;; record the betweenness
    let res (runresult task nw:betweenness-centrality)
    if is-number? res [ set res precision res 2 ]
    file-print(word prefix "betweenness-centrality: " res)
    
    ;; record the eigenvector
    set res (runresult task nw:eigenvector-centrality)
    if is-number? res [ set res precision res 2 ]
    file-print(word prefix "eigenvector-centrality: " res)
    
    ;; record the closeness
    set res (runresult task nw:closeness-centrality)
    if is-number? res [ set res precision res 2 ]
    file-print(word prefix "closeness-centrality: " res)
    
    ;; record the page-rank
    set res (runresult task nw:page-rank)
    if is-number? res [ set res precision res 2 ]
    file-print(word prefix "page-rank: " res)
    
    file-print ""
  ]
]

  
  file-close
end



to save-matrix [ filename ]
  if file-exists? filename [ file-delete filename ]
  file-open filename
  let turtle-list sort turtles
  
  file-type " ,"
  foreach turtle-list [ 
    file-write ?
    file-type ","
  ]
  file-print ""
  
  foreach turtle-list [
    let source ?
    file-type word source ","
    
    foreach turtle-list [
       let target ?
       ifelse [ link-neighbor? target ] of source [
         file-type "1,"
       ] [
         file-type "0,"
       ]
    ]
    file-print ""
  ]
  file-close
end



;; report whether two agent will collaborate successfully or not
to-report confirm-to-collaborate?
  let x random 100
  ifelse x < (probability-of-confirm-collaboration) [report true] [report false]
end

to-report terminate-to-collaborate?
  let x random 100
  ifelse x < (probability-of-terminate-collaboration) [report true] [report false]
end


;; report the common technical domain
to-report compare-technical-domain [list1 list2]
  let score 0
  let denominator 0
  let length1 length list1
  let length2 length list2
  ifelse length1 >= length2 [ set denominator length1 ] [set denominator length2]
  foreach list1 [
    if (member? ? list2) [set score score + 1]
  ]
  ;; 分數的算法 ＝  match的技術 / 較長的技術list  
  ;; ex list1 = [1 2], list2 = [1 2 3]. score = 2 / 3
  ;;report score / denominator
  
  ;; match的技術數量/雙方的技術數量和
  report score / (length list1 + length list2)
end

;; report true if university is ready for increasing research-maturity-level
to-report increase-research-maturity-level?
  let x random 100  
  ifelse x < increaseResearchMaturityLevelProbability [report true] [report false]
end
  
  
;; Report the best fit university to research collaboration with
;; Asker: firm, university
to-report best_fit_university [us]
  let myself-current-collaborators current-collaborators
  let candicates (turtle-set)
  let score 0
  let current-max -1
  ask us in-radius friend-circle-radius [
    if not member? self myself-current-collaborators [
      set score reputation_to_value reputation + research-maturity-level
      if score > current-max [
        set candicates (turtle-set self)
        set current-max score
      ]
    ]
  ]
  
  ;; report one candicate in candicates (randomly)
  report one-of candicates
end

;; Report the best fit firm to research collaboration
;; Asker: firm, university
to-report best_fit_firm [fs]
  let myself-current-collaborators current-collaborators
  let candicates (turtle-set)
  let myself-major-investor (turtle-set)
  
  if [breed] of self = firms [set myself-major-investor major-investor]
  let asker self
  let current-max -1
  
  ask fs in-radius friend-circle-radius [
    let score 0
    if not member? self myself-current-collaborators [
      ifelse [breed] of asker = firms [
      ;; firm ask collaboration
      ;; previous partner? + Have same major investor? + capital + Number of products in pipeline
        if contain myself-major-investor major-investor [ set score (score + 1)]
        set score (score + capital + number-of-product-in-pipeline)
        if score > current-max [
          set candicates (turtle-set self)
          set current-max score
        ]
      
      ] [
        ;; university ask collaboration
        ;; previous partner? + capital + Number of products in pipeline + Absorptive capacity
        set score (score + capital + number-of-product-in-pipeline + absorptive_capacity_to_value absorptive-capacity)
        if score > current-max [
          set candicates (turtle-set self)
          set current-max score
        ]
      ] 
    ]
  ]
  
  show candicates
  show one-of candicates
  
  report one-of candicates
end





;; utilities
to-report contain[source target]
  ask source [
    if member? self target [report true]
  ]
  report false
end

to-report absorptive_capacity_to_value [absorptive]
  if absorptive = "high" [report 10]
  
  if absorptive = "medium" [report 5]
  
  if absorptive = "low" [report 0]
end

to-report reputation_to_value [rep]
  if rep = "high" [report 10]
  
  if rep = "medium" [report 5]
  
  if rep = "low" [report 0]
end



to-report try-to-read [ string ]
  let result string
  carefully [ set result read-from-string string ] []
  report result
end

to-report split [ string delim ]
  report reduce [
    ifelse-value (?2 = delim)
      [ lput "" ?1 ]
      [ lput word last ?1 ?2 but-last ?1 ]
  ] fput [""] n-values (length string) [ substring string ? (? + 1) ]
end


to-report formating-date-time [datetime]
  let result split datetime " "
  let date item 2 result
  let ampm item 1 result
  let time item 0 result
  set time split time "."
  set time item 0 time
  set time replace-item 2 time "-"
  set time replace-item 5 time "-"
  set result(word date "-" ampm time)
  report result
end





; ======================================== Testing function ============================================


to read-content

  let line1 "MyAge\t20\tMyYear\t1994" ; in real life, you'll use file-read-line
  let items split line1 "\t"
  show items ; will be: ["MyAge" "20" "MyYear" "1994"]

  ; If you know the types, you can read the items one by one.
  ; Only apply `read-from-string` to numbers:
  let itemsAB1 (list
    item 0 items
    read-from-string item 1 items
    item 2 items
    read-from-string item 3 items
  )
;  show itemsAB1 ; ["MyAge" 20 "MyYear" 1994]

  ; You could also "carefully" try to convert everything to numbers:
  let itemsAB2 map try-to-read items
;  show itemsAB2 ; ["MyAge" 20 "MyYear" 1994]

end


to test
  create-turtles 10
  ;; in random order
  layout-circle turtles 10
  ;; in order by who number
  layout-circle sort turtles 10
  ;; in order by size
  layout-circle sort-by [[size] of ?1 < [size] of ?2] turtles 10
end


to go2
   CRT 3
   ASK TURTLES 
   [ SHOW "LEVEL 1----------"
     ASK OTHER TURTLES [
       SHOW (WORD "-----LEVEL 2- SELF:" SELF) 
       SHOW (WORD "-----LEVEL 2-MYSELF:" MYSELF) 
       ASK OTHER TURTLES [
         SHOW (WORD "----------LEVEL 3- SELF:" SELF) 
         SHOW (WORD "-----------LEVEL 3-MYSELF:" MYSELF)
         SHOW (WORD "-----------LEVEL 3-MYSELF-OF-MYSELF:" [MYSELF ] OF MYSELF)

       ]]]
  
end


; ======================================== Testing function ============================================
@#$#@#$#@
GRAPHICS-WINDOW
568
33
1007
493
16
16
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
1035
47
1098
80
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
109
173
142
initial-firm-capital
initial-firm-capital
0
100
30
1
1
NIL
HORIZONTAL

BUTTON
1109
47
1196
80
NIL
clean-up
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1036
129
1147
162
NIL
betweenness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
187
56
349
89
nUniversities
nUniversities
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
182
112
356
145
initial-university-capital
initial-university-capital
0
100
30
1
1
NIL
HORIZONTAL

BUTTON
1037
178
1141
211
NIL
eigenvector
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1039
228
1132
261
NIL
closeness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
365
55
521
88
nTTs
nTTs
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
364
108
536
141
initial-tt-capital
initial-tt-capital
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
5
170
171
203
big-firms-percent
big-firms-percent
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
180
171
348
204
big-universities-percent
big-universities-percent
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
364
171
536
204
big-TTs-percent
big-TTs-percent
0
100
30
1
1
NIL
HORIZONTAL

SWITCH
1042
367
1182
400
display-firms
display-firms
0
1
-1000

SWITCH
1044
416
1223
449
display-universities
display-universities
0
1
-1000

SWITCH
1044
461
1175
494
display-TTs
display-TTs
0
1
-1000

BUTTON
1047
518
1121
551
NIL
redraw
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1035
88
1101
121
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
922
676
1217
709
probability-of-confirm-collaboration
probability-of-confirm-collaboration
0
100
30
1
1
%
HORIZONTAL

SLIDER
918
742
1223
775
probability-of-terminate-collaboration
probability-of-terminate-collaboration
0
100
30
1
1
%
HORIZONTAL

CHOOSER
86
587
298
632
potentialReputaionThreshold
potentialReputaionThreshold
"high" "medium" "low"
0

SLIDER
84
652
393
685
potentialResearchMaturityLevelThreshold
potentialResearchMaturityLevelThreshold
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
85
712
298
745
potentialCapitalThreshold
potentialCapitalThreshold
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
84
776
426
809
potentialNumberOfProductInPipelineThreshold
potentialNumberOfProductInPipelineThreshold
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
81
837
371
870
technicalDomainMatchingThreshold
technicalDomainMatchingThreshold
0
100
30
1
1
%
HORIZONTAL

BUTTON
1039
267
1135
300
NIL
page-rank
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
923
613
1243
646
increaseResearchMaturityLevelProbability
increaseResearchMaturityLevelProbability
0
100
30
1
1
%
HORIZONTAL

SLIDER
78
953
420
986
attempToCollaborateThresholdForUniversity
attempToCollaborateThresholdForUniversity
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
4
55
176
88
nFirms
nFirms
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
5
223
169
256
FirmFriendRadius
FirmFriendRadius
0
sqrt (max-pxcor * max-pxcor + max-pycor * max-pycor)
30
1
1
NIL
HORIZONTAL

SLIDER
181
223
350
256
UniversityFriendRadius
UniversityFriendRadius
0
sqrt (max-pxcor * max-pxcor + max-pycor * max-pycor)
30
1
1
NIL
HORIZONTAL

SLIDER
360
223
543
256
IntermediaryFriendRadius
IntermediaryFriendRadius
0
sqrt (max-pxcor * max-pxcor + max-pycor * max-pycor)
30
1
1
NIL
HORIZONTAL

TEXTBOX
87
534
237
554
Threshold
16
0.0
1

TEXTBOX
318
593
664
638
A threshold that determine whether the reputation of university is enough to be a potential collbaorator to be  matched by Intermediary
12
0.0
1

TEXTBOX
412
649
806
696
A threshold that determine whether the Research Maturity Level of university is enough to be a potential collbaorator to be matched by Intermediary
12
0.0
1

TEXTBOX
310
712
724
742
A threshold that determine whether the capital of firm is enough to be a potential collbaorator to be matched by Intermediary
12
0.0
1

TEXTBOX
442
778
899
810
A threshold that determine whether the amount of product in pipeline of firm is enough to be a potential collbaorator to be matched by Intermediary\n
12
0.0
1

TEXTBOX
387
834
839
878
A threshold that determine whether the percent of matching techical domain between two university and firm  is enough to collaborate with and matched by Intermediary\n
12
0.0
1

TEXTBOX
439
956
864
1000
A threshold that determines whether the research maturity level of university is enough to request collaborate with others.\n
12
0.0
1

TEXTBOX
930
570
1080
590
Probability
16
0.0
1

TEXTBOX
1258
614
1627
648
A probability that determines whether university will increase his research maturity level or not
12
0.0
1

TEXTBOX
1246
678
1587
710
A probability that determines whether two agent will successfully collaborate with each other
12
0.0
1

TEXTBOX
1245
741
1569
775
A probability that determines whether two collaborators will terminate their collaboration or not
12
0.0
1

SWITCH
1247
365
1517
398
automatically-assigns-parameters
automatically-assigns-parameters
0
1
-1000

INPUTBOX
1247
413
1482
473
inputFileName
input.csv
1
0
String

PLOT
262
310
462
460
Plot
Ticks
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Link" 1.0 0 -13840069 true "" "plot count links"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
