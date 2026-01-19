# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))

import sys
from pathlib import Path

# I need to add my own extension and it needs to be found (from sphinx tuto)
sys.path.append(str(Path('_ext').resolve()))


# -- Project information -----------------------------------------------------

project = 'slipshow'
copyright = '2020, Paul-Elliot'
author = 'Paul-Elliot'


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.autosectionlabel',
    'sphinx.ext.extlinks',
    'slipshowexample',
    'sphinx_tabs.tabs',
    'sphinxcontrib.video'
]
autosectionlabel_prefix_document = True
todo_include_todos=True

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', '.venv',
    '**/.venv/**']


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
#html_theme = 'alabaster'
html_theme = 'sphinx_rtd_theme'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

html_js_files = ["main.js"]
html_css_files = ["style.css"]



# -- Added By PE -------------------------------------------------------------

# Read The Doc uses a different version of sphinx by default, which has
# a different default for master_doc
master_doc = 'index'

import subprocess

commit_sha = subprocess.check_output(
    ["git", "rev-parse", "HEAD"]
).decode().strip()

extlinks = {
    'github_src': (f'https://github.com/panglesd/slipshow/blob/{commit_sha}/%s', '%s')
}

html_extra_path = ['extra_html']
