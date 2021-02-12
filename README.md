# Assembler_programs
Programs to encrytp/decrypt message and zoom keyboard input.  
  
#
### *xor.asm*
The program to encrypt and decryt messages by doing xor on input text and given key text.  
The input data are: input file name, output file name, key text in quotes. Encryption:  
```
  xor file_1.txt file_2.txt "key to encrypt message"
```
Encryption using xor i symmetric, so the same key must be used to decrypt message. Decryption:
```
  xor file_2.txt file_3.txt "key to encrypt message"
```
  
#
### *zoom.asm*  
The program to zoom and display given text. The text is displayed on screen graphic mode VGA.  
The input data are: a number (zoom) and a text to enlarge.  
```
  zoom 8 "text to enlarge"
```  
<br>  

#
Letters in *letters.txt* made by [@retkiewi](https://github.com/retkiewi) based [on](https://github.com/retkiewi/Assembler/tree/master/Zad2/letters/font8x8-master). 
