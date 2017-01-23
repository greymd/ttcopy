# Trans-Terminal Copy/Paste
Provide copying and pasting within multiple hosts through the Web.

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
TTCP_ID="your_id"
TTCP_PASSWORD="your_password"

zplug "greymd/ttcopy"
```

## zsh, bash

```sh
# Set ID and PASSWORD **AS YOU LIKE**.
TTCP_ID="your_id"
TTCP_PASSWORD="your_password"

source ttcp.sh
```

# Examples

* copy & paste

```sh
$ echo foobar | ttcopy
$ ttpaste
foobar
```

* binary data is processed as it is.

```sh
$ cat image.jpg| ttcopy
$ ttpaste | file -
/dev/stdin: JPEG image data, JFIF standard 1.01
```

## LICENSE

This is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
