;; 2015/01/19: 
;;   1. Add three agent: Firm, University, II

;; 2015/01/30:
;;   1. Add tick concept
;;   2. save the attributes of each agent
;;   3. save the network matrix        


;; 2015/03/07
;;   1. Add Friend circle radius for every agent (means the coverage of agent)
;;   2. Add the reqeust and response collaboration behavior (firm and university)
;;   3. Add the slider for adjusting the probability of successfully collaborating (probability-of-accepting-collaboration, probability-of-confirm-collaboration)
;;   4. Add the slider for adjusting the probability of termination collaborating (probability-of-terminate-collaboration)
;;   5. Add terminate_collaboration procedure
;;   6. Add screening_for_technology_with_potential procedure (intermediary)
;;   7. Add screening_for_potential_actors procedure (intermediary)
;;   8. random change the color of link


extensions [ nw ]


;; the comment variables are set via user in the controll panel.
globals [
  ;   nFirms                      ; the number of firms initially
  ;   n-big-firms                 ; number of firms with 10 times initial capital of rest
  ;   big-firms-percent           ; the percentage of firms that will be big firm
  ;   initial-firm-capital        ; the capital that a firm starts with
  initial-capital-for-big-firms   ; the amount of start-up capital for those firms set to be 'big'
  
  
  ;   nUniversities                      ; the number of universities initially
  ;   n-big-universities                 ; number of universities with 10 times initial capital of rest
  ;   big-universities-percent           ; the percentage of firms that will be big firm
  ;   initial-university-capital         ; the capital that a university starts with
  initial-capital-for-big-universities   ; the amount of start-up capital for those universities set to be 'big'
  
  ;   nTTs                      ; the number of TTs initially
  ;   n-big-TTs                 ; number of TTs with 10 times initial capital of rest
  ;   big-TTs-percent           ; the percentage of firms that will be big firm
  ;   initial-TT-capital        ; the capital that a TT starts with
  initial-capital-for-big-TTs   ; the amount of start-up capital for those TTs set to be 'big'
  
  
  track-record-value
  absorptive-capacity-value
  
  ;   baseFriendCircleRadius            ; the base friend circle radius of agent //  Radius(firm) = Radius(University) = 1/2 Raidus(TT)
  ;   probability-of-accepting-collaboration  ; the probability that the reqeusted collaboration agent will accept
  ;   probability-of-confirm-collaboration    ; the probability that the reqeusted collaboration agent will confirm
  ;   probability-of-terminate-collaboration  ; the probability that the collabration will be terminated
  
  ;   potentialReputaionThreshold              ; string. the threshold that determine whether add the university to collaboration candidate agentset or not
  ;   potentialResearchMaturityLevelThreshold   ; numeric. the threshold that determine whether add the university to collaboration candidate agentset or not
  ;   potentialCapitalThreshold                 ; numeric. the threshold that determine whether add the firm to collaboration candidate agentset or not
  ;   potentialNumberOfProductInPipelineThreshold        ; numeric. the threshold that determine whether add the firm to collaboration candidate agentset or not
  
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
  current-collaborators       ;; a list that record partners are currently collaboraing with
  previous-collaborators      ;; a list that record partners that had collaborated with
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

to test
  create-turtles 10
  ;; in random order
  layout-circle turtles 10
  ;; in order by who number
  layout-circle sort turtles 10
  ;; in order by size
  layout-circle sort-by [[size] of ?1 < [size] of ?2] turtles 10
end


to setup
  clear-all
  reset-ticks
  
  set track-record-value list "high" "medium"
  set track-record-value lput "low" track-record-value
  set absorptive-capacity-value list "high" "medium"
  set absorptive-capacity-value lput "low" absorptive-capacity-value
  
  set initial-capital-for-big-firms 10 * initial-firm-capital
  set initial-capital-for-big-universities 10 * initial-university-capital
  set initial-capital-for-big-TTs 10 * initial-TT-capital
  
  initialise-firms 
  initialise-universities
  initialise-TTs
end

to go2
 ;; if initial-capital-for-big-firms != (10 * initial-firm-capital) [ setup ]
  
;;  ask firms [find-partner(universities)]
;;  ask turtles [ 
;;    ask patches in-radius 3 [ set pcolor red ] 
 ;;  ask other turtles in-radius 1 [ set pcolor red ] 
   
   ;;]
   
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
    
    set friend-circle-radius baseFriendCircleRadius ;; set friend-circle-radius again for real time adjusting
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
       request_for_development_collaboration(firms)
       request_for_research_collaboration(other universities)
    ]
    
    terminate_collaboration
    
    
    set friend-circle-radius baseFriendCircleRadius ;; set friend-circle-radius again for real time adjusting
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
;;      show word "potential-universities: " potential-universities
;;      show word "potential-firms: " potential-firms
      ifelse (random 2) > 0 [
        matching potential-firms potential-universities                     ;; start matching procedure
      ] [
        matching potential-universities potential-firms                     ;; start matching procedure
      ]

      
    ]
    
    set friend-circle-radius (baseFriendCircleRadius * 2) ;; set friend-circle-radius again for real time adjusting
    
  ]
  
  nw:set-context turtles links
  
