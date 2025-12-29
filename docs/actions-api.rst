=======
Actions
=======

An action consists of a name, a set of possible arguments, and an effect. In this page, we describe all possible actions.

Inserting an action in the presentation is done by adding an attribute with the name of the action.

.. code-block::

   Some content.

   {center}

   Some other content.

The effect might be different when the attribute is attached to an element.

.. code-block::

   Some content.

   {center}
   Some other content.

Arguments can be added to an action. In this case, the attribute is a key-value attribute, the key being the name of the action, and the value containing the arguments.

.. code-block::

   {#one}
   Some content.

   {center=one}

   Some other content.

An action can have two kind of arguments: named arguments, and positional ones. Named argument are of the form ``~argument-name:value`` and positional are given as-is. The list of arguments is space-separated.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one"}

   Some other content.

It is possible to have multiple actions in a single attribute. They will be executed at the same step.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one" reveal="two three"}

   {#two .unrevealed}
   Some other content.

   {#three .unrevealed}
   Some more content.

API
===
