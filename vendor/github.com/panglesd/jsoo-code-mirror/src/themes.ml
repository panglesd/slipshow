type settings = {
  background : string;
  foreground : string;
  caret : string;
  selection : string;
  lineHighlight : string;
  gutterBackground : string;
  gutterForeground : string;
}

type variant = Dark | Light

let create_theme variant settings _style =
  let open View.EditorView in
  let backgroundColor = "backgroundColor" in
  let color = "color" in
  let s = settings in
  let th =
    TO
      [
        ( "&",
          TO [ (backgroundColor, TV s.background); (color, TV s.foreground) ] );
        (".cm-content", TO [ ("caretColor", TV s.caret) ]);
        (".cm-cursor, .cm-dropCursor", TO [ ("borderLeftColor", TV s.caret) ]);
        ( "&.cm-focused .cm-selectionBackgroundm .cm-selectionBackground, \
           .cm-content ::selection",
          TO [ (backgroundColor, TV s.selection) ] );
        (".cm-activeLine", TO [ (backgroundColor, TV s.lineHighlight) ]);
        ( ".cm-gutters",
          TO
            [
              (backgroundColor, TV s.gutterBackground);
              (color, TV s.gutterForeground);
            ] );
        (".cm-activeLineGutter", TO [ (backgroundColor, TV s.lineHighlight) ]);
      ]
  in
  theme ~dark:(variant = Dark) th