;;  show map sort nw:get-context
  
  let filename (word "output/matrix/matrix-" ticks ".txt")
  nw:save-matrix filename
  
  set filename "output/angent_and_attri.txt"
  
  record-attribute
  
  redraw
  
  ask turtle 1 [ repeat 1 [ fd 1 wait 1  ] ]
 
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


;; observer procedure
to initialise-firms
  create-firms nFirms [
    set capital initial-firm-capital
    set track-record one-of track-record-value
    set staff-number (random 100)                       
    set absorptive-capacity one-of absorptive-capacity-value
    set number-of-patent (random 100)
    set number-of-product-in-pipeline (random 100)
    set technical-domain list (random 10) (random 10) 
    set shape "circle"
    setxy random-pxcor random-pycor
    set friend-circle-radius baseFriendCircleRadius
    set current-collaborators (turtle-set)
    set previous-collaborators (turtle-set)
  ]
  
  ;  make some of them large firms, with extra initial capital
  ask n-of round ((big-firms-percent / 100) * nFirms) firms [ ;;bug fix for v 5-32: added /100
    ;; n-of size agnetset/list => Randomly chose n agents
    set capital initial-capital-for-big-firms
  ]
  
end

;; observer procedure
to initialise-universities 
  create-universities nUniversities [
    set capital initial-university-capital
    set track-record one-of track-record-value
    set staff-number (random 100)                       
    set number-of-patent (random 100)
    set technical-domain list (random 10) (random 10)
    set shape "triangle"
    setxy random-pxcor random-pycor
    set friend-circle-radius baseFriendCircleRadius
    set current-collaborators (turtle-set)
    set previous-collaborators (turtle-set)
    set reputation one-of (list "high" "medium" "low")
    set research-maturity-level (random 100)   
  ]
  
    ;  make some of them large firms, with extra initial capital
  ask n-of round ((big-universities-percent / 100) * nUniversities) universities [ ;;bug fix for v 5-32: added /100
    ;; n-of size agnetset/list => Randomly chose n agents
    set capital initial-capital-for-big-universities
  ]
end

