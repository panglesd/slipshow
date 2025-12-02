  $ slipshow compile --verbosity=debug debug.md
  slipshow: [DEBUG] Stage 1:
                     (div {enter-at-unpause="~duration:0"; slip}
                       (blocks
                         (div {id="slides"; children:slide; style="display:flex"}
                           (blocks
                             (div
                               (blocks (blank line) (paragraph) (blank line)))
                             (div {id="d"}
                               (blocks (blank line) (paragraph) (blank line)))))
                         (div (blocks (blank line) (paragraph) (blank line)))))
                    
  slipshow: [DEBUG] Stage 2:
                    (div {enter-at-unpause="~duration:0"; slip}
                      (blocks
                        (div {id="slides"; children:slide; style="display:flex"}
                          (blocks
                            (div {slide}
                              (blocks (blank line) (paragraph) (blank line)))
                            (div {id="d"; slide}
                              (blocks (blank line) (paragraph) (blank line)))))
                        (div (blocks (blank line) (paragraph) (blank line)))))
                    
  slipshow: [DEBUG] Stage 3:
                    (slip {slip; enter-at-unpause="~duration:0"}
                      (blocks
                        (div {id="slides"; style="display:flex"; children:slide}
                          (blocks
                            (slide {slide; enter-at-unpause}
                              (div
                                (blocks (blank line) (paragraph) (blank line))))
                            (slide {id="d"; slide; enter-at-unpause}
                              (div
                                (blocks (blank line) (paragraph) (blank line))))))
                        (div (blocks (blank line) (paragraph) (blank line)))))
                    

$ cp carousel.html /tmp/
