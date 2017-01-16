# wpbcopy
Provide copying and pasting to the pasteboard through the Web

# Dependencies

  * openssl
  * xmllint
  * zsh
  * bash (over version 4)

# Install

## zsh & zplug

Add this line to `.zshrc`.

```
# Set ID and PASSWORD **AS YOU LIKE**.
WPB_ID="your_id"
WPB_PASSWORD="your_password"

zplug "greymd/wpbcopy"
```

## zsh, bash

```
# Set ID and PASSWORD **AS YOU LIKE**.
WPB_ID="your_id"
WPB_PASSWORD="your_password"

source wpb.sh
```

# Examples

* copy & paste

```
$ echo foobar | wpbcopy
$ wpbpaste
foobar
```

* binary data is processed as it is.

```
$ cat image.jpg| wpbcopy
$ wpbpaste | file -
/dev/stdin: JPEG image data, JFIF standard 1.01
```

## LICENSE

This is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
