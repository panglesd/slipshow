==========================
Record and replay drawings
==========================

Slipshow has an experimental feature that lets you record a drawing, and replay it during your presentation.

This lets you hand-draw a diagram, a graph, or provide recorded sketching during an explanation, freeing you from the problems associated with having to draw it live.

An example of presentation using such feature can be found `here <https://choum.net/panglesd/hb.html>`_ (press :kbd:`right` to start the animation/go to the next one).

.. NOTE::
    If you're using recorded drawings, do not hesitate to let me know how it went — I want to make it better!

Creating a new drawing
======================

Slipshow's drawing are "anchored" in the text flow of your presentation. This
allows them to be moved as you add text before, or if you move some parts, the
drawing included, in a subslip.

So, to create a new drawing, simply add the following at the place in the text flow where you want it to be anchored:

.. code-block:: markdown

   Some text before...

   ![Recording name](file-name.draw)

   Some text after...

The ``.draw`` extension is mandatory for slipshow to recognize it as a
drawing. However, it is not necessary to create the file in advance. We will be
able to save it to the given location through the preview server, after having
recorded the drawing.


Recording a drawing
===================

Now that you have the anchor point, to start recording a drawing, open the
presentation through a preview server.

In the upper left, amongst the drawing tools, you'll find a "Manage my recording" button. Click it, or use the shortcut :kbd:`R`.

This will open a bottom panel, where you can chose which recording to edit. Once
the right one is selected, either click on "Start recording" on the top left
panel, or use the shortcut, :kbd:`R`.

You can now start drawing, every stroke and erasure will be recorded. To end the drawing, click on "Stop recording", or use the shortcut, :kbd:`R`.

Editing a recording
===================

Once you have stopped recording, the bottom panel opens, showing you a timeline representing your recording. The time goes from left to right, and each stroke is represented by a rectangle that spans the time it took to make it, with the color of the stroke. Each erasure is denoted by a circle at the time it happened.

Above the timeline, there is a slider allowing you to set the time for the presentation panel, which displays the state of the drawing at the selected time.

You have several tools to edit a recording, available in the top left panel, or with a key shortcut. Most tools have an effect on both the timeline and the presentation view. Most tools have a different effect depending on whether the current selection is empty or not.

The Selection Tool
------------------

The *selection* tool can be chosen by clicking on it in the top left panel, or by using its shortcut, :kbd:`s`. It allows, unsurprisingly, selecting strokes and erasures, both on the presentation view and on the timeline.

On either target, click and drag with the primary button of your mouse to "preselect" strokes. Preselected strokes will be visible. Once you release the mouse button, the preselection will be turned into a selection.

By default, any new selection replaces the previous one. However, if you hold :kbd:`Shift` during the process, the preselection will be *added* to the selection; if you hold :kbd:`Ctrl`, the elements of the preselection are *added* if they are not already present in the selection, and *removed* otherwise.

In the presentation view, only drawn strokes can be selected. In the timeline, any stroke or erasure can be selected.

The Move Tool
-------------

The *move* tool can be chosen by clicking on it in the top left panel, or by using its shortcut, :kbd:`m`. It allows, unsurprisingly, moving strokes and erasures, in space and time.

To move where strokes are drawn spatially (i.e. their position on screen), click and drag *anywhere* on the presentation view. When something is selected, only those strokes will be moved. When nothing is selected, the same action will move *all* the strokes.

To change the time at which strokes are drawn, click and drag *anywhere* on the timeline. When something is selected, only those strokes and erasures will be shifted in time. When the selection is empty, only the strokes and erasure that happen *after* where you initially clicked will be shifted in time.

In the timeline, one can also change the "track" of the moved strokes. It allows to have an easier view of what happens, and to also control which strokes will be drawn "above" the other.

The Rescale Tool
----------------

The *rescale* tool can be taken by clicking on it in the top left panel, or by using its shortcut, :kbd:`r`. It allows, unsurprisingly, rescaling strokes and erasures, in space and time.

To rescale strokes spatially, click and drag *anywhere* on the presentation view. When something is selected, only those strokes will be rescaled. When nothing is selected, the same action will rescale *all* the strokes.

To change how much time it takes to draw strokes, click and drag *anywhere* on the timeline. When something is selected, only those strokes and erasures will be rescaled in time.

When the selection is empty, and the tool is used on the timeline, the total length of the recording is changed, scaling all of the individual strokes proportionally.

Editing the selection
---------------------

When strokes are selected, you can change their colors and widths in the left part of the bottom panel. You can also delete the selected strokes.

Extending a recording
---------------------

You can extend your recording with new strokes and erasure by clicking "Continue recording" or pressing the shortcut :kbd:`R`. It will put you back in drawing mode, at the selected time. The new recording will be inserted at the current playback point.

Adding pauses
-------------

If you want to add pauses in the replay, use the "Add pause" button, which will create a pause at the current time, displayed in the timeline as a grey bar.

When replayed, the replay will stop at each pause you added, giving you more control over timing.

Saving a recording
==================

Once you are happy with your drawing, click the ``Save`` button to save the file for inclusion in your presentation. Note that to work, this needs to be done through a preview server, which will send you a notification to confirm the save.

If outside a preview server, you can still ``Save As``, which will offer you to "download" the file.

Replaying a recording in a presentation
=======================================

Once you have saved your recording, you need to add an action to replay it.

The action to replay a recording is the ``draw`` action. It takes as input the
id of the drawing, or nothing if it is attached to the drawing. Here is an
example where the first drawing is played immediately, and the second one is
played when the later ``draw`` action referencing it is executed:

.. code-block:: markdown

   ![Something](recording1.draw){draw}

   ![Something else](recording2.draw){#my-id}

   {draw=my-id}

Advice on this kind of presentation
===================================

- *Save often!* Slipshow does not (yet) have a way to undo changes.
- Use the keyboard shortcuts, or you'll find it gets very cumbersome.
- Editing after recording is very easy, so do not hesitate to stop and resume recording; you don't have to get it perfectly right first time.
- Strip leading time with the "Move" tool and trailing time with the "Rescale" tool, both with an empty selection.
- Unfortunately, while it's planned, there is no timeline zoom feature yet. If your recording becomes too long, consider breaking it into several recordings that are played one after the other.
