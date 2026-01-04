import { EditorView, basicSetup } from "codemirror"
import { EditorState, ChangeSet } from "@codemirror/state"
import { hoverTooltip, ViewPlugin } from "@codemirror/view"
import { receiveUpdates, sendableUpdates, getSyncedVersion, collab } from "@codemirror/collab"
import { markdown } from "@codemirror/lang-markdown"
import * as lint from "@codemirror/lint"
import * as autocomplete from "@codemirror/autocomplete"
import * as dark from "@codemirror/theme-one-dark"
import * as language from "@codemirror/language"
import { oCaml } from "@codemirror/legacy-modes/mode/mllike"

joo_global_object.__CM__view = EditorView;
joo_global_object.__CM__collab = collab;
joo_global_object.__CM__receiveUpdates = receiveUpdates;
joo_global_object.__CM__sendableUpdates = sendableUpdates;
joo_global_object.__CM__getSyncedVersion = getSyncedVersion;
joo_global_object.__CM__viewPlugin = ViewPlugin;
joo_global_object.__CM__markdown = markdown;
joo_global_object.__CM__changeSet = ChangeSet;
joo_global_object.__CM__state = EditorState;
joo_global_object.__CM__lint = lint;
joo_global_object.__CM__autocomplete = autocomplete;
joo_global_object.__CM__hoverTooltip = hoverTooltip;
joo_global_object.__CM__basic_setup = basicSetup
joo_global_object.__CM__dark = dark;
joo_global_object.__CM__stream_parser = language;
joo_global_object.__CM__mllike = oCaml;
