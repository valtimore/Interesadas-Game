;; Variables globales definidas

globals [

  random-variable      ;; Generar valores aleatorios
  class-info           ;; Información sobre la clase
  education-info       ;; Información sobre el nivel de educación
  services-info        ;; Información sobre los servicios
  income-info          ;; Información sobre los ingresos

]

patches-own [

  is-living?                      ;; Muestra si la celda está ocupada
  is-high-class?                  ;; Muestra si la celda es 'clase alta'
  is-middle-class?                ;; Muestra si la celda es 'clase media'
  is-low-class?                   ;; Muestra si la celda es 'clase baja'
  is-hospital?                    ;; Muestra si la celda es un hospital
  is-university?                  ;; Muestra si la celda es una universidad
  is-store?                       ;; Muestra si la celda es una tienda

  cell-income                     ;; Ingresos de la celda
  cell-services                   ;; Servicios de la celda
  cell-education                  ;; Nivel educativo de la celda
  IPM-value                ;; Valor usado para determinar la clase social

  high-class-neighbors            ;; Vecinos de 'clase alta'
  middle-class-neighbors          ;; Vecinos de 'clase media'
  low-class-neighbors             ;; Vecinos de 'clase baja'
  university-neighbors            ;; Vecinos que son universidades
  hospital-neighbors              ;; Vecinos que son hospitales
  store-neighbors                 ;; Vecinos que son tiendas
  park-neighbors                  ;; Vecinos que son parques
  living-neighbors                ;; Vecinos que están vivos

]

;; Inicializa el mundo vacío

to setup-blank
  clear-all
  ask patches [ initialize-cell ]
  reset-ticks
end

;; Inicializa el mundo con valores aleatorios

to setup-random
  clear-all

  set class-info ""
  set income-info ""
  set services-info ""
  set education-info ""
  set random-variable random 10

;; Establecer cuántas celdas de cada tipo aparecerán en el mundo, a mayor número, menos aparecerán

  ask patches [
    ifelse random-float 200000.0 < initial-density
        [ assign-hospital ]
        [ initialize-cell ]
  ]

  ask patches with [not is-hospital?] [
    ifelse random-float 200000.0 < initial-density
        [ assign-university ]
        [ initialize-cell ]
  ]

  ask patches with [not is-hospital? and not is-university?] [
    ifelse random-float 10000.0 < initial-density
        [ assign-store ]
        [ initialize-cell ]
  ]

  ask patches with [not is-hospital? and not is-university? and not is-store?] [
    let probability random-float 100.0

    ifelse probability < 2.8      ;; Probabilidad de que una celda sea de clase alta
        [ assign-high-class ]
        [ ifelse probability < 70     ;; Probabilidad de que una celda sea de clase media y baja
            [ assign-middle-class ]
            [ assign-low-class ]
    ]

  ]

  reset-ticks

end

;; Restablece el estado de una celda

to initialize-cell

  set is-living? true
  set is-high-class? false
  set is-middle-class? false
  set is-low-class? false
  set is-university? false
  set is-hospital? false
  set is-store? false

end


;; Definición de las clases sociales

to assign-high-class
  initialize-cell
  set is-high-class? true
  set cell-income 3200000
  set cell-education 3
  set cell-services 3
  calculateIPMvalue
  set pcolor green
end

to assign-middle-class
  initialize-cell
  set is-middle-class? true
  set cell-income 2100000
  set cell-education 2
  set cell-services 2
  calculateIPMvalue
  set pcolor yellow
end

to assign-low-class
  initialize-cell
  set is-low-class? true
  set cell-income 700000
  set cell-education 1
  set cell-services 1
  calculateIPMvalue
  set pcolor red
end

;; Definición de celdas de entidades

to assign-hospital
  initialize-cell
  set is-hospital? true
  set IPM-value -15
  set pcolor black
end

to assign-university
  initialize-cell
  set is-university? true
  set IPM-value -35
  set pcolor white
end

to assign-store
  initialize-cell
  set is-store? true
  set IPM-value -25
  set pcolor violet
end

;; Definición de celdas desocupadas

to initialize-dead-cell
  initialize-cell
  set is-living? false
  set pcolor black
end

;; Función para la selección de celdas en la simulación

