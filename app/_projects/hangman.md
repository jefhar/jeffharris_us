---
title: Hangman
date: September 25, 2019
image: /assets/img/hangman-java.png
header:
  teaser: /assets/img/hangman-java.png
tags: [Java, Java-13]
---
[Github source](https://github.com/jefhar/hangman-java)

![Hangman screenshot](/assets/img/hangman-java.png "Hangman screenshot"){: height="250px"}

## Overview
**Hangman** is the simple find a word game played by children with pencil
and paper the world over. Is it the best? Probably not. Is the the fastest?
Probably not. However, I built it and it works.

This uses the `/usr/share/dict/american-english` word file from Ubuntu 19.04.
Most of the proper nouns and words with non-letter characters have been removed.
Maybe I missed one, maybe I didn't. There are 102401 lines of words in the
original file. If you find a non-letter character, file an
[issue](https://github.com/jefhar/hangman-java/issues) or a pull request.

### Usage
```
$ git clone https://github.com/jefhar/hangman-java.git
```
Then compile using your favorite compiler.

Have docker?
```
docker run -it jefhar/hangman:java
```

### Code
You can find the source code for Hangman at
[GitHub](https://github.com/jefhar/hangman-java).
