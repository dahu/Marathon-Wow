#!/usr/bin/newlisp
;;
;; Copyright (C) 2012 Barry Arthur
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is furnished to do
;; so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;
(set-locale "C")
(load (append (env "NEWLISPDIR") "/guiserver.lsp"))
(seed (time-of-day))

;; GUI

(gs:init)
(gs:set-trace true)

; Main Application Frame

(gs:frame 'Wow 100 100 800 600 "Marathon Wow!")
(gs:frame-closed 'Wow 'quit-action)
(gs:set-border-layout 'Wow 0 0)

; Main Split Pane across centre

(gs:split-pane 'MainPane "vertical" 1.0 1.0 10)

(gs:panel 'WordPanel 400 800)
(gs:key-event 'WordPanel 'key-action)
(gs:set-grid-layout 'WordPanel 10 2)

(define (between max_v min_v val) (and (<= max_v val) (>= min_v val)))

(define (key-action id type code modifiers)
  ;(println "id:" id " type:" type " key code:" code " modifiers:" modifiers)
  (when (and (= 0 Timer:paused)
             (= type "pressed")
             (!= code 16)
             (or (between "a" "t" (char code))
                 (between "A" "T" (char code))
             ))
    (if (= modifiers 0)
     (mark-right (char code))
     (mark-wrong (char code)))))

(define (mark-right label)
  (map (fn (l) (gs:set-foreground l 0.3 0.8 0.3)) (WordEngine:WordLabels label))
  (Score:Increase)
)

(define (mark-wrong label)
  (map (fn (l) (gs:set-foreground l 1.0 0.4 0.4)) (WordEngine:WordLabels label))
  (Score:Decrease)
)

(gs:panel 'ButtonPanel 400 800)
(gs:set-grid-layout 'ButtonPanel 4 2)

(gs:label  'ScoreTitleLabel "Score: ")
(gs:set-font 'ScoreTitleLabel "Arial Bold" 22 "plain")

(gs:label  'ScoreLabel "0")
(gs:set-font 'ScoreLabel "Arial Black" 22 "plain")

(gs:label  'TimerTitleLabel "Time: ")
(gs:set-font 'TimerTitleLabel "Arial Bold" 22 "plain")

(gs:label  'TimerLabel "120")
(gs:set-font 'TimerLabel "Arial Black" 22 "plain")

(gs:button 'RestartButton 'restart-action "Restart")
(gs:set-font 'RestartButton "Arial Bold" 22 "plain")

(gs:button 'PauseButton 'pause-action "Play")
(gs:set-font 'PauseButton "Arial Bold" 22 "plain")

(define (pause-action)
  (println "pause")
  (Timer:PauseToggle)
)

(gs:button 'QuitButton 'quit-action "Quit")
(gs:set-font 'QuitButton "Arial Bold" 22 "plain")

(define (quit-action) (exit))

(gs:panel 'WordSizeSliderPanel)
(gs:set-grid-layout 'WordSizeSliderPanel 2 1)
(gs:label 'WordSizeSliderLabel "Font Size")
(gs:set-font 'WordSizeSliderLabel "Arial Bold" 22 "plain")
(gs:slider 'WordSizeSlider 'change-word-size "horizontal" 32 72 32)
(gs:add-to 'WordSizeSliderPanel 'WordSizeSliderLabel 'WordSizeSlider)

(define (change-word-size slider size)
  (WordEngine:SetWordSize size))

(gs:add-to 'ButtonPanel 'ScoreTitleLabel 'ScoreLabel 'TimerTitleLabel 'TimerLabel 'RestartButton 'PauseButton 'QuitButton 'WordSizeSliderPanel)
(gs:add-to 'MainPane 'WordPanel 'ButtonPanel)

(gs:add-to 'Wow 'MainPane "center")

; Title Banner at top

(gs:panel 'TitleBanner)
(gs:label 'Title "Marathon Wow!")
(gs:set-font 'Title "Times New Roman" 56 "bold")
(gs:set-foreground 'Title 0.5 0.4 1.0)
(gs:add-to 'TitleBanner 'Title)
(gs:add-to 'Wow 'TitleBanner "north")

; Game Over Dialog

(gs:dialog 'GameOverDialog 'Wow "Game Over" 600 400)
(gs:set-border-layout 'GameOverDialog)
(gs:label 'GameOver "Game Over!")
(gs:set-font 'GameOver "Times New Roman" 96 "bold")
(gs:set-foreground 'GameOver 0.3 0.3 0.5)

(gs:label 'GameOverScore "")
(gs:set-font 'GameOverScore "Times New Roman" 96 "bold")
(gs:set-foreground 'GameOverScore 0.3 0.3 0.5)

(gs:button 'GameOverOkButton 'restart-action "Ok")
(gs:set-font 'GameOverOkButton "Times New Roman" 22 "bold")

(define (restart-action)
  (println "restart")
  (hide-game-over-dialog)
  (Timer:Restart)
)

(gs:add-to 'GameOverDialog 'GameOver "north")
(gs:add-to 'GameOverDialog 'GameOverScore "center")
(gs:add-to 'GameOverDialog 'GameOverOkButton "south")

(define (show-game-over-dialog)
  (gs:set-text 'GameOverScore (string Score:game-score " points"))
  (gs:set-visible 'GameOverDialog true))

(define (hide-game-over-dialog)
  (gs:set-visible 'GameOverDialog nil))

; Show GUI

(gs:set-visible 'Wow true)
(gs:layout 'Wow)

(define (play-game)
  (Timer:Restart)
  (while (gs:check-event 10000) ; check for 10 milli seconds
    (game-over))
)

(define (game-over)
  (if (= 0 Timer:counter)
    (begin
      (Timer:Stop)
      (show-game-over-dialog)
    )))

;; WordEngine

(setf WordEngine:Words (clean empty? (parse (read-file "./words.txt") {\n} 0)))
(setf WordEngine:WordSize 32)
(setf WordEngine:LabelFont "")
(setf WordEngine:WordFont "")   ; specifying a font seems to cause linux to not show chinese characters
                                ; untested on windows

(define (WordEngine:WordLabels handle)
  (list  (sym (string "Word_l_" handle) 'MAIN) (sym (string "Word_w_" handle) 'MAIN)))

(define (WordEngine:WordLabelsPanel handle)
  (sym (string "Panel_" handle) 'MAIN))

(define (WordEngine:SpreadWords , label handle)
  ; remove any existing word labels
  (setf handle "A")
  (dotimes (n 20)
    (setf panel (WordEngine:WordLabelsPanel handle))
    (gs:remove-from 'WordPanel panel)
    (setf handle (char (inc (char handle))))
  )
  ; create new labels
  (setf handle "A")
  (dolist (w (randomize WordEngine:Words) (= $idx 20))
    (setf panel (WordEngine:WordLabelsPanel handle))
    (map set '(label_l label_w) (WordEngine:WordLabels handle))
    (gs:panel panel)
    (gs:set-flow-layout panel "left")
    (gs:label label_l handle "left" 100 100)
    (gs:set-foreground label_l 0.1 0.1 1.0)
    (gs:label label_w w)
    (gs:add-to panel label_l label_w)
    (gs:add-to 'WordPanel panel)
    (setf handle (char (inc (char handle))))
  )
  ; resize labels
  (WordEngine:SetWordSize WordEngine:WordSize)
  (gs:layout 'WordPanel)
)

(define (WordEngine:SetWordSize size , handle)
  (setf WordEngine:WordSize size)
  (setf handle "A")
  (dotimes (n 20)
    (map set '(label_l label_w) (WordEngine:WordLabels handle))
    (gs:set-font label_l WordEngine:LabelFont size "plain")
    (gs:set-font label_w WordEngine:WordFont size "plain")
    (setf handle (char (inc (char handle))))))

;; Score

(setf Score:game-score 0)
(define (Score:Reset) (setf Score:game-score 0) (Score:UpdateScoreLabel Score:game-score))
(define (Score:Increase) (Score:UpdateScoreLabel (inc Score:game-score 10)))
(define (Score:Decrease) (Score:UpdateScoreLabel (dec Score:game-score 10)))
(define (Score:UpdateScoreLabel label) (gs:set-text 'ScoreLabel (string label)))

;; Timer

(setf Timer:paused 0)
(setf Timer:initial 120)
(setf Timer:counter Timer:initial)
(define (Timer:UpdateTimerLabel label) (gs:set-text 'TimerLabel label))
(define (Timer:Start)
  (Timer:UpdateTimerLabel (string (dec Timer:counter)))
  (gs:request-focus 'WordPanel)
  (timer 'Timer:Start 1.0)
)
(define (Timer:Stop) (timer (fn ()) 0))
(define (Timer:Restart)
  (setf Timer:counter Timer:initial)
  (Score:Reset)
  (WordEngine:SpreadWords)
  (Timer:UpdateTimerLabel (string Timer:counter))
  (Timer:PauseOn)
)
(define (Timer:PauseOn)
  (gs:set-text 'PauseButton "Play")
  (setf Timer:paused 1)
  (Timer:Stop))

(define (Timer:PauseOff)
  (gs:set-text 'PauseButton "Pause")
  (setf Timer:paused 0)
  (Timer:Start))

(define (Timer:PauseToggle)
  (if (= 1 Timer:paused)
    (Timer:PauseOff)
    (Timer:PauseOn))
)

(play-game)
