code1 segment
start1:

	mov ax, seg top1
	mov ss, ax 
	mov sp, offset top1
	
	
	;CZYTANIE PARAMETRÓW WYWOŁANIA
	
	mov si, 82h				
	mov di, offset zoom
	
	mov cx, 0				  			; petla <- zerowanie cx-licznik
	mov cl, byte ptr ds:[80h] 			;pod 80h jest ilosc znakow

spr:									;pomijanie spacji przed pierwszym argumentem
	cmp byte ptr ds:[si],' '
	je spac1
	
	mov al, byte ptr ds:[si]			 ;zapisanie cyfry w zmiennej
	mov byte ptr cs:[di],al
	add si,2									;następnym znakiem powinna być spacja - 
													; - pomijam ją i zaczynam czytać tekst od następnego znaku, aż do końca
	
	
	sub cx,3 									; zmiejszam cx tyle razy ile znaków już ominęłam +1 - na 13 na końcu wejścia
	
	mov di, offset buf						; będzie zapisywał przeczytane znaki do bufora
	push cx
czy: 										; pętla, w której czyta znaki do końca wejścia i zapisuje w buf
	
	mov al, byte ptr ds:[si]
	mov byte ptr cs:[di],al
	inc si
	inc di
	
	loop czy
	
	
	
	;WŁĄCZENIE TRYBU GRAFICZNEGO

ent:	
	mov ah,0								;czekanie na ENTER
	mov al,13h
	int 16h
	
	cmp al,13
	jne ent
	
	
	mov al,13h								; tryb graficzny 320x200, 256 kolorów
	mov ah,0								; zmiana trybu karty VGA
	int 10h									; przerwanie BIOS
	
	pop cx
	
	
	;OTWARCIE PLIKU Z BITMAPAMI LITER
	
	mov ax, cs		
	mov ds, ax
	mov dx, offset map
	mov al, 0					; 0 znaczy ze tylko do odczytu
	mov ah, 3dh					; otwarcie pliku z ds:dx
	int 21h
	jc err
	mov bx,ax	
	
	
	
	;RYSOWANIE LITER
	
	mov di, offset buf
	mov word ptr cs:[y],0
	mov word ptr cs:[x],0
	
	
	
	;PĘTLA ZNAJDUJĄCA KOLEJNE LITERY Z WEJŚCIA
	
wezlitere:	
	push cx
		
	call znajdzmape
	call poznaku 				; żeby ominąć znak 13
	call poznaku				; i znak 10
	
	
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	
	push ax
	
	call check
	
	
mcx:
	mov ax, 80							; 64 znaki '0' lub '1' +16 znaków 10 i 13
	pop cx
	push cx	
	mul cx								; pomnożone przez 'zoom'
	mov cx,ax						
	
	
	;PĘTLA WYŚWIETLAJĄCA LITERĘ Z BITMAPY

rysuj:
	push cx
	call poznaku
	cmp byte ptr cs:[lit], '1'
	jne cmpe
	
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	mov dx,ax
xlop:
	push dx
	call zapal
	pop dx
	add word ptr cs:[x],1
	
	dec dx
	cmp dx,0
	jne xlop
	jmp om	


cmpe:
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	push ax
	
	cmp byte ptr cs:[lit],10
	jne addx
	
	add word ptr cs:[y],1
	
	pop ax
	push ax
	mov cx,9
	mul cx
	sub word ptr cs:[x],ax
	
	pop dx
	
	pop cx
	pop ax							; pobranie zoomu ze stosu
	cmp ax,1
	je psh
	dec ax
	push ax							; wrzucenie na stos zmniejszonego zoomu, jeśli był większy od zera
	push cx
	jmp mop
	
psh:
	push dx						
	push cx
	jmp om


mop:
	mov cx,-1 							; powrót na początek danej linii w pliku
	mov dx,-10
	mov ah,42h
	mov al, 1h
	int 21h
	jc err
	jmp om
	
addx:
	pop dx
	add word ptr cs:[x],1
	dec dx
	push dx
	cmp dx,0
	jne addx
	
	pop dx
