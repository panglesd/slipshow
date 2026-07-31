=========================
Drawing your presentation
=========================

In this tutorial, we'll create a presentation in a totally different way, one
that's much more like what you would do in a whiteboard-based presentation.

Note that it is best to have access to a Wacom-like drawing tablet; second-hand
ones can be very cheap. If you don't have one, it's still possible to follow the
tutorial with the mouse!

The presentation topic
----------------------

Let's first discuss the point of this tutorial's presentation. You want to show
to the audience a clever little trick to compute :math:`1+2+3+\dots+100`.

We are going to do the sum *twice*. And then, we'll sum the first one with the last one, and so on, in this way:

.. math::

   \begin{array}{r@{\quad}c@{\quad}r@{\quad}c@{\quad}r@{\quad}c@{\quad}r@{\quad}c@{\quad}r}
    S  &=&   1 &+&   2 &+& \dots &+& 100 \\
   + \quad S  &=& 100 &+&  99 &+& \dots &+&   1 \\
   \hline
   2S  &=& 101 &+& 101 &+& \dots &+& 101
   \end{array}

Now, since we are summing :math:`100` times the number :math:`101`, we get that
:math:`2S = 100 \times 101`, so:

.. math::

   S = \frac{100 \times 101} 2 = 5050

Now, take a moment to think how you would present that, in two situations:

- You explain it to a friend and you have a pen and paper or a whiteboard
- You do a presentation with slides.

Which one is the easiest to prepare? And which one is the clearest and most
enjoyable to watch? These questions obviously depend on the person, but for me
and this particular visual explanation, the "pen and paper" approach works best!

So why do we still do slide-based presentations? Probably because it has other
advantages: It's easily readable if your handwriting is not perfect, you can
share your slides, it's less stressful as you have less to do during the
presentation, and you can reuse your slides.

The record-and-replay drawing feature of Slipshow tries to reclaim the "niceness" and immediacy of
whiteboard presentations, while retaining some of the advantages of prepared
presentations.

.. note::

   What does it take to render the sum above in a typed presentation? Here is how I did it:

   .. code-block::

      \begin{array}{r@{\quad}c@{\quad}r@{\quad}c@{\quad}r@{\quad}c@{\quad}r@{\quad}c@{\quad}r}
              S  & = &   1 & + &   2 & + & \dots & + & 100 \\
      + \quad S  & = & 100 & + &  99 & + & \dots & + &   1 \\
              \hline
              2S & = & 101 & + & 101 & + & \dots & + & 101
      \end{array}

   The spacing gave me trouble; we can probably do better. Drawing is
   definitely easier, more human, and conveys a richer message (e.g. in the order
   in which you draw things).

Starting with drawings
----------------------

The best way to create drawings in slipshow, is to use a preview server: either with ``slipshow serve``, or simply by opening the file in your editor if you `configured it <editor-setup>`_.

The workflow to integrate drawings to your presentation is the following:

1. First, you'll decide where in the text flow you want to anchor your
   drawing. This allows to add some text before, and have the drawing moved down
   accordingly. Simply add ``![Description of the drawing](filename.draw)``
   there.
2. The preview server will allow to record a drawing, and then edit it as much as needed.
3. Once you are happy, you can save the drawing to ``filename.draw`` through the
   preview server
4. During the presentation, specific slipshow actions allow you to replay saved
   drawings.

In this tutorial, the "typed" part of the presentation is minimal: We'll just type the title, the rest will be drawn. We also chose a ratio that gives us more horizontal space, and that is common for video projectors and laptop screens.

Let's create the following ``sum.slp`` file:

.. code-block::

   ---
   dimension:16:9
   ---

   # Sum of consecutive numbers

   ![Sum of consecutive numbers](sum.draw)

If you did not use a setup editor,

.. code-block::

   $ slipshow serve sum.slp

Great! We can now start our recorded drawing.

Drawing
-------

Now, let's open the preview with your favorite browser.  You should see a
presentation with no steps, just a title.

In the top left, you'll find the tools to use for drawings. Try it!
Press :kbd:`p` to select the pen, and draw on the screen with your mouse. Change
the width of the stroke, the color, use the highlighter with :kbd:`h`. Erase
some of the strokes with the erase tool, selectable with :kbd:`e`.

