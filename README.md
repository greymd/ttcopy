# ttcopy: Trans-Terminal Copy/Paste

[![Build Status](https://travis-ci.org/greymd/ttcopy.svg?branch=master)](https://travis-ci.org/greymd/ttcopy)

Provide copying and pasting within multiple hosts through the Web.

![Introduction Image](./img/ttcp_intro_img.png)

# Environment
  * zsh (tested ver: 4.3, 5.0)
  * bash (tested ver: 3.2, 4.2)

## Dependent commands
  * openssl
  * curl

# Install
First of all, please prepare ID and Password **as you like**.
Do not be lazy. You are **NOT** required to register them on any services.
Same data source (like clipboard) is shared within the hosts having same ID/Password.

After that, please install `ttcopy` to the hosts you want to make share data source each other.
Please follow the following instructions to install.

## For Zsh & [zplug](zplug/zplug)

Add those lines to `.zshrc`.

```sh
# Set ID and Password you decided.
TTCP_ID="your_id"
TTCP_PASSWORD="your_password"

zplug "greymd/ttcopy"
```

## Zsh or Bash

#### 1. Clone repository

```sh
$ git clone https://github.com/greymd/ttcopy.git ~/ttcopy
```

#### 2. Edit `.bashrc` or `.zshrc`

And add following lines.

```sh
# Set ID and Password you decided.
TTCP_ID="your_id"
TTCP_PASSWORD="your_password"

source ~/ttcopy/ttcp.sh
```

# Examples

### Copy & Paste within multiple hosts!

* Host1
```sh
$ echo foobar | ttcopy
```

* Host2
```sh
$ ttpaste
foobar
```

### Binary data is processed as it is.

* Host1
```sh
$ cat image.jpg | ttcopy
```

* Host2
```sh
$ ttpaste | file -
/dev/stdin: JPEG image data, JFIF standard 1.01
```

## LICENSE

This is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