om:	
	pop cx
	dec cx
	cmp cx,0
	jne rysuj
	
	
	
	;KONIEC PĘTLI WYŚWIETLAJĄCEJ LITERĘ Z BITMAPY
	pop ax
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	push ax
	
	mov cx,8
	mul cx
	sub word ptr cs:[y],ax				; wraca do numeru wiersza sprzed dodania litery
	
	pop ax
	mov cx, 9
	mul cx
	add word ptr cs:[x],ax
	inc di
	

	mov cx,0							; powrót na początek pliku z literkami - bitmapami
	mov dx,0
	mov ah,42h
	mov al, 0h
	int 21h
	jc err
	
	
	pop cx
	dec cx
	cmp cx,0
	jne wezlitere						; jeśli cx nie jest zerem, to skacz (działa jak loop, ale loop wyrzucał error A2075)
	
	;KONIEC PĘTLI ZNAJDUJĄCEJ KOLEJNE LITERY Z WEJŚCIA
	
	
	
	xor ax,ax								;oczekiwanie na dowolny klawisz
	int 16h
	
	
	;ZAMKNIĘCIE PLIKU Z LITERAMI
	
	mov ah, 3eh
	int 21h
	jc err
	
zam:	
	mov al,3h								; przywrócenie normalnego trybu tekstowego
	mov ah,0
	int 10h
	
	
	mov al, 0
	mov ah, 04ch
	int 21h	
	

;----------------------procedury----------------------

wypisz:
	mov ax, cs
	mov ds, ax
	mov ah,9
	int 21h
	ret	

zapal:
	mov ax, 0a000h 								; adres segmentowy pamięci obrazu
	mov es,ax
	mov ax,word ptr cs:[y]
	push bx
	mov bx,320 
	mul bx										;dx:ax=ax*bx=320*y
	
	mov bx,word ptr cs:[x] 						; bx=x, ax=320*y
	add bx,ax									; bx=320*y+x
	mov al, byte ptr cs:[k]						; do al numer koloru
	mov byte ptr es:[bx],al						; zapal: piksel w es (tam adres segmentowy pamięci obrazu) o offsecie bx ma kolor al
	pop bx
	ret

znajdzmape:
	call poznaku
	
	mov al, byte ptr cs:[di]
	cmp byte ptr cs:[lit], al
	jne znajdzmape
	ret
	

poznaku:
	mov cx,1
	mov ax, cs		
	mov ds, ax
	mov dx, offset lit
	mov ah, 3fh					
	int 21h
	jc err
	ret
	
check:
	mov es,ax
	mov cx,9
	mul cx
	add ax,word ptr cs:[x]
	cmp ax, 320
	jnb hop1
	jmp r
	
hop1: call nwiersz
	
r:	ret

nwiersz:
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	mov cx, 9
	mul cx
	add word ptr cs:[y],ax
	
	mov word ptr cs:[x],0
	ret

checkline:
	;cmp word ptr cs:[x],ax
	;jnb hsub
	
	;sub word ptr cs:[y],ax
	
	;sub ax, word ptr cs:[x]
	;mov word ptr cs:[x], 319
	;sub word ptr cs:[x],ax
	
	;pop ax
	;push ax
	;mov cx, 8
	;mul cx
	;sub word ptr cs:[y],ax
	;sub word ptr cs:[y],1
	;jmp powr

hsub:
	sub word ptr cs:[x],ax
powr:
	ret

spac1:
	inc si
	dec cx
	jmp spr

err:
	mov dx, offset errend					;wypisanie informacji, że proces zakończył się z błędem i skok do zamknięcia programu
	call wypisz
	jmp zam

;-----------------------zmienne----------------------	

map db "letters.txt",0
lit db 8 dup('$')
zoom db 1 dup(0)
buf db 256 dup('$') 
errend db "program zakonczyl sie z bledem",'$'

x dw ? 
y dw ?
k dw 14

code1 ends



stos1 segment stack
	dw 100 dup(?)
	top1 dw ?
stos1 ends

end start1