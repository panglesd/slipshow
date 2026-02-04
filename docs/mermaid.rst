===================
Mermaid.js diagrams
===================

`Mermaid.js <https://mermaid.js.org/>`_ is a diagramming and charting tool. It allows you to write descriptions of diagrams, and let them be rendered.

Including Mermaid diagrams
==========================

In order to include mermaid.js diagrams, enclose the mermaid syntax in a code block with language ``=mermaid``.

.. slipshow-example::
   :visible: both
   :dimension: 4:3

   ``` =mermaid
   graph TD;
       A-->B;
       A-->C;
       B-->D;
       C-->D;
   ```

Configuring Mermaid
===================

Mermaid can be configured by setting the ``window.Mermaid`` configuration value, following mermaid's `configuration schema <https://mermaid.js.org/config/schema-docs/config.html>`_. The default value is:

.. code-block::

   {
     startOnLoad: false,
     deterministicIds : true,
     securityLevel: "loose"
   }

Not that ``startOnLoad`` has to be set to false, in order for Slipshow to be able to start when all diagrams have been rendered.
