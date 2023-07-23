---
paginate: true
marp: true
footer: andrea.manzini@suse.com
theme: default
---
# Oxidize your shell

## 5+1 modern CLI tools for *Ye Olde* rusty geekos

![bg left fit](img/opensuse-logo-color.svg)

---
# Brace yourself

## We are going to replace 
- `cat`
- `find`
- `grep`
- `ps`
- `time`
- `PS1`

![bg right fit](img/screaming_cropped-scaled.jpg)

---
# Why ? I like my old tools!

## ... and they work flawlessly 😠

- A pillar of free software: diversity, richness, freedom of choice... The [Bazaar](http://www.catb.org/~esr/writings/cathedral-bazaar/)! 
- New users use them on other platforms, maybe you want to know what those foolish young hipsters mess around with 🤓
- Totally optional, use at your own pace. Nothing disappears installing them
- Good OSS projects, small enough to start contributing in a new programming language (also because they may lack features that unix veterans can bring in 😉) 
- Why not ? Trying something new won't hurt


---
# And of course...

##  ... because there's a cute mascot like Ferris the crab

![bg right fit](img/cuddlyferris.svg)

---
## The tools 1/2

1. [bat](https://github.com/sharkdp/bat) 🦇 
an alternative to `cat` , with syntax highlighting and `git` integration. Shows non-printable characters
2. [procs](https://github.com/dalance/procs)
a modern replacement for `ps`: colored output, integrate filtering and paging
3. [fd](https://github.com/sharkdp/fd) a simple, fast and user-friendly alternative to `find`. Smart case, colored output, `.gitignore` integration, parallel command execution

---
## The tools 2/2

4. [ripgrep](https://github.com/BurntSushi/ripgrep) a `grep` alternative specialized in code search. [Fast](https://blog.burntsushi.net/ripgrep/), unicode+git aware and with replacement support
5. [hyperfine](https://github.com/sharkdp/hyperfine) a command-line benchmarking tool with many features: analysis across multiple runs, realtime feedback, warmup runs, statistical outlier detection


## Bonus mention

[Starship](https://starship.rs/) 🚀

The minimal, blazing-fast, and infinitely customizable prompt for any shell!

---
# How they can be useful ?

- A richer and pleasant CLI experience can improve day to day productivity
- Green field for innovation: no legacy constraints, no limit to try out new ideas
- Learning from well written Rust source code
- Packaged in OpenSUSE (check out how they are packaged on [OBS](https://build.opensuse.org))

---
# Thanks!

These slides are Open Source and live in a [github repository](https://github.com/ilmanzo/suse_presentations), feel free to improve them 💚

![bg right fit](img/opensuse-logo-color.svg)
