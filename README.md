shout_ml
===
Another blocker, but this one uses machine learning to classify yells into one of eight classes:  Content, RMT, Merc, JP Merc, Chat, Selling (non-Merc), Buying (non-Merc), and Unknown.



Commands:
```
//sml h                       -  help.
//sml t (class) (threshold)   -  set the minimum probability of belonging to a class to block.
//sml a (allow word)          -  allow yells with key phrases to pass through without scoring.
//sml r (allow word index)    -  remove an allow word.
//sml d                       -  debug (show classification probabilities).
//sml show                    -  show content window.
//sml hide                    -  hide content window.
//sml ct                      -  set max time to keep a yell on the content window after last shout.
```