But you are in "presentation" mode, which is meant to be used to do live annotations
during a presentation, so the drawing is not recorded.

We'll now record a sketch drawing that we'll use for our explanation. For
instance, the sum rendered in the first section.

First, clear all your test drawings with :kbd:`Shift` + :kbd:`X`.  Then, open
the "Recording manager" with :kbd:`Shift` + :kbd:`R`. Here, you'll see an empty
recording named "Unnamed recording", and a list of recordings that contains only
this one. We'll start by renaming it ``Sum``, by typing that in the text input.

Now, the fun part! Start recording with :kbd:`Shift` + :kbd:`R`, and draw the
sum! When you have finished drawing, press :kbd:`Shift` + :kbd:`R` again to
finish the recording.

.. video:: example_drawing3.mp4
   :width: 100%

You should now see the timeline of your strokes over time. On top of the
timeline is a slider you can move around, and see the preview update
accordingly. You can also press the :kbd:`Play` button to see how the replay
looks!

If you replay your drawing from the beginning, you will probably notice a few problems:

- The recording includes some inactive time before the
  first stroke and after the last.
- The replay probably feels very slow (unless you are very good!).

Fortunately, the drawing and timeline are editable! First take the "Select tool"
by pressing :kbd:`s`, and select all strokes with a click-and-drag either on the
timeline, or on the preview. Then, take the "Move tool" with :kbd:`m`, and move
the strokes in the timeline by click-and-dragging left from anywhere on the
timeline!

This solves the problem of initial delay before the first stroke is
replayed. Now, let's select the "Rescale tool" with :kbd:`r`. Similarly,
click-and-drag left from anywhere on the timeline to rescale the selected
strokes, making them replay faster. Test the new speed by replaying the preview
until you are satisfied.

The remaining fix is to remove the trailing recording time, so that replay
stops after the last stroke. To do this, use the Select tool and click
anywhere to unselect everything. Then, go back to the Rescale tool. In the
absence of a selection, the rescale tool changes the overall recording time. Click
anywhere on the timeline and drag left until the end of the recording is at the
end of the last stroke.

.. note::

   - The "Select" tool will allow you to select strokes, either on the preview
     or on the timeline.
   - The "Move" tool will allow you to move strokes, either spatially on the
     preview, or in time on the timeline. The move tool moves all *selected*
     strokes, no matter where you click! If you don't have any selected strokes,
     it moves all strokes that are after where you clicked.
   - The "Rescale" tool will allow you to rescale strokes, either spatially on
     the preview, or in time on the timeline. The rescale tool rescales all
     *selected* strokes, no matter where you click! If you don't have any
     selected strokes, it rescales the duration of the whole timeline.

.. video:: editing3.mp4
   :width: 100%

We are almost there! Now, we want to add pauses in various places, to leave us
some time to speak, take questions, etc:

- Before writing the second ("reversed") sum.
- Before making the "sum of the two sums".

We can do that! Use the slider on top of the timeline to position the time where
you want, and click the ``Add pause`` button. Now, replay from the beginning:
the replay stops at the pause! If you click replay again, playback continues.

.. video:: edit-plus.mp4
   :width: 100%

Saving the drawing file
-----------------------

Once you have finished editing the timeline and the preview, click on the "Save"
button. It will save the edited recording as ``sum.draw``. The preview server
should show a notification that the file was saved.

.. video:: save.mp4
   :width: 100%

Triggering the replay of the drawing
------------------------------------

If you refresh the preview, you'll notice that the drawing does not appear yet!
This is because drawing is an *action*, that needs to be triggered
explicitly. The action name is ``draw``; add it to the included file:

.. code-block::

   ![](sum.draw){draw}

This time, going to the next step plays the drawing until it reaches the first pause! If
we want to draw the other steps, use another draw action. We use the identifier
here to say which drawing we need to draw:

.. code-block::

   ![](sum.draw){#sum-drawing}

   {draw=sum-drawing}

   {draw=sum-drawing}

   {draw=sum-drawing}


.. video:: replay.mp4
   :width: 100%

Modifying a recording
---------------------

If you need to modify the recording, open the recording manager with
:kbd:`Shift` + :kbd:`R`, and select the recording in the list. You can add
strokes by extending the recording with :kbd:`Shift` + :kbd:`R`. Once you are
satisfied, click save.
