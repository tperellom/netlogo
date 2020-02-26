extensions [nw]

globals [
  framing
  profile
  T1-basic-profile
  T2-basic-profile
]

breed [households household]

households-own [
  values
  supportive?
  trust
  internal?
  external?
]

undirected-link-breed [social-links social-link]
social-links-own [
  link-similarity
]

to setup
  let n-households 100
  clear-all
  nw:generate-preferential-attachment households social-links n-households 3 [
    set color blue
    set supportive? false
    set internal? false
    set external? false
  ]
  repeat 50
  [
    layout-spring households social-links 0.3 (world-width / (sqrt (n-households))) 1
  ]

  setup-framing
  setup-value-profiles n-households
  setup-trust
  setup-network
  reset-ticks
end

to setup-network
  ask social-links [
    set link-similarity (similarity-computation [values] of end1 [values] of end2)
   ]
end

to setup-framing
  set framing (list V1-F V2-F V3-F V4-F V5-F)
  set profile (list V1-P V2-P V3-P V4-P V5-P)
end

to setup-value-profiles [n]

  ; Assign value profiles to households:
  set T1-basic-profile (list V1-T1 V2-T1 V3-T1 V4-T1 V5-T1)
  set T2-basic-profile (list V1-T2 V2-T2 V3-T2 V4-T2 V5-T2)

  if (Type1 != 0) [
    ask n-of floor (Type1 * n / 100) households with [values = 0] [
      set values T1-basic-profile
      set shape "square"
    ]
  ]
  if (Type2 != 0) [
    ask n-of floor (Type2 * n / 100) households with [values = 0] [
      set values T2-basic-profile
      set shape "triangle"
    ]
  ]

  ; Check that all households have a value-profile. If any, set a random value-profile of those types whose proportion is not null:
  if any? households with [values = 0] [
    let aux-value-list (list Type1 Type2)
    let aux-value-list2 (list T1-basic-profile T2-basic-profile)
    (foreach aux-value-list aux-value-list2 [
      [?1 ?2] ->
      if (?1 = 0) [
        set aux-value-list2 remove ?2 aux-value-list2
      ]
    ])
    while [any? households with [values = 0]] [
      ask one-of households with [values = 0][
        set values one-of aux-value-list2
      ]
    ]
  ]

end

to external-influence
  if ticks mod appeal-period = 0 [
    ask households with [supportive? = false] [
      ; External appeal:
      let appeal (affinity-computation framing values)
      if random-float 1.0 < (appeal * trust) [
        set supportive? true
        set color red
        set external? true
      ]
    ]
  ]
end

