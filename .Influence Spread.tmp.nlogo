; should we add more breeds per medium? e.g., f2f-influencers, mixed-influencers, etc...
breed [influencers influencer]
; same with audiences?
breed [audiences audience]

globals [
  agree-total
  disagree-total
  agree-advantage      ; difference of agree-level and disagree-level (when agree-level >)
  agree-advantage-average
  disagree-advantage   ; when disagree-level >
  disagree-advantage-average
  both-messages
]

audiences-own [
  temp
  templinks
  stored
  agree-level
  disagree-level
  agree-threshold
  disagree-threshold
  nearby
]

influencers-own [
  temp ; for finding link
  templinks ;
  message ; 1 for Agree || 0 for Disagree
  medium  ; 2 for mixed || 1 for f2f   || 0 for social media
]

; start out as audience
; random first (slider var link-chance)
; barabasi on all
; start of influence

to setup
  clear-all
  ; shape used to differentiate agent type
  set-default-shape influencers "person"
  set-default-shape audiences "person"

  ask patches [set pcolor 29]

  ; Message | 0 -> cyan | 1 -> lime

  create-audiences starting_population[
    set size 2
    set color white
    setxy round(random-xcor) round(random-ycor)
    rt random 360
  ]

  ask one-of audiences [
    set temp -1

    ask audiences with [temp != -1] [
      set stored random 100
      output-print stored
      if stored < link_chance [
        create-links-with audiences with [temp = -1] [
          set color [0 0 255 25]
        ]
      ]
    ]

    set temp 0
  ]

  barabasi
  become-influencer

  ask audiences [
    let tempthreshold random 51 + 50

    set agree-threshold tempthreshold
    set disagree-threshold tempthreshold
  ]

  ask influencers with [message = 1] [
    ask my-links [
      set color [0 0 255 25]
    ]
  ]

  ask influencers with [message = 0] [
    ask my-links [
      set color [255 0 0 25]
    ]
  ]
  reset-ticks
end

to go
  if not any? audiences [stop]
  move-audience
  influence
  remove-audience

  ask audiences [
    set nearby count audiences in-radius 20
  ]

  wait 0.01

  tick
end

to barabasi
  ask audiences [
   set temp -1
   set templinks count my-links
    ask audiences with [temp != -1 and templinks > 0] [
      if random 100 <= (templinks)/(count links) * 100 [
        create-links-with audiences with [temp = -1] [
          set color [0 0 255 30]
        ]
     ]
   ]

   set temp 0
  ]
end
to set_turtle_color_position
  set size 2
  setxy round(random-xcor) round(random-ycor)
  rt random 360
end

to update-colors
  ask influencers with [message = 1] [
    ask my-links [
      set color [0 0 255 25]
    ]
  ]

  ask influencers with [message = 0] [
    ask my-links [
      set color [255 0 0 25]
    ]
  ]
end

to update-roles
  ask audiences [
    (ifelse agree-level >= 100 [
      ifelse coin-flip? = 0 [
        become-influencer
        set message 1
      ] [die]
    ]
      disagree-level >= 100 [
        ifelse coin-flip? = 0 [
          become-influencer
          set message 0
        ] [die]
      ]
    )
  ]
end

