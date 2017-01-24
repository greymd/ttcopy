# Trans-Terminal Copy/Paste

[![Build Status](https://travis-ci.org/greymd/ttcopy.svg?branch=master)](https://travis-ci.org/greymd/ttcopy)

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

#### 1. Clone Repository

```sh
$ git clone https://github.com/greymd/ttcopy.git ~/ttcopy
```

#### 2. Edit `.bashrc` or `.zshrc`

And add following lines.

```sh
# Set ID and PASSWORD **AS YOU LIKE**.
TTCP_ID="your_id"
TTCP_PASSWORD="your_password"

source ~/ttcopy/ttcp.sh
```

# Examples

### Copy & Paste

```sh
$ echo foobar | ttcopy
$ ttpaste
foobar
```

### Binary data is processed as it is.

```sh
$ cat image.jpg | ttcopy
$ ttpaste | file -
/dev/stdin: JPEG image data, JFIF standard 1.01
```

## LICENSE

This is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
