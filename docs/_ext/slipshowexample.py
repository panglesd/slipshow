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
    self.body.append('<div dimension="'+node['dimension']+'" class="running-example '+node['visible']+'">')

    # Write raw, *escaped* text so it appears exactly as typed
    self.body.append(self.encode(node['raw_text']))


def depart_slipshow_example_node_html(self, node):
    self.body.append('</div>')


def setup(app):
    app.add_node(
        slipshow_example_node,
        html=(visit_slipshow_example_node_html,
              depart_slipshow_example_node_html),
    )
    app.add_directive("slipshow-example", SlipshowExampleDirective)
    return {"version": "0.1"}