to become-influencer
  let currentCount 0
  let social 0
  (ifelse
    (unequal_social_media_influencers?)
    [ set social max-n-of (disagree_social_media_influencers + agree_social_media_influencers) audiences [count my-links] ]
    [ set social max-n-of (social_media_influencers * 2) audiences [count my-links] ]
  )
  ask social [
    set breed influencers
    set medium 0
    set label medium
    (ifelse (currentCount mod 2 = 0) [set message 0 set color red] [set message 1 set color blue])

    if (unequal_social_media_influencers?) [
      if (count influencers with [message = 0 and medium = 0] > disagree_social_media_influencers) [ set message 1 set color blue]
      if (count influencers with [message = 1 and medium = 0] > agree_social_media_influencers) [ set message 0 set color red]
    ]

    set currentCount currentCount + 1
  ]


  set currentCount 0
  let mixed 0
  (ifelse
    (unequal_mixed_influencers?)
    [ set mixed max-n-of (disagree_mixed_influencers + agree_mixed_influencers) audiences [count my-links] ]
    [ set mixed max-n-of (mixed_influencers * 2) audiences [count my-links] ]
  )
  ask mixed [
    set breed influencers
    set medium 2
    set label medium
    (ifelse (currentCount mod 2 = 0) [set message 0 set color red] [set message 1 set color blue])

    if (unequal_mixed_influencers?) [
      if (count influencers with [message = 0 and medium = 2] > disagree_mixed_influencers) [ set message 1 set color blue]
      if (count influencers with [message = 1 and medium = 2] > agree_mixed_influencers) [ set message 0 set color red]
    ]

    set currentCount currentCount + 1
  ]


  set currentCount 0
  let f2f_count 0
  (ifelse
    (unequal_f2f_influencers?)
    [ set f2f_count agree_f2f_influencers + disagree_f2f_influencers ]
    [ set f2f_count f2f_influencers * 2 ]
  )

  ask n-of (f2f_count) audiences [
    set breed influencers
    set medium 1
    set label medium
    (ifelse (currentCount mod 2 = 0) [set message 0 set color red] [set message 1 set color blue])

    if (unequal_f2f_influencers?) [
      if (count influencers with [message = 0 and medium = 1] > disagree_f2f_influencers) [ set message 1 set color blue]
      if (count influencers with [message = 1 and medium = 1] > agree_f2f_influencers) [ set message 0 set color red]
    ]
    set currentCount currentCount + 1
  ]


end

to move-audience
  ask audiences [
    rt random 360
    fd 1
  ]
end

to influence
  ; Broadcast every 7 ticks
  if (ticks mod 7 = 0) [
    ask influencers with [medium = 2 or medium = 0 and message = 1] [
      set templinks count my-links
      ask link-neighbors with [breed = audiences] [
        if (random 101 < influence_chance) [
          set agree-level agree-level + ((random 5 + 1) * templinks) ; Random val from 1-1 * Degree
        ]
      ]
    ]
  ]

  if (ticks mod 7 = 0) [
    ask influencers with [medium = 2 or medium = 0 and message = 0] [
      ask link-neighbors with [breed = audiences] [
        if (random 101 < influence_chance) [
          set disagree-level disagree-level + ((random 5 + 1) * templinks)
        ]
      ]
    ]
  ]


  ; F2F every 5 ticks

  let maxnearby audiences with-max [nearby]

  if (ticks mod 5 = 0) [
    ask influencers with [medium = 1 or medium = 2 and message = 1][
      face one-of maxnearby
      fd 1
      ask audiences in-radius 10 [
        if (random 101 < influence_chance) [
          set agree-level agree-level + ((random 5 + 1) * (templinks + 10)) ; 10 as bonus for being f2f
        ]
      ]
    ]
  ]

  ; Move F2F
  if (ticks mod 5 = 0) [
    ask influencers with [medium = 1 or medium = 2 and message = 0][
      face one-of maxnearby
      fd f2f_movement_distance
      ask audiences in-radius 10 [
        if (random 101 < influence_chance) [
          set disagree-level disagree-level + ((random 5 + 1) * (templinks + 10))
        ]
      ]
    ]
  ]

  ask audiences [
    ifelse ticks = 0 [set color white] [
    let level agree-level - disagree-level
      set color scale-color white level 0 510 ]

    ; Threshold

    if (agree-level >= agree-threshold) [
      set temp -1
      ask influencers with [message = 1] [
        if (random 101 < link_chance) [
          create-links-with audiences with [temp = -1] [
            set color [0 0 255 25]
          ]
        ]
      ]
      set temp 0
      set agree-threshold agree-threshold + 30 ; Milestone/Threshold increases by 30
    ]

    if (disagree-level >= disagree-threshold) [
      set temp -1
      ask influencers with [message = 0] [
        if (random 101 < link_chance) [
          create-links-with audiences with [temp = -1] [
            set color [0 0 255 25]
          ]
        ]
      ]
      set temp 0
      set disagree-threshold disagree-threshold + 30
    ]
  ]

  update-colors
end

to remove-audience
  ask audiences with [agree-level >= 500 or disagree-level >= 500] [
    (ifelse
      (disagree-level > agree-level) [
        set disagree-total disagree-total + 1
        set disagree-advantage disagree-advantage + (disagree-level - agree-level)
        set disagree-advantage-average (disagree-advantage / disagree-total)
      ]
      (agree-level > disagree-level) [
        set agree-total agree-total + 1
        set agree-advantage agree-advantage + (agree-level - disagree-level)
        set agree-advantage-average (agree-advantage / agree-total)
      ]
      [
        set both-messages both-messages + 1
     ])
    die
  ]
