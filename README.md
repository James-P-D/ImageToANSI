# ImageToANSI
Image to ANSI converter in Perl

![Screenshot](https://github.com/James-P-D/ImageToANSI/blob/main/screenshot.gif)

## Introduction

This program can be used to output an image on the terminal, using the closest colors we can find using [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit).

The program first divides the original image into squares, then identifies the most prominent color in the square, before attempting to match it to the closest of the 16-available colors in the terminal. Because the pallette is so limited, you will get better results with brightly colored images, such as cartoon characters, than will regular photographs.

Since each cell in the terminal is roughly twice as high as they are wide, we cannot simply use one terminal-cell to represent one square in the image, otherwise the output would be elongated vertically. Instead, for each two-vertical squares in the original image, we use one single cell in the terminal, and display a lower-block character (`▄` ASCII code 220) in the terminal. We can then color the top-half of the cell by setting the background color, and then color the bottom-half by setting the foreground color.

## Running

The program was tested used Perl 5. To see the arguments for the script, simply run it from the terminal:

```
C:\Users\jdorr\Desktop\perl>perl ImageToANSI.pl
Usage:
perl ImageToANSI.pl IMAGE_FILE [options]:
     [Options] - /q     (quiet mode)
               - /c X   (columns (default X=80))
```

The first paramter should be the path to an image file (jpg, png, etc.). Additionally you can use `/q` to supress the debugging output (image width/height, progress during conversion, etc.) and `/c` can be used to change the number of columns the image will be scaled to.