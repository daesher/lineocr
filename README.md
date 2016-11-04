# lineocr
Wrapper to the OCR engines CuneiForm and Tesseract.
Requiriments for usage:
1. Linux (/bin/sh). 
2. xsane
3. Cuneiform or Tesseract (command line)
4. ImageMagick (command line tool convert)
5. gtk2 (interface of LCL)
6. X11

Requiriments for build
1. Freepascal+Lazarus
2. RichMemo component installed

Functions:
1. Scan (with xsane)
2. Open images
3. Rotate images 90 degrees CW or CCW.
4. Crop images (only once works good for now)
5. Recognize with CuneiForm or Tesseract
6. Save all RTF