end

to-report coin-flip?
  report random 2 = 0
end
@#$#@#$#@
GRAPHICS-WINDOW
199
18
774
594
-1
-1
8.7231
1
20
1
1
1
0
0
0
1
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
72
12
135
45
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
118
53
181
86
NIL
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
19
95
192
128
social_media_influencers
social_media_influencers
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
1010
369
1087
414
Disagree f2f
count influencers with [message = 0 and medium = 1]
2
1
11

MONITOR
1042
312
1200
357
Disagree advantage average
disagree-advantage-average
17
1
11

MONITOR
784
314
928
359
Agree advantage average
agree-advantage-average
17
1
11

MONITOR
931
314
1039
359
Equally influenced
both-messages
17
1
11

SLIDER
20
129
192
162
f2f_influencers
f2f_influencers
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
20
165
192
198
mixed_influencers
mixed_influencers
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
250
192
283
f2f_movement_distance
f2f_movement_distance
1
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
15
296
187
329
Starting_Population
Starting_Population
0
1000
310.0
1
1
NIL
HORIZONTAL

SLIDER
20
205
192
238
link_chance
link_chance
0
100
32.0
1
1
NIL
HORIZONTAL

TEXTBOX
1073
64
1167
84
Disagree stats\n
12
14.0
0

TEXTBOX
846
63
936
83
Agree stats
12
94.0
1

MONITOR
805
93
950
138
Fully influenced (Agree)
agree-total
17
1
11

MONITOR
1035
92
1195
137
Fully influenced (Disagree)
disagree-total
17
1
11

BUTTON
22
54
98
88
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1021
151
1199
301
Disagree advantage average
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot disagree-advantage-average"

PLOT
787
152
949
302
Agree advantage average
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14454117 true "" "plot agree-advantage-average"

INPUTBOX
18
682
117
742
agree_social_media_influencers
100.0
1
0
Number

SWITCH
19
618
242
651
unequal_social_media_influencers?
unequal_social_media_influencers?
1
1
-1000

INPUTBOX
133
682
244
742
disagree_social_media_influencers
1.0
1
0
Number

TEXTBOX
23
664
128
682
# of Agree soc med
11
94.0
1

TEXTBOX
137
662
255
680
# of Disagree soc med
11
14.0
1

SWITCH
289
619
484
652
unequal_f2f_influencers?
unequal_f2f_influencers?
1
1
-1000

INPUTBOX
287
682
379
742
agree_f2f_influencers
1.0
1
0
Number

INPUTBOX
391
682
477
742
disagree_f2f_influencers
5.0
1
0
Number

TEXTBOX
292
661
376
679
# of Agree f2f
11
94.0
1

TEXTBOX
395
660
491
678
# of Disagree f2f
11
14.0
1

SWITCH
532
621
743
654
unequal_mixed_influencers?
unequal_mixed_influencers?
1
1
-1000

INPUTBOX
528
683
623
743
agree_mixed_influencers
100.0
1
0
Number

INPUTBOX
640
683
744
743
disagree_mixed_influencers
0.0
1
0
Number

TEXTBOX
533
662
621
680
# of Agree mixed
11
94.0
1

TEXTBOX
646
664
747
682
# of Disagree mixed
11
14.0
1

MONITOR
857
368
950
413
Agree soc med
count influencers with [message = 1 and medium = 0]
17
1
11

MONITOR
783
367
849
412
Agree f2f
count influencers with [message = 1 and medium = 1]
17
1
11

MONITOR
1090
367
1200
412
Disagree soc med
count influencers with [message = 0 and medium = 0]
17
1
11

MONITOR
809
422
891
467
Agree mixed
count influencers with [message = 1 and medium = 2]
17
1
11

MONITOR
1039
421
1136
466
Disagree mixed
count influencers with [message = 0 and medium = 2]
17
1
11

MONITOR
920
10
1063
55
Uninfluenced audiences
count audiences
17
1
11

SLIDER
17
341
189
374
influence_chance
influence_chance
0
100
50.0
1
1
NIL
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
NetLogo 6.3.0
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