;; observer procedure
to initialise-TTs
  create-TTs nTTs [
    set capital initial-tt-capital
    set track-record one-of track-record-value
    set staff-number (random 100)                       
    set number-of-patent (random 100)
    set number-of-product-in-pipeline (random 100)
    set technical-domain list (random 10) (random 10)
    set shape "target"
    setxy random-pxcor random-pycor
    set friend-circle-radius 2 * baseFriendCircleRadius
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
  show measure
  nw:set-context turtles partners
  ask turtles [
    let res (runresult measure) ;; run the task for the turtle
    ifelse is-number? res [
      set label precision res 2
      set size res ;; this will be normalized later
    ]
    [ ;; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
      set label res
      set size 1
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



;; firm and university procedure (only to university)
to request_for_research_collaboration [candidate-universities]
  let myself-current-collaborators current-collaborators
  ask candidate-universities in-radius friend-circle-radius [
    if not member? self myself-current-collaborators [
      if (desire-to-collaborate?) [ 
        if (confirm-to-collaborate?) [
          set myself-current-collaborators (turtle-set myself-current-collaborators self)  ;; save university to current partner to list
          set current-collaborators (turtle-set current-collaborators myself)   ;; save firm to current partner list          
        ]
      ]
    ]
  ]
  
  set current-collaborators myself-current-collaborators ;; save agentset back
  
  
  ask current-collaborators [
    let partner self
    let link-color (list (random 256) (random 256) (random 256))
    ask myself [ create-partner-to partner [ set color link-color ] ] ;; create link
  ]
  
end



;; firm and university procedure (only to firm)
to request_for_development_collaboration [candidate-frims]
  let myself-current-collaborators current-collaborators
  ask candidate-frims in-radius friend-circle-radius [
    if not member? self myself-current-collaborators [
      if (desire-to-collaborate?) [ 
        if (confirm-to-collaborate?) [
          set myself-current-collaborators (turtle-set myself-current-collaborators self)  ;; save university to current partner to list
          set current-collaborators (turtle-set current-collaborators myself)   ;; save firm to current partner list          
        ]
      ]
    ]
  ]
  
  set current-collaborators myself-current-collaborators ;; save agentset back
  
  ask current-collaborators [
    let partner self
    let link-color (list (random 256) (random 256) (random 256))
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
        let score compare_technical_domain ([technical-domain] of current-source) ([technical-domain] of current-target)
        if score >= (matchingThreshold / 100) [  ;; collaborate
          set source-current-collaborators (turtle-set source-current-collaborators current-target)  ;; save the collaborator to current-collaborators list
          set target-current-collaborators (turtle-set target-current-collaborators current-source)  ;; save the collaborator to current-collaborators list
          
          ;; create link through intermediary
          let link-color (list (random 256) (random 256) (random 256))
          
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
to record-attribute
  file-open "output/angent_count_and_attribute.txt"
  file-print(word "================tick: " ticks " ================")
  file-print(word "total agent: " count turtles)
  file-print(word "count firm: " count firms)
  file-print(word "count university: " count universities)
  file-print(word "count TT: " count TTs)
  
  file-print(word "############## Firm Attribute ############")
  let number 1
  ask firms [
    let prefix (word "[firm" number "] ")
    file-print(word prefix "capital: " capital)
    file-print(word prefix "track-record: " track-record)
    file-print(word prefix "staff-number: " staff-number)
    file-print(word prefix "absorptive-capacity: " absorptive-capacity)
    file-print(word prefix "number-of-patent: " number-of-patent)
    file-print(word prefix "number-of-product-in-pipeline: " number-of-product-in-pipeline) 
    file-print(word prefix "technical-domain: " technical-domain)
    file-print ""
    set number number + 1     
  ]

  
  file-print(word "############## University Attribute ##############")  
  set number 1
  ask universities [
    let prefix (word "[university" number "] ")
    file-print(word prefix "capital: " capital)
    file-print(word prefix "track-record: " track-record)
    file-print(word prefix "staff-number: " staff-number)
    file-print(word prefix "number-of-patent: " number-of-patent)
    file-print(word prefix "technical-domain: " technical-domain)
    file-print ""
    set number number + 1     
  ]
  
  file-print(word "##############TT Attribute ##############")
  set number 1
  ask TTs [
    let prefix (word "[TT" number "] ")
    file-print(word prefix "capital: " capital)
    file-print(word prefix "track-record: " track-record)
    file-print(word prefix "staff-number: " staff-number)
    file-print(word prefix "number-of-patent: " number-of-patent)
    file-print(word prefix "number-of-product-in-pipeline: " number-of-product-in-pipeline) 
    file-print(word prefix "technical-domain: " technical-domain)
    file-print ""
    set number number + 1     
  ]
  
  file-close
end


;; report whether objective partner want to collaborate with him or not
to-report desire-to-collaborate?
  let x random 100
  ifelse x < (probability-of-accepting-collaboration) [report true] [report false]
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
to-report compare_technical_domain [list1 list2]
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
  report score / denominator
end
  
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
143
142
initial-firm-capital
initial-firm-capital
0
100
53
1
1
NIL
HORIZONTAL

SLIDER
5
56
97
89
nFirms
nFirms
0
100
13
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
308
89
nUniversities
nUniversities
0
100
9
1
1
NIL
HORIZONTAL

SLIDER
158
109
332
142
initial-university-capital
initial-university-capital
0
100
53
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
457
88
nTTs
nTTs
0
100
17
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
50
1
1
NIL
HORIZONTAL

SLIDER
4
171
145
204
big-firms-percent
big-firms-percent
0
100
11
1
1
NIL
HORIZONTAL

SLIDER
163
171
331
204
big-universities-percent
big-universities-percent
0
100
12
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
31
1
1
NIL
HORIZONTAL

SWITCH
1041
303
1181
336
display-firms
display-firms
0
1
-1000

SWITCH
1042
350
1221
383
display-universities
display-universities
0
1
-1000

SWITCH
1043
398
1174
431
display-TTs
display-TTs
0
1
-1000

BUTTON
1063
458
1137
491
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

BUTTON
1281
61
1344
94
NIL
test
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
77
267
392
300
baseFriendCircleRadius
baseFriendCircleRadius
0
sqrt (max-pxcor * max-pxcor + max-pycor * max-pycor)
8
1
1
NIL
HORIZONTAL

BUTTON
1149
103
1212
136
NIL
go2
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
89
330
396
363
probability-of-accepting-collaboration
probability-of-accepting-collaboration
0
100
4
1
1
%
HORIZONTAL

SLIDER
88
381
383
414
probability-of-confirm-collaboration
probability-of-confirm-collaboration
0
100
4
1
1
%
HORIZONTAL

SLIDER
87
444
392
477
probability-of-terminate-collaboration
probability-of-terminate-collaboration
0
100
2
1
1
%
HORIZONTAL

CHOOSER
91
502
303
547
potentialReputaionThreshold
potentialReputaionThreshold
"high" "medium" "low"
2

SLIDER
92
568
401
601
potentialResearchMaturityLevelThreshold
potentialResearchMaturityLevelThreshold
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
93
628
306
661
potentialCapitalThreshold
potentialCapitalThreshold
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
92
692
434
725
potentialNumberOfProductInPipelineThreshold
potentialNumberOfProductInPipelineThreshold
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
89
753
275
786
matchingThreshold
matchingThreshold
0
100
0
1
1
%
HORIZONTAL

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
