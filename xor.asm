;czytamy tresc od " do " i tak bedzie fajnie, jak nie bedzie końcowegoo cudzysłowu to jakiś błąd

;algorytm:
;
;uruchamia program z argumentami: plikiem wej, plikiem wyj, kluczem do szyfrowania
;w programie:
;(trzeba zrobic jakas petle zeby pomijala spacje i taby piedzy argumentami)
;zczytuje nazwe pliku wejsciowego i zapisuje do zmiennej (wszytskie zmienne mozna w segmencie kodu trzymac, bo to maly program, 
;a do rejestrow zapisac zobie wartosc pliku np)

;zczytuje nazwe pliku wyjsciowego i zapisuje do zmiennej
;zczytuje klucz i zapisuje do zmiennej tresc (na koncu bedzie enter - powrot karetki - 13 -wtedy w kodzie moze byc " )
;(jakies info trzeba wyrzucac jak zle zargumenty np)
;
;otwiera plik i do jakiegos bufora czyta kod do zaszyfrowania
;(jak plik pusty albo cos to tez bledy)
;
;robimy xor'a
;jakas zmienna mowiaca ile razy pelny klucz zmiesci sie w slowie -> cx -> po tym petla
;mozna od razu do pliku wyjsciowego zapisywac i dopisywac kolejne chyba 
;jakas inna mowiaca ile znakow zaostanie na koncu -> po petli xor na tej reszcie znakow
;tez dopisz do pliku wyjsciowego   
;
;zamknij plik czy cos tam i koniec

;--------------------------------------------------------------------------

data1 segment

wej db 30 dup(0),'$'
wyj db 30 dup(0),'$'
klucz db 30 dup(0),'$'
buf db 201 dup('$') 			
wsk1 dw ?
nlinia db 10,13,'$'
pozend db "program zakonczyl sie poprawnie",'$'
errend db "program zakonczyl sie z bledem",'$'

data1 ends

code1 segment
start1:
	mov ax, seg top1
	mov ss, ax 
	mov sp, offset top1


	;KOPIOWANIE ARGUMENTÓW DO ZMIENNYCH - BEZ PIERWSZEJ SPACJI PO NAZWIE PROGRAMU
	
	mov si, 82h				
	mov ax, seg wej				;pierwszy argument jest nazwą pliku wejściowego. Zapisujemy go do 'zmiennej' wej
	mov es, ax
	mov di, offset wej
	
	mov cx, 0				  ; petla <- zerowanie cx-licznik
	mov cl, byte ptr ds:[80h] ;pod 80h jest ilosc znakow
	mov dl,0					; potrzebny licznik do liczenia spacji
	mov dh,0					; licznik cudzysłowiów
	
	
spr:							;pomijanie spacji przed pierwszym argumentem
	cmp byte ptr ds:[si],' '
	je spac1

lo:	push cx 				; wysyla na stos komorki rejestru-licznika
	
	mov al, byte ptr ds:[si];pobranie pierwszego znaku z linii komend
	cmp al, ' '				;porównaj wczytane znak ze spacją
	je cc					; jeśli wczytany znak jest spacją to skocz do miejsca z etykietą cc 'jump if equal'
	cmp al, 9				;porównaj wczytane znak z tabulaturą
	je cc					; jeśli wczytany znak jest tabulaturą to skocz do miejsca z etykietą cc 'jump if equal' - omija dodanie 
	cmp al, 34
	je cudz
	cmp al,13				; na końcu wejścia znajduje się 13 - przejście na początek linii. Jeśli tam dojdziemy wychodzimy z pętli (coś w rodzaju 'break')
	je en
re:	mov byte ptr es:[di], al  
	inc di
	
	jmp po
cc:	jmp copy
po:	inc si					;to samo co add di,1
	
	mov ah,al				; w ah zapisuje znak, żeby w następnym obrocie móc sprawdzić, czy była tam spacja
	pop cx
	loop lo					; WEJSCIE ZAPISANE W BUFORZE
	
	
en:  mov cx, 0				  ; petla <- zerowanie cx-licznik
	mov al,'$'
	mov byte ptr es:[di], al  ; na koncu klucza daje snak '$', żeby wiedzieć, gdzie jest koniec napisu
	
	
	
	
	
	;OTWARCIE PLIKU WEJŚCIOWEGO
	
	mov ax, seg wej			
	mov ds, ax
	mov dx, offset wej
	mov al, 0					; 0 znaczy ze tylko do odczytu
	mov ah, 3dh					; otwarcie pliku z ds:dx
	int 21h
	jc err
	push ax
	
	;OTWARCIE PLIKU WYJŚCIOWEGO
	
	mov ax, seg wyj			
	mov ds, ax
	mov dx, offset wyj
	mov al, 1					; 1 znaczy ze tylko do zapisu
	mov ah, 3dh					; otwarcie pliku z ds:dx
	int 21h
	jc err
	push ax
	
	mov ax,0
	push ax
	
	;CZYTANIE Z PLIKU WEJŚCIOWEGO - 200 ZNAKÓW
	
czyt:
	pop cx
	pop ax						;pobiera handler pliku wyj
	mov es,ax					;zapisuje go w es
	pop ax						;pobiera handler pliku wej
	push ax						;wrzuca go znowu na stos
	push es						;wrzuca na niego handler do pliku wyj
	push cx
	
	mov word ptr ds:[wsk1], ax
	mov bx, word ptr ds:[wsk1]
	mov cx, 200				; do licznika 200, zeby odczytac 200 znakow
	mov ax, seg buf
	mov ds, ax
	mov dx, offset buf			; ds:[dx] -> buf
	mov ah, 3fh					; odczytac plik do 250 znakow (jak jest mniej znakow to info o bledzie idzie do flagi)
	int 21h
	jc err
	mov cx, ax 					; przenieś liczbę przeczytanych znaków z ax do cx
	
	pop ax
	push cx 					; wrzuca na stos liczbę przeczytanych znaków z pliku wejściowego
	

	
	;SZYFROWANIE XOR
	
	cmp ax,1
	je et
	
	mov si, offset klucz

et:	
	mov ax, seg klucz
	mov ds, ax
	
	mov ax, seg buf
	mov es, ax
	mov di, offset buf
	
	pop cx
	push cx
	
lo2:
	push cx
	cmp byte ptr ds:[si], '$' 			; jeśli doszliśmy do końca klucza, skocz do funkcji, która przesunie 'wskaźnik' w kluczu na pierwszy znak klucza
	je lop
pop1:
	mov al, byte ptr ds:[si]
	xor byte ptr es:[di], al
	inc di
	inc si
	
	pop cx
	loop lo2



	
	pop cx ;zbiera ze stosu liczbe przeczytanych znaków z pliku wejściowego

	
	;PISANIE DO PLIKU WYJŚCIOWEGO - ILOŚĆ ZNAKÓW RÓWNA CX
	
	pop ax
	mov bx, ax	
	push ax
	mov ax, seg wyj			
	mov ds, ax	
	mov ah, 40h
	mov dx, offset buf
	int 21h
	jc err
	
	
	cmp cx, 199 			; jeśli liczba przeczytanych znaków jest mniejsza niż 199 (jednorazowo pobieram 200 znaków) to znaczy, że osiągnęliśmy koniec pliku
	jb zamk
	
	mov ax,1
	push ax					; by wiedzieć czy to kolejny obrót
	jmp czyt 						;skocz czytać dalszą częśc pliku
	
zamk:	
	
	;ZAMKNIĘCIE PLIKU WYJ
	
	pop ax
	mov bx, ax	
	mov ah, 3eh
	int 21h
	jc err
	
	
	;ZAMKNIĘCIE PLIKU WEJ
	
	pop ax
	mov bx, ax	; zamkniecie pliku
	mov ah, 3eh
	int 21h
	jc err
	
	;WYPISANIE WCZYTANYCH DANYCH
	
	mov dx,offset wej 		
	call wypisz				;wypisuje to co jest aktualnie w ds:dx
	mov dx,offset nlinia
	call wypisz
	
	mov dx, offset wyj
	call wypisz
	mov dx,offset nlinia
	call wypisz
	
	mov dx, offset klucz
	call wypisz
	mov dx,offset nlinia
	call wypisz
	
	
	;WYPISANIE INFORMACJI, ŻE PROCES ZAKOŃCZYŁ SIĘ POPRAWNIE 
	;(jeśli wystąpił błąd, nastąpił skok do etykiery err -> tam wypisywana jest informacja o niepoprawnym zakończeniu)
	
	mov dx, offset pozend	
	call wypisz
	
zam:	
	mov al, 0
	mov ah, 04ch
	int 21h					; koniec programu


;----------------procedury-----------
wypisz:
	mov ax, seg data1
	mov ds, ax
	mov ah,9
	int 21h
	ret						;wypisuje to co jest w ds:dx aktualnie

copy:						;jeśli weszliśmy tu z powodu kolejnej spacji między argumentami to zostanie ona zignorowana i przeniesiemy się
	cmp dh,1
	je re
	cmp dl,0
	je copywyj
	jmp po					; jeśli nic się nie 'zgodzi' wróc do pętli do etykiety 'po'

copywyj:
	mov di, offset wyj
	mov dl,1
	jmp po

copyklucz:
	mov di, offset klucz
	inc dh
	jmp po

cudz:
	cmp dh,0
	je copyklucz
	cmp dh,1
	je en

lop:
	mov si, offset klucz
	jmp pop1

spac1:
	inc si
	jmp spr

err:
	mov dx, offset errend					;wypisanie informacji, że proces zakończył się z błędem i skok do zamknięcia programu
	call wypisz
	jmp zam

code1 ends


stos1 segment stack
	dw 100 dup(?)
	top1 dw ?
stos1 ends

end start1
