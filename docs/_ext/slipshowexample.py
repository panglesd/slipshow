from docutils import nodes
from docutils.parsers.rst import Directive

class slipshow_example_node(nodes.Element):
    pass


class SlipshowExampleDirective(Directive):
    has_content = True

    def run(self):
        raw_text = "\n".join(self.content)
        node = slipshow_example_node()
        node['raw_text'] = raw_text
        return [node]


def visit_slipshow_example_node_html(self, node):
    self.body.append('<div class="running-example">')

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
