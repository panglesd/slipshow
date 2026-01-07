from docutils import nodes
from docutils.parsers.rst import Directive, directives

class slipshow_example_node(nodes.Element):
    pass


class SlipshowExampleDirective(Directive):
    has_content = True
    option_spec = {
        "visible": directives.unchanged,
        "dimension": directives.unchanged,
    }
    def run(self):
        raw_text = "\n".join(self.content)
        node = slipshow_example_node()
        node['raw_text'] = raw_text
        node['visible'] = self.options.get("visible", "both")
        node['dimension'] = self.options.get("dimension", "")
        return [node]

def visit_slipshow_example_node_html(self, node):
    match node['visible']:
        case "both":
            mode = "show-both"
        case "editor":
            mode = "show-editor"
        case "presentation":
            mode = "show-presentation"
        case _:
            mode = "show-both"
    self.body.append(f"""
<div dimension="{node['dimension']}" class="running-example {node['visible']}">
  <div class="entry {mode}">
    <div class="tabs">
      <div class="editor-button">Editor</div>
      <div class="pres-button">Presentation</div>
      <div class="both-button">Both</div>
    </div>
    <div class="editor"></div>
    <div class="preview"></div>
    <div class="source" style="display:none">""")
    # Write raw, *escaped* text so it appears exactly as typed
    self.body.append(self.encode(node['raw_text']))
    self.body.append('</div></div></div>')

def depart_slipshow_example_node_html(self, node):
    pass

def setup(app):
    app.add_node(
        slipshow_example_node,
        html=(visit_slipshow_example_node_html,
              depart_slipshow_example_node_html),
    )
    app.add_directive("slipshow-example", SlipshowExampleDirective)
    return {"version": "0.1"}
