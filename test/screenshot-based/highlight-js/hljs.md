---
highlightjs-theme: gradient-dark
---

```nix
let
  myPackage = derivation {
    name = "example";
    outputs = [ "lib" "dev" "doc" "out" ];
    # ...
  };
in myPackage.dev
```
