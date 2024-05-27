Bugs
====

Add a section for the bug and the CommonMark that triggers it as 
follows:

```
# Bug #NUM

The triggering CommonMark
```

# Bug #10 

In cells toplevel text nodes not at the beginning or end of the cell
get dropped.

|  Foo                    |
|-------------------------|
| `a` or `b`              |
| before `a` or `b` after |
| before `a` or `b`after  |
| before`a`or`b`after     |
| *a*`a`                  |
| <p>foo</p>              |
