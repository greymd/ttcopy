# wpbcopy
Provide copying and pasting to the pasteboard through the Web

# Environment
  * zsh
  * bash

# Dependencies
  * openssl
  * curl

# Install

## zsh & zplug

Add this line to `.zshrc`.

```sh
# Set ID and PASSWORD **AS YOU LIKE**.
WPB_ID="your_id"
WPB_PASSWORD="your_password"

zplug "greymd/wpbcopy"
```

## zsh, bash

```sh
# Set ID and PASSWORD **AS YOU LIKE**.
WPB_ID="your_id"
WPB_PASSWORD="your_password"

source wpb.sh
```

# Examples

* copy & paste

```sh
$ echo foobar | wpbcopy
$ wpbpaste
foobar
```

* binary data is processed as it is.

```sh
$ cat image.jpg| wpbcopy
$ wpbpaste | file -
/dev/stdin: JPEG image data, JFIF standard 1.01
```

## LICENSE

This is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