to internal-influence
  ask households with [supportive? = false] [
    ;Internal appeal:
    let convinced-neighbors social-link-neighbors with [supportive? = true]
    if any? convinced-neighbors [
      let average-similarity mean ([link-similarity] of link-set [social-link-with myself] of convinced-neighbors)
      let convinced-ratio count convinced-neighbors / count social-link-neighbors
      if random-float 1.0 < convinced-ratio * average-similarity [
        set supportive? true
        set color red
        set internal? true
      ]

      ;foreach (sort convinced-neighbors) [
      ; ? ->
      ; let aff [link-similarity] of social-link-with ?
      ;if random-float 1.0 < aff [
      ;set supportive? true
      ;set color red
      ;set internal? true
      ;]
    ]

  ]
end

to go
  external-influence
  internal-influence

  do-plots
  tick
  if ticks >= 15 [stop]
end


to do-plots
  set-current-plot "Convinced"
  set-current-plot-pen "total" plot (count households with [supportive? = true] * 100 / count households)
  set-current-plot-pen "external" plot (count households with [supportive? = true and external? = true] * 100 / count households)
  set-current-plot-pen "internal" plot (count households with [supportive? = true and internal? = true] * 100 / count households)

  set-current-plot "Convinced-by-types"
  set-current-plot-pen "T1" plot (count households with [supportive? = true and values = T1-basic-profile] * 100 / count households)
  set-current-plot-pen "T2" plot (count households with [supportive? = true and values = T2-basic-profile] * 100 / count households)
  set-current-plot-pen "T1-int" set-plot-pen-mode 2 plot (count households with [supportive? = true and values = T1-basic-profile and internal? = true] * 100 / count households)
  set-current-plot-pen "T2-int" set-plot-pen-mode 2 plot (count households with [supportive? = true and values = T2-basic-profile and internal? = true] * 100 / count households)
end

to setup-trust
  ask households [
    set trust similarity-computation values profile
  ]
end


to-report similarity-computation [x1 x2]

  let num-held-values 0
  let coincidences 0

  (foreach x1 x2 [
    [my-value its-value] ->
    if my-value = 1 or its-value = 1 [
      set num-held-values (num-held-values + 1)
      if my-value = its-value [
        set coincidences (coincidences + 1)
      ]
    ]
    ])

  report (ifelse-value (num-held-values != 0) [ coincidences / num-held-values ] [0])

end

to-report affinity-computation [F V]
  let aux []
  let affinity 0

  (foreach F V [
    [framing-value held-value] ->
    if framing-value = 1 [
      ifelse held-value = 1 [
        set aux lput 1 aux
      ][
        set aux lput 0 aux
      ]
    ]
  ])

  if not empty? aux [
    set affinity mean aux
  ]

  report affinity
end
@#$#@#$#@
GRAPHICS-WINDOW
515
30
952
468
-1
-1
13.0
1
10
1
1
1
0
1
1
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

INPUTBOX
80
205
130
265
V1-F
1.0
1
0
Number

INPUTBOX
135
205
185
265
V2-F
0.0
1
0
Number

INPUTBOX
190
205
240
265
V3-F
0.0
1
0
Number

BUTTON
20
25
83
58
NIL
setup\n
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
20
62
83
95
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

PLOT
960
30
1254
228
Convinced
ticks
%
0.0
15.0
0.0
100.0
false
true
"" ""
PENS
"total" 1.0 0 -16777216 true "" ""
"external" 1.0 0 -3844592 true "" ""
"internal" 1.0 0 -14439633 true "" ""

INPUTBOX
245
205
295
265
V4-F
0.0
1
0
Number

INPUTBOX
300
205
350
265
V5-F
0.0
1
0
Number

INPUTBOX
15
320
65
380
Type1
50.0
1
0
Number

INPUTBOX
80
320
130
380
V1-T1
1.0
1
0
Number

INPUTBOX
135
320
185
380
V2-T1
0.0
1
0
Number

INPUTBOX
190
320
240
380
V3-T1
0.0
1
0
Number

INPUTBOX
245
320
295
380
V4-T1
0.0
1
0
Number

TEXTBOX
20
225
170
243
Framing:
11
0.0
1

INPUTBOX
300
320
350
380
V5-T1
0.0
1
0
Number

INPUTBOX
15
385
65
445
Type2
50.0
1
0
Number

INPUTBOX
80
385
130
445
V1-T2
0.0
1
0
Number

INPUTBOX
135
385
185
445
V2-T2
0.0
1
0
Number

INPUTBOX
190
385
240
445
V3-T2
1.0
1
0
Number

INPUTBOX
245
385
295
445
V4-T2
0.0
1
0
Number

INPUTBOX
300
385
350
445
V5-T2
1.0
1
0
Number

MONITOR
15
455
65
500
Total
Type1 + Type2
0
1
11

INPUTBOX
80
140
130
200
V1-P
1.0
1
0
Number

INPUTBOX
135
140
185
200
V2-P
1.0
1
0
Number

TEXTBOX
20
160
170
178
Profile:
11
0.0
1

INPUTBOX
190
140
240
200
V3-P
0.0
1
0
Number

INPUTBOX
245
140
295
200
V4-P
1.0
1
0
Number

INPUTBOX
300
140
350
200
V5-P
0.0
1
0
Number

MONITOR
370
150
485
195
Avg. trust (%)
(mean [trust] of households) * 100
1
1
11

SLIDER
105
25
277
58
appeal-period
appeal-period
1
15
15.0
1
1
NIL
HORIZONTAL

MONITOR
370
215
485
260
Avg.similarity (%)
100 * (mean [link-similarity] of social-links)
1
1
11

MONITOR
355
330
425
375
S(P,T1) (%)
similarity-computation T1-basic-profile profile * 100
1
1
11

MONITOR
355
395
425
440
S(P,T2) (%)
similarity-computation T2-basic-profile profile * 100
1
1
11

MONITOR
355
450
425
495
S(T1,T2) (%)
similarity-computation T1-basic-profile T2-basic-profile * 100
1
1
11

MONITOR
430
330
507
375
A(F,T1) (%)
affinity-computation framing T1-basic-profile * 100
1
1
11

MONITOR
430
395
507
440
A(F,T2) (%)
affinity-computation framing T2-basic-profile * 100
1
1
11

TEXTBOX
20
290
170
308
Households types:
11
0.0
1

PLOT
960
235
1255
435
Convinced-by-types
ticks
%
0.0
15.0
0.0
100.0
false
true
"" ""
PENS
"T1" 1.0 0 -10899396 true "" ""
"T2" 1.0 0 -13345367 true "" ""
"T1-int" 1.0 0 -15040220 true "" ""
"T2-int" 1.0 0 -14070903 true "" ""

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
NetLogo 6.0.4
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
1
@#$#@#$#@
