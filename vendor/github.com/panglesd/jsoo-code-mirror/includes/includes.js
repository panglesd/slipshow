import { EditorView, basicSetup } from "codemirror"
import { EditorState, StateField, StateEffect, EditorSelection, RangeSet, Compartment, ChangeSet } from "@codemirror/state"
import { hoverTooltip, showPanel, keymap, Decoration, WidgetType, lineNumbers, ViewPlugin } from "@codemirror/view"
import { receiveUpdates, sendableUpdates, getSyncedVersion, getClientID, collab } from "@codemirror/collab"
import * as lint from "@codemirror/lint"
import * as autocomplete from "@codemirror/autocomplete"
import * as dark from "@codemirror/theme-one-dark"
import * as language from "@codemirror/language"
import { oCaml } from "@codemirror/legacy-modes/mode/mllike"
import { markdown } from "@codemirror/lang-markdown"
import { dracula } from 'thememirror';
import { LSPClient, languageServerExtensions, jumpToDefinitionKeymap } from "@codemirror/lsp-client"


joo_global_object.__CM__view = EditorView;
joo_global_object.__CM__state = EditorState;
joo_global_object.__CM__Decoration = Decoration;
joo_global_object.__CM__RangeSet = RangeSet;
joo_global_object.__CM__EditorSelection = EditorSelection;
joo_global_object.__CM__lint = lint;
joo_global_object.__CM__autocomplete = autocomplete;
joo_global_object.__CM__hoverTooltip = hoverTooltip;
joo_global_object.__CM__basic_setup = basicSetup
joo_global_object.__CM__dark = dark;
joo_global_object.__CM__language = language;
joo_global_object.__CM__mllike = oCaml;
joo_global_object.__CM__markdown = markdown;
joo_global_object.__CM__showPanel = showPanel;
joo_global_object.__CM__StateField = StateField;
joo_global_object.__CM__StateEffect = StateEffect;
joo_global_object.__CM__keymap = keymap;
joo_global_object.__CM__theme_dracula = dracula;
joo_global_object.__CM__Compartment = Compartment;
joo_global_object.__CM__WidgetType = WidgetType;
joo_global_object.__CM__lineNumbers = lineNumbers;
joo_global_object.__CM__viewPlugin = ViewPlugin;
joo_global_object.__CM__collab = collab;
joo_global_object.__CM__receiveUpdates = receiveUpdates;
joo_global_object.__CM__sendableUpdates = sendableUpdates;
joo_global_object.__CM__getSyncedVersion = getSyncedVersion;
joo_global_object.__CM__getClientID = getClientID;
joo_global_object.__CM__changeSet = ChangeSet;
joo_global_object.__CM__jumpToDefinitionKeymap = jumpToDefinitionKeymap;
