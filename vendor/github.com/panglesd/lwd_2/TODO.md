- Document implementation
- Switch to labelled interface
- Make "window manager" a core Nottui concept:
  - applications start by creating a window manager
  - main loop runs a window manager and not a ui Lwd.t
  - main loop quit when there is no window scheduled
- Benchmark "compact" trace representation:
  It should consume a bit less memory (that should be observable in misc
  example with a million edit fields) and should not affect runtime
  performance... However it seems to do so (in misc and stress),
  especially in bytecode, maybe because of the additional recursive functions.
- Add a standard mainloop / update scheduler to Tyxml-lwd:
  - it should take into account different roots 
    (multiple sub-trees of the DOM that are maintained by lwd)
  - it should support "unstable" documents (those that need more than one
    update cycle):
    - provide different levels of logging for profiling unstable parts?
    - maybe split update cycles in different chunks, so that we can still
      produce a frame within time budget when a fixpoint cannot be reached
