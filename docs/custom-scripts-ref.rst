==============
Custom scripts
==============

Use a slipscript code block to add a script, and ``exec`` to execute it.

.. code-block:: markdown

		{pause exec}
		```slip-script
                alert("Alerts are very annoying !")
		```

If a script has a "permanent" side-effect, it has to provide a way for slipshow
to revert it. There are currently two experimental ways to do that. The first
one (but not the preferred one) is return an undo function:

.. code-block:: markdown

		{pause exec}

		```slip-script
                let elem = document.querySelector("#id")
		let old_value = elem.style.opacity;
                elem.style.opacity = "1";
                return {undo : () => { elem.style.opacity = old_value }}
		```

However this is not always easy to compose. The other option is to use
the ``slip.onUndo`` function to register callbacks to be run on undo.

.. code-block:: markdown

		{pause exec}

		```slip-script
                let i = 0
                let incr = () => {
                  slip.onUndo(() => { console.log(--i)})
                  console.log(i++);
                }
                incr();
                incr();
                incr();
		```

Using ``slip.onUndo`` inside an undo callback should not be a problem. (Actually, it might be recommended.)

Slipshow provides a few utils function, using the callback mechanism just described.

You can use ``slip.setStyle(elem, style, value)`` where ``elem`` is an element, and ``style`` and ``value`` a string to set a style and register an undo callback.

You can also use ``slip.setClass(elem, className, bool)`` where ``elem`` is an element, ``style`` is a string and ``bool`` a boolean to add or remove a class and register an undo callback.

You can also use ``slip.setProp(object, propName, value)`` where ``object`` is an element, ``propName`` is a string and ``value`` a value to set a property and register an undo callback.

Through the ``slip`` object, slip-scripts also have access to the actions defined above. Again, they work using the ``onUndo`` callbacks. They can be used to programmatically call the actions defined above.

.. code-block:: markdown

		{pause exec}
		```slip-script
                let elem = document.querySelector("#id")
                slip.up(elem);
		```

Note that if an API above accepts multiple IDs (as ``unstatic`` for instance), then the function expects a list of elements:

.. code-block:: markdown

		{pause exec}
		```slip-script
                let elems = document.querySelectorAll(".class")
                slip.unstatic(elems);
		```

The expression ``slip.isFast()`` tells whether we are "running fast" (e.g. when going to a specific starting state) or not.

Finally, the ``slip.state`` object is persisted between scripts. (Other functions are specific to a script. This might change in the future, but ``slip.state`` is safe to use).

Use it with ``slip.setProp`` to not forget undoing the changes!

.. code-block:: markdown

		{pause exec}
		```slip-script
                log = function (slip, x) { // slip needs to be passed
                  console.log(x)
                  slip.onUndo(() => {console.log(x)})
                }
                log(slip, slip.state.x);
                slip.setProp(slip.state, "x", 1);
                log(slip, slip.state.x);
                ```
		{pause exec}
		```slip-script
                log(slip, slip.state.x); // 1
                ```
