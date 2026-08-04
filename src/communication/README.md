This communication type is used:

Not between the "server's client" abstraction and the previewer
abstraction. Those code live on the same iframe, and communicate through
function call in one direction, and callback calling in the other.
<!-- - In the communication between the server's client -->
<!--   (`src/server/client/client.ml` through calls to the -->
<!--   `src/engine/previewer/previewer.ml` library) and the previewer -->
<!--   (`src/engine/previewer/previewer.ml`). It is not really back and forth: -->
<!--   - The server's client receives a "Control" event (not a communication value), -->
<!--     it forwards it (as a communication value) to the previewer. -->
<!--   - The previewer receives a "save drawing" communication value from the -->
<!--     scheduler, it calls a callback from the server's client. -->

- In the communication between the previewer
  (`src/engine/previewer/previewer.ml`) and the speaker note scheduler
  (`src/engine/scheduler/scheduler.ml`). Back and forth:
  - The previewer may send "`go next/previous`", "`open_speaker_note`",
    "`can_save`".
  - The previewer receives all communication values and handles "State",
    "`open/close_recording_panel`", "`open/close_speaker_notes`", "`Ready`",
    "`Save_drawing`"

- In the communication between the speaker note scheduler
  (`src/engine/scheduler/scheduler.ml`) and the presentation frame
  (`src/engine/runtime/controller.ml`). Back and forth:
  - controller receives State, Next, Previous, `Drawing _`, `send_all_strokes`, `can_save`.
  - It sends "Ready", State, Draw, `send_all_strokes`, `save_drawing`,
    `open_speaker_notes`, `send_speaker_note`, `opened/closed_recording_panel`

Note that the communication between the server and server's client is done
through `src/server/proto/proto.ml`.