to update-info-label
  if mouse-inside? [
    let patch-under-mouse patch mouse-xcor mouse-ycor

    set class-info (word "Clase: "
      (ifelse-value [is-low-class?] of patch-under-mouse [ "Baja" ]
        [is-middle-class?] of patch-under-mouse [ "Media" ]
        [is-high-class?] of patch-under-mouse [ "Alta" ]
        [is-hospital?] of patch-under-mouse [ "Hospital" ]
        [is-university?] of patch-under-mouse [ "Universidad" ]
        [is-store?] of patch-under-mouse [ "Tiendas" ]
        [ "Ninguna" ]))

    set income-info     (word "Ingresos: " [cell-income] of patch-under-mouse)
    set education-info  (word "Educacion: " [cell-education] of patch-under-mouse)
    set services-info   (word "Servicios: " [cell-services] of patch-under-mouse)
  ]
end

;; Establece el valor de transición: se divide el valor de los ingresos para eliminar los ceros (ya que se manejan altos valores de ingresos) y se les suman los servicios y educación

to calculateIPMvalue

  set IPM-value ((cell-income / 100000) + cell-services + cell-education )

end

;; Actualiza la información de los vecinos de una celda

to update-neighbors-info
  ask patches [

    set high-class-neighbors count neighbors with [is-high-class?]
    set middle-class-neighbors count neighbors with [is-middle-class?]
    set low-class-neighbors count neighbors with [is-low-class?]
    set hospital-neighbors count neighbors with [is-hospital?]
    set university-neighbors count neighbors with [is-university?]
    set store-neighbors count neighbors with [is-store?]

  ]

  end

to set-cell-values
  set cell-income cell-income
  set cell-education cell-education
  set cell-services cell-services
  calculateIPMvalue
end

;; Reglas de transición de clases

