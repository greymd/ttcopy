# wpbcopy
Provide copying and pasting to the pasteboard through the Web

## Example 1 (Text)
$ echo foobar | wpbcopy
$ wpbpaste
foobar

## Example 2 (Binary)
$ cat image.jpg| wpbcopy
$ wpbpaste | file -
/dev/stdin: JPEG image data, JFIF standard 1.01

## LICENSE
This is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
