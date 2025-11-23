=========================
Drawing record and replay
=========================

Slipshow has an experimental feature, where you can record a drawing, and replay it during you presentation.

This allows to easily make a diagram, a graph, or provide recorded sketching during an explanation, freeing you from having to draw it live.

This feature is still experimental, and time will tell how useful it is, what are its limitations and how to improve it. Do not hesitate to reach out if you use it, and write about how it went.

Starting a recording
====================

In order to start recording a drawing, open the presentation you want to include the drawing in a web browser.

In the upper left, amongst the drawing tools, you'll find a "Manage my recording" button. Click on it, or use the shortcut ``R``.

This will open a bottom panel, where you can either edit your previous recordings (TODO: add link). This includes any recording added to the presentation, as well as a "new one", initially named "Unnamed recording".

You can change this name in the left part of the bottom panel.

Once you have named your new recording, let's actually record the drawing! Either click on "Start recording" on the top left panel, or use the shortcut, ``R``.

You can now start drawing, every stroke and erasure will be recorded. To end the drawing, click on "Stop recording", or use the shortcut, ``R``.

Editing a recording
===================

Once you have stopped recording, the bottom panel opens up, showing you a timeline representing your recording. The time goes from left to right, and each stroke is represented by a rectangle that spans the time it took to make it, with the color of the stroke. Each erasure is depicted by a circle at the time it happened.

Above the timeline, there is a slider allowing you to set the time for the presentation panel, which displays the drawing at the selected time.

You have several tool to edit a recording, available on the top left panel, or with a key shortcut. Most tools have an effect both on the timeline, and the presentation view. And, most of them have a different effect whether the selection is not empty.

The Selection Tool
------------------

The selection tool can be taken by clicking on it in the top left panel, or by using its shortcut, ``s``. It allows, unsuprisingly, to select strokes and erasures, both on the presentation view and the timeline.

On both targets, click and drag with the primary button of your mouse to "preselect" strokes. Preselected strokes will be visible. Once you release the mouse button, the preselection will be turned into a selection.

In the default case, the new selection replaces the previous one. However, if you hold ``Shift`` during the process, the preselection will be added to the selection. And if you hold ``Ctrl``, the elements of the preselection are added if not present in the selection, and removed otherwise.

In the presentation view, only drawn strokes can be selected. In the timeline, any stroke or erasure can be selected.

The Move Tool
-------------

The move tool can be taken by clicking on it in the top left panel, or by using its shortcut, ``m``. It allows, unsuprisingly, to move strokes and erasures, in space-time.

To move where spatially strokes are drawn, one has to click and drag *anywhere* on the presentation view. When the selection is non empty, only the currently selected strokes will be moved. When the selection is empty, the same action will move the entirety of the strokes.

To change the time when strokes are being drawn, one has to click and drag *anywhere* on the timeline. When the selection is non empty, only the currently selected strokes and erasure will be shifted in time. When the selection is empty, only the strokes and erasure that happen *after* where you initially clicked will be shifted in time.

In the timeline, one can also change the "track" of the moved strokes. It allows to have an easier view of what happens, and to also control which strokes will be drawn "above" the other.


The Rescale Tool
----------------

The rescale tool can be taken by clicking on it in the top left panel, or by using its shortcut, ``s``. It allows, unsuprisingly, to rescale strokes and erasures, in space-time.

To spatially rescale strokes, one has to click and drag *anywhere* on the presentation view. When the selection is non empty, only the currently selected strokes will be rescaled. When the selection is empty, the same action will rescale the entirety of the strokes.

To change how much time it takes to draw strokes, one has to click and drag *anywhere* on the timeline. When the selection is non empty, only the currently selected strokes and erasure will be rescaled in time.

When the selection is empty, and the tool is used on the timeline, the total length of the recording is changed.

Editing the selection
---------------------

When your selection is not empty, you can change the colors and width of the strokes in the left part of the bottom panel. You can also delete the selection.

Extending a recording
---------------------

You can extend your recording with new strokes and erasure by clicking "Continue recording" or pressing the shortcut ``R``. It will put you back in drawing mode, at the selected time. The new recording will be inserted at the time set.


Saving a recording
==================

Once you are happy with your drawing, you can use the ``Save`` button to save the file for inclusion in your presentation. You can change the name, but should not change the extension, as it is used by Slipshow to recognize the content of the file.

Including and replaying a recording in a presentation
=====================================================

Once you have saved your recording, you need to include it in your presentation.

To do so, use the image following syntax:

.. code-block:: markdown

   ![](your-recording.draw)


Where the name of your own file is used instead of ``your-recording.draw``.

Then, replaying a recording is the ``draw`` action. It takes as input the id of the drawing, or nothing if it is attached to the drawing. Here is an example:

.. code-block:: markdown

   ![](recording1.draw){draw}

   ![](recording2.draw){#my-id}

   {draw=my-id}

Editing an included recording
=============================

If you have included a recording, you can edit it by selecting it on the left of the bottom panel, while having no selection.

Once you have edited the recording, save it the same way, overwriting the old recording file.