to transition-classes ;; Política 'Normalidad': Agrupación de la riqueza, y establecimiento de zonas críticas

  ask patches [ ;; Para la clase Baja
    if (is-low-class?)
    [
      ifelse (hospital-neighbors >= 1 or university-neighbors >= 1 or store-neighbors >= 1) ;; Le benefician las entidades, debido a los arrendos

      [
          set cell-income cell-income + 1400000
          set cell-services cell-services + 2
          set cell-education cell-education + 1
          calculateIPMvalue
        ]

      [ ifelse (middle-class-neighbors <= 4 or low-class-neighbors >= 5) ;; Sigue igual si la mayoría de sus vecinos son de su misma clase

        [ set-cell-values ]

        [ ifelse (high-class-neighbors >= 5) ;; Si su barrio tiene clase alta, se beneficia

          [
            set cell-income cell-income + 2500000
            set cell-services cell-services + 2
            set cell-education cell-education + 1
            calculateIPMvalue
          ]

          [ if (middle-class-neighbors >= 5 or low-class-neighbors <= 4 ) ;; Se beneficia con vecinos de clase media

            [
              set cell-income cell-income + 1400000
              set cell-services cell-services + 1
              set cell-education cell-education + 1
              calculateIPMvalue
            ]
          ]
        ]
      ]
    ]
  ]

  ask patches [ ;; Para la clase Media
    if (is-middle-class?)
    [

      ifelse  (hospital-neighbors >= 1 or university-neighbors >= 1 or store-neighbors >= 2) ;; Subirá de estrato y nivel de educación con entidades cerca

      [
        set cell-income cell-income + 800000
        set cell-services cell-services + 1.5
        set cell-education cell-education + 1
        calculateIPMvalue
      ]

      [ ifelse  (middle-class-neighbors <= 3 and high-class-neighbors >= 2) ;; Se beneficia con vecinos de clase alta

        [
          set cell-income cell-income + 1400000
          set cell-services cell-services + 1
          set cell-education cell-education + 1
          calculateIPMvalue
        ]

        [ ifelse (high-class-neighbors > 3)

          [
            set cell-income cell-income + 1400000
            set cell-services cell-services + 1
            set cell-education cell-education + 1
            calculateIPMvalue
          ]

          [ ifelse (middle-class-neighbors >= 5) ;; Seguirá igual si su entorno es clase media

            [ set-cell-values ]

            [ ifelse (low-class-neighbors >= 3 and middle-class-neighbors <= 3) ;; Se verá menos perjudicada si tiene menos vecinos clase baja y algunos clase media

              [
                set cell-income cell-income - 800000
                calculateIPMvalue
              ]

              [ if (low-class-neighbors >= 4) ;; Se verá perjudicada si tiene muchos vecinos clase baja

                [
                  set cell-income cell-income - 1600000
                  set cell-services cell-services - 1
                  set cell-education cell-education - 1
                  calculateIPMvalue
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

  ask patches [   ;; Para la clase Alta
    if (is-high-class?)
    [

      ifelse ((high-class-neighbors >= 5 or middle-class-neighbors >= 4) and is-high-class?) ;; Se beneficia si su entorno es clase alta

      [
        set cell-income cell-income + 2500000
        calculateIPMvalue
      ]

      [ ifelse (hospital-neighbors >= 1 or university-neighbors >= 1)

        [
          set cell-income cell-income + 2500000
          calculateIPMvalue
        ]

        [ ifelse (middle-class-neighbors >= 4 or low-class-neighbors >= 5) ;; Se perjudica con vecinos de clase baja

          [
            set cell-income cell-income - 1100000
            set cell-services cell-services - 1
            set cell-education cell-education - 1
            calculateIPMvalue
          ]

          [ ifelse store-neighbors >= 2

            [
              set cell-services cell-services - 2
              calculateIPMvalue
            ]

            [ if (low-class-neighbors <= 4) ;; Su entorno tiene que ser clase alta para no perder ingresos

              [
                set cell-income cell-income - 2500000
                set cell-services cell-services - 2
                set cell-education cell-education - 2
                calculateIPMvalue
              ]
            ]
          ]
        ]
      ]
    ]
  ]

end


to transition-classes-taxes ;; Política 'Equidad': Distribución de la riqueza por medio de impuestos

  ask patches [ ;; Para la clase Baja
    if (is-low-class?)
    [
      ifelse (low-class-neighbors >= 7 or middle-class-neighbors <= 2) ;; Sigue igual si la mayoría de sus vecinos son de su misma clase, ya que nadie le puede dar dinero

      [ set-cell-values ]

      [ ifelse  (high-class-neighbors >= 1) ;; Cada clase alta le proveerá de ingresos

        [
          set cell-income cell-income + 1000000
          calculateIPMvalue
        ]

        [ ifelse (hospital-neighbors >= 1 or university-neighbors >= 1 or store-neighbors >= 1) ;; Le benefician las entidades, debido a los arrendos

          [
            set cell-income cell-income + 550000
            set cell-services cell-services + 1.5
            set cell-education cell-education + 1
            calculateIPMvalue
          ]

          [ ifelse (middle-class-neighbors >= 5 or low-class-neighbors <= 3 ) ;; Recibirá ingresos si tiene vecinos de clase media

            [
              set cell-income cell-income + 900000
              calculateIPMvalue
            ]

            [ if (middle-class-neighbors >= 4 and low-class-neighbors <= 3 ) ;;

              [
                set cell-income cell-income + 700000
                calculateIPMvalue
              ]
            ]
          ]
        ]
      ]
    ]
  ]

  ask patches [   ;; Para la clase Media
    if (is-middle-class?)
    [
      ifelse  (hospital-neighbors >= 1 or university-neighbors >= 1 or store-neighbors >= 1) ;; Subirá de estrato y nivel de educación con entidades cerca

      [
        set cell-services cell-services + 1.5
        set cell-education cell-education + 1
        calculateIPMvalue
      ]

      [ ifelse (low-class-neighbors >= 5) ;; Se verá perjudicado, ya que debe pagar impuestos hacía la clase baja

        [
          set cell-income cell-income - 600000
          set cell-services cell-services - 1
          set cell-education cell-education - 1
          calculateIPMvalue
        ]

        [ ifelse (middle-class-neighbors <= 3 and high-class-neighbors >= 1) ;; También recibe ingresos por parte de la clase alta

          [
            set cell-income cell-income + 1200000
            set cell-services cell-services + 1
            calculateIPMvalue

          ]

          [ ifelse (middle-class-neighbors < 5 )

            [
              set cell-income cell-income + 1200000
              calculateIPMvalue
            ]

            [ if (middle-class-neighbors >= 5) ;; Seguirá igual si su entorno es clase media

              [ set-cell-values  ]
            ]
          ]
        ]
      ]
    ]
  ]

  ask patches [   ;; Para la clase Alta
    if (is-high-class?)
    [
      ifelse (middle-class-neighbors >= 4 or low-class-neighbors >= 6) ;; Se perjudica con vecinos de clase baja y media, debe pagar

      [
        set cell-income cell-income - 1100000
        calculateIPMvalue
      ]

      [ ifelse (high-class-neighbors >= 4 or middle-class-neighbors >= 5) ;; Si su entorno es mayormente clase alta, no paga impuestos

        [
          set-cell-values
        ]

        [ ifelse (store-neighbors >= 2)  ;; Si tiene tiendas cerca se ve perjudicado

          [
            set cell-services cell-services - 2
            calculateIPMvalue
          ]

          [ if (low-class-neighbors <= 4)  ;; Su entorno tiene que ser clase alta para no perder ingresos

            [
              set cell-income cell-income - 1000000
              calculateIPMvalue
            ]
          ]
        ]
      ]
    ]
  ]

end


to transition-classes-capitalism ;; Política 'Capitalismo Salvaje': Las riquezas se concentran únicamente en las clases altas

  ask patches [ ;; Para la clase Baja
    if (is-low-class?)
    [
      ifelse (low-class-neighbors >= 5 or middle-class-neighbors <= 3) ;; Sigue igual si la mayoría de sus vecinos son de su misma clase

      [ set-cell-values ]

      [ ifelse (high-class-neighbors >= 1) ;; Se perjudica con vecinos clase alta, establecen impuestos

        [
          set cell-income cell-income - 100000
          calculateIPMvalue
        ]

        [ if (middle-class-neighbors >= 4 or low-class-neighbors <= 3 ) ;; Puede ganar ingresos sin tener vecinos clase alta

          [
            set cell-income cell-income + 500000
            set cell-services cell-services + 1
            set cell-education cell-education + 1
            calculateIPMvalue
          ]
        ]
      ]
    ]
  ]

  ask patches [ ;; Para la clase Media
    if (is-middle-class?)
    [

      ifelse  (middle-class-neighbors >= 5) ;; Seguirá igual si su entorno es clase media

      [ set-cell-values ]

      [ ifelse  (middle-class-neighbors <= 5 and high-class-neighbors >= 1) ;; La clase alta cobrará impuestos

        [
          set cell-income cell-income - 900000
          calculateIPMvalue
        ]

        [ if (low-class-neighbors >= 4) ;; Se verá perjudicado si tiene muchos vecinos clase baja, hay caos y robos

          [
            set cell-income cell-income - 600000
            set cell-education cell-education - 1
            set cell-services cell-services - 1
            calculateIPMvalue
          ]
        ]
      ]
    ]
  ]

  ask patches [ ;; Para la clase Alta
    if (is-high-class?)
    [

      ifelse (high-class-neighbors >= 5 or middle-class-neighbors >= 4) ;; Se beneficia si su entorno es mayormente clase alta

      [
        set cell-income cell-income + 2500000
        set cell-services cell-services + 2
        set cell-education cell-education + 2
        calculateIPMvalue
      ]

      [ ifelse (middle-class-neighbors >= 4 or low-class-neighbors >= 5) ;; Gana impuestos de sus vecinos de clase inferior

        [
          set cell-income cell-income + 1100000
          calculateIPMvalue
        ]

        [ ifelse (store-neighbors >= 2)

          [
            set cell-services cell-services + 2
            calculateIPMvalue
          ]

          [ if (low-class-neighbors <= 4) ;; Gana impuestos de los vecinos clase baja

            [
              set cell-income cell-income + 1000000
              calculateIPMvalue
            ]
          ]
        ]
      ]
    ]
  ]

end


;; Para asignar las clases a las celdas

to assign-class
  ask patches [
    if IPM-value >= 30 [

      set is-low-class? false
      set is-middle-class? false
      set is-high-class? true
      set pcolor green

    ]

    if IPM-value >= 20 and IPM-value < 30 [

      set is-middle-class? true
      set is-low-class? false
      set is-high-class? false
      set pcolor yellow

    ]

    if IPM-value < 20 and IPM-value > 1 [

      set is-middle-class? false
      set is-low-class? true
      set is-high-class? false
      set pcolor red

    ]

    if IPM-value = 0 [
      initialize-cell
    ]

    ;; Valores inalcanzables para que las celulas no se transformen en entidades

    if IPM-value = -15 [
      assign-hospital
    ]
    if IPM-value = -25 [
      assign-store
    ]
    if IPM-value = -35 [
      assign-university
    ]
  ]

end


;; Para iniciar el modelo

to go

  assign-class
  update-neighbors-info

  ifelse(politica = "Normalidad")[transition-classes]
  [ifelse(politica = "Equidad")[transition-classes-taxes]
  [transition-classes-capitalism]]

  update-info-label
  tick

end

;; ------------------------- Aquí termina el código, empiezan los ajustes en la interfaz ----------------------------------------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
204
10
813
620
-1
-1
3.9801325
1
10
1
1
1
0
0
0
1
-75
75
-75
75
0
0
1
ticks
30.0

SLIDER
18
10
190
43
initial-density
initial-density
0
100
100.0
0.1
1
%
HORIZONTAL

BUTTON
106
48
190
81
Nacimiento
setup-random
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
18
48
100
81
Extinción
setup-blank
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
23
95
185
128
Iniciar
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

MONITOR
42
408
165
453
Clase
class-info
17
1
11

MONITOR
43
463
165
508
Informacion Ingresos
income-info
17
1
11

MONITOR
43
518
162
563
Informacion Servicios
services-info
17
1
11

MONITOR
43
573
163
618
Informacion Educacion
education-info
17
1
11

MONITOR
26
218
183
263
Total Clase Baja
count patches with\n[is-low-class? ]
17
1
11

MONITOR
27
277
182
322
Total Clase Media
count patches with\n[is-middle-class?]
17
1
11

MONITOR
26
335
181
380
Total Clase Alta
count patches with\n[is-high-class?]
17
1
11

CHOOSER
25
141
185
186
politica
politica
"Normalidad" "Equidad" "Capitalismo Salvaje"
2

TEXTBOX
50
193
200
211
Monitores de población\n
11
0.0
1

TEXTBOX
43
387
193
405
Información sobre la celula
11
0.0
1

@#$#@#$#@
## Segregación Económica en Colombia

Este modelo simula un entorno urbano donde las celdas representan diferentes clases sociales (alta, media, baja) y entidades (hospitales, universidades, tiendas). El modelo tiene como objetivo explorar cómo diferentes políticas económicas afectan la distribución de clases sociales y la dinámica de los ingresos, educación y servicios dentro de una ciudad.

## ¿Cómo funciona el modelo?

El modelo sigue estas reglas básicas:

1. **Inicialización**:
    - El mundo se inicializa con una distribución aleatoria de celdas de clases sociales y entidades.

    - Cada celda tiene propiedades como ingresos, nivel de educación y servicios.

2. **Transición de Clases**:
    - Las celdas pueden cambiar de clase social en función de sus vecinos y de la política económica seleccionada.

    - Las políticas disponibles son:

        - `Normalidad`: Agrupación de la riqueza y establecimiento de zonas críticas.
        - `Equidad`: Distribución de la riqueza por medio de impuestos.
        - `Capitalismo Salvaje`: Las riquezas se concentran únicamente en las clases altas.

    - Las celdas calculan su valor de transición en función de sus ingresos, servicios y educación, así como la influencia de los vecinos y entidades cercanas.

## Instrucciones de uso

1. **Configuración**:
    - `setup-blank`: Inicializa el mundo vacío.
    - `setup-random`: Inicializa el mundo con valores aleatorios de clases y entidades.

2. **Ejecutar el Modelo**:
    - `go`: Ejecuta el modelo aplicando la política seleccionada y actualizando el estado de las celdas y vecinos.

3. **Interfaz**:
    - `class-info`, `income-info`, `education-info`, `services-info`: Muestra información sobre la celda debajo del cursor.
    - `random-variable`: Variable aleatoria para diversas operaciones.

## A tener en cuenta

- Observe cómo las celdas cambian de clase social en función de sus vecinos.
- Preste atención a cómo la presencia de entidades (hospitales, universidades, tiendas) influye en los cambios de clase.
- Note la diferencia en la distribución de clases sociales al cambiar entre diferentes políticas económicas.

## Si quiere experimentar...

- Ajuste la `initial-density` para ver cómo la densidad inicial afecta la distribución final de las clases.
- Cambie entre las políticas `Normalidad`, `Equidad` y `Capitalismo Salvaje` para observar cómo cada política afecta el modelo.
- Intente modificar los valores de ingresos, educación y servicios para ver cómo estos cambios afectan la dinámica del modelo.

## Funciones para extender el modelo

- Añadir nuevas entidades como parques o centros comunitarios y ver cómo influyen en la dinámica de las clases sociales.
- Introducir nuevas políticas económicas o modificar las existentes para explorar diferentes escenarios.
- Incorporar factores adicionales como migración o fluctuaciones económicas.

## Features a destacar

- El modelo utiliza la función `neighbors` de NetLogo para calcular la influencia de los vecinos.
- Se usan colores para representar visualmente diferentes clases sociales y entidades.
- Las políticas económicas se implementan mediante reglas condicionales aplicadas en cada tick.

## Modelos similares

- El modelo de segregación de Schelling, disponible en la biblioteca de modelos de NetLogo, puede ser de interés ya que también trata la distribución espacial de clases sociales.
- Modelos urbanos en la biblioteca de modelos de NetLogo que exploran la dinámica de las ciudades.

## Créditos y referencias

Este modelo fue desarrollado por los estudiantes:

- Juan David Cataño Castillo 
- Valentina Londoño Dueñas
- Kevin Estiven Gil Salcedo
- Nicolás Prado León

Para más información, visite https://github.com/valtimore/Segregacion-Simulada.git
Agradecimientos a los desarrolladores de NetLogo y a los autores de modelos relacionados por la inspiración y las herramientas proporcionadas.
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
NetLogo 6.4.0
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
