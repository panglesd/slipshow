### Pending

- Use _WIN32 and MAX_PATH on Windows to support MSVC (#34, @jonahbeckford)

### 0.5.0 (2020-04-30)

- Switch to GitHub Actions from Travis (#31, @avsm)
- Initialise backends only when needed via a
  lazy watcher interface (#31, @samoht @avsm)
- Use fsevents and cf-lwt packages (#31, @avsm)
- Use ocamlformat.0.18.0 (#31, @avsm)

### 0.4.1 (2019-07-02)

- Clearer name for hook logger (@talex5, #21)
- Fix race when scanning directories (@talex5, #21)
- Make listen loop tail-recursive (@talex5, #21)

### 0.4.0 (2018-10-08)

- use dune (#13, @mc10)
- rename `unix_realpath` function name to avoid name clashes (#17, @samoht)

### 0.3.0 (2017-06-21)

- Use jbuilder (#11, @samoht)

### 0.2.0 (2016-11-14)

- Allow to watch non-existing directories (#8, @samoht)
- Expose `Irmin_watches.stats` to get stats about the numbers
  of active watchdogs, and callback dispatchers (#7, @samoht)
- When using fsevents/inotify do not scan the whole tree everytime
  (#6, @samoht)
- Use realpath(3) on Linux and GetFullPathName on Windows to
  normalise the path to watch (#6, @samoht)
- inotify: close the inotify file descriptor when stopping the
  watch (#6. @samoht)
- inotify: fix the path of watched events (inotify uses relative
  patch, unless fsevents which uses absolute paths) (#6, @samoht)
- fix detection of removed files (#6, @samoht)

### 0.1.4 (2016-08-16)

- Use osx-fsevents > 0.2.0 to avoid an fd leak when starting/stoping
  the main watch scheduler.

### 0.1.3 (2016-08-15)

- Fix `uname` runtime checks on Windows

### 0.1.2 (2016-08-10)

- Fix link issue when no inotify/fsevents backends are available
- Use topkg 0.7.8

### 0.1.1 (2016-08-09)

- Fix link issue with the inotify backend

### 0.1.0 (2016-08-09)

- Initial release
