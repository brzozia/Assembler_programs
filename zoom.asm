; Natalia Brzozowska

; Program przyjmuje jako argumenty: cyfrę oraz tekst
; Spacje przed pierwszym argumentem są pomijane
; Tekst rozpoczyna się dwa znaki po znaku cyfry i kończy, gdy kończą się argumenty
; Zmienne znajdują się w kodzie
; Aby uruchomić program należy wpisać argumenty i nacisnąć ENTER

code1 segment
start1:

	mov ax, seg top1
	mov ss, ax 
	mov sp, offset top1
	
	
;----CZYTANIE PARAMETRÓW WYWOŁANIA-------------------------------------------
	
	mov si, 82h				
	mov di, offset zoom					; ustawienie offsetu zmiennej zoom do di - zoom to zmienna przechowująca cyfrę powiększenia
	
	mov cx, 0				  			
	mov cl, byte ptr ds:[80h] 			; przekazanie do cl ilości znaków wpisanych w konsoli

spr:									; pomijanie spacji przed pierwszym argumentem
	cmp byte ptr ds:[si],' '
	je spac1
	
	mov al, byte ptr ds:[si]			 
	mov byte ptr cs:[di],al				; zapisanie cyfry w zmiennej
	add si,2							; następnym znakiem powinna być spacja - 
										; - pomijam ją i zaczynam czytać tekst od następnego znaku, aż do końca
	
	
	sub cx,3 							; zmniejszenie cx tyle razy ile znaków już zostało ominiętych +1 - na 13 na końcu wejścia
	
	mov di, offset buf					; przekazanie offsetu bufora do di, żeby zapisywać przeczytane znaki do bufora
	push cx								; wrzucenie ilość znaków tekstu na stos 

czy: 									; pętla, w której czytane są znaki do końca wejścia i zapisywane w buf
	mov al, byte ptr ds:[si]
	mov byte ptr cs:[di],al
	inc si
	inc di
	
	loop czy
	
	
	
;----WŁĄCZENIE TRYBU GRAFICZNEGO-------------------------------------------

;ent:									; odkomentowanie tego fragmentu spowoduje oczekiwanie na klawisz ENTER, po naciśnięciu ENTERa 'zatwierdzającego' wpisane argumenty
										; nie wydaje mi się konieczne używanie takiej konstrukcji, jednak można ją dołączyć
	;mov ah,0							; oczekiwanie na ENTER
	;mov al,13h
	;int 16h
	
	;cmp al,13							; jeśli wciśnięty znak nie był ENTERem to oczekuje dalej
	;jne ent
	
	
	mov al,13h							; tryb graficzny 320x200, 256 kolorów
	mov ah,0							; zmiana trybu karty VGA
	int 10h								; przerwanie BIOS
	
	pop cx
	
	
;----OTWARCIE PLIKU Z BITMAPAMI LITER---------------------------------------
	
	mov ax, cs		
	mov ds, ax
	mov dx, offset map					; przekazanie offsetu zmiennej zawierającej nazwę pliku
	mov al, 0							; 0 znaczy ze tylko do odczytu
	mov ah, 3dh							; otwarcie pliku z ds:dx
	int 21h
	jc err								; niepoprawne otwarcie spowoduje wypisanie informacji o błędnym zakończeniu i zakończeniem programu
	mov bx,ax							; przez prawie cały czas trwania programu w rejestrze bx będzie znajdował się handler do pliku
	
	
	
;----RYSOWANIE LITER-------------------------------------------------------
	
	mov di, offset buf
	mov word ptr cs:[y],0				; wyzerowanie współrzędnych x i y
	mov word ptr cs:[x],0				; x - kolumna, y - wiersz 
	
	
	
;----PĘTLA ZNAJDUJĄCA KOLEJNE LITERY Z WEJŚCIA-----------------------------
	
wezlitere:	
	push cx
		
	call znajdzmape						; szukanie w pliku z bitmapami liter litery, którą będziemy wypisywać
	call poznaku 						; ominięcie znaku 13, po sumpolu litery w pliku
	call poznaku						; i znaku 10
	
	
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h							; zapisanie w rejestrze al decymalnie wartości zmiennej zoom
	
	push ax								; wrzucenie wartości zoom na stos
	
	call check							; sprawdzenie, czy następna litera zmieści się na ekranie - jeśli nie 'zawinięcie' tekstu do nowej linii
	
	
	mov ax, 80							; 64 znaki '0' lub '1' +16 znaków 10 i 13 - ilość ileracji, żeby odczytać całą bitmapę litery
	pop cx								; pobranie wartości powiększenia
	push cx	
	mul cx								; pomnożenie ilości iteracji przez powiększenie - otrzymanie ilości iteracji potrzebnych do wyświetlenia powiększonej litery
	mov cx,ax							; przekazanie tej wartości do cx	
	
	
	
;----PĘTLA WYŚWIETLAJĄCA LITERĘ Z BITMAPY---------------------------------

rysuj:
	push cx
	call poznaku						; czytanie bitmapy po znaku (najpierw wiersze)
	cmp byte ptr cs:[lit], '1'
	jne cmpe							; jeśli znak jest różny od 1 to skacze do instrukcji pod etykietą cmpe
	
	mov ah,0 							; jeśli znak jest równy 1 to zostanie wyświetlony
	mov al,byte ptr cs:[zoom]
	sub al,30h
	mov dx,ax							; zapisanie w dx powiększenia
xlop:									; pętla zapalająca odpowiednią ilość pikseli dla danego powiększenia, w danym wierszu
	push dx
	call zapal							; zapalenie piksela
	pop dx
	add word ptr cs:[x],1				; zwiększenie współrzędnej x-owej
	
	dec dx								; pętla wykona się tyle razy ile nakazuje powiększenie ( dla zoom=2, wykona się 2 razy)
	cmp dx,0
	jne xlop
	jmp om						


cmpe:
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	push ax								; wrzucenie na stos wartości powiększenia
	
	cmp byte ptr cs:[lit],10			; jeśli pobrany znak jest równy 10, oznacza to, że zakończyliśmy wyświetlanie danego wiersza bitmapy
	jne addx							; jeśli nie jest to 0 lub 13, które traktujemy tak samo - nie zapalamy ich
	
	add word ptr cs:[y],1				; zwiększenie współrzędnej y - przejście do nowego wiersza na ekranie
	
	pop ax								; pobranie wartości powiększenia ze stosu
	push ax						
	mov cx,9							; 8 bitów litery + 1 bit '13' - daje 9 pikseli, przy powiększeniu równym 1
	mul cx								; ustalenie liczby pikseli przy podanym powiększeniu
	sub word ptr cs:[x],ax				; cofnięcie współrzędnej x-owej na początek nowego wiersza
	
	pop dx								; pobranie wartości powiększenia ze stosu
	
	pop cx
	pop ax								; pobranie wartości zoomu, która mówi ile razy musimy powrórzyć dany wiersz dla danego powiększenia (dla zoom=2, jeden wiersz wyświetlamy 2 razy)
	cmp ax,1
	je psh								; jeśli dany wiersz został wyświetlony odpowiednią ilość razy to idziemy do następnego
	dec ax								; jeśli nie zmniejszamy ax i wrzucamy na stos
	push ax						
	push cx
	jmp mop								; skoro nalezy dany wiersz wyśiwetlić jeszcze raz, trzeba w pliku przesunąć wskaźnik na początek tego wiersza
	
psh:
	push dx								; wrzucenie na stos wartości powiększenia
	push cx
	jmp om


mop:
	mov cx,-1 							; powrót na początek danego wiersza w pliku
	mov dx,-10
	mov ah,42h
	mov al, 1h
	int 21h
	jc err
	jmp om
	
addx:									; zwiększenie współrzędnej x o powiększenie - bez zapalania (dla 0,13)
	pop dx
	add word ptr cs:[x],dx

om:	
	pop cx
	dec cx								; zmniejszenie ilość operacji do wykonania i wrzucenie na stos
	cmp cx,0
	jne rysuj							; jeśli pozostały jeszcze jakieś operacje do wykonania do powtórzenie instrukcji od etykiety 'zapal'
	
	
	
;----KONIEC PĘTLI WYŚWIETLAJĄCEJ LITERĘ Z BITMAPY--------------------------

	pop ax
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h
	push ax								; obliczenie i wrzucenie na stos wartości powiększenia
	
	mov cx,8							; po przeczytaniu jednej litery trzeba wrócić do pierwszego wiersza, z którego ta litera się zaczęła, by obok niej zacząć wyświetlać kolejną lietrę
	mul cx								; obliczenie ilości zajmowanych wierszy przez poprzednią literę, z uwzględnieniem powiększenia
	sub word ptr cs:[y],ax				; powrót do numeru wiersza sprzed dodania litery
	
	pop ax								; pobranie wartości powiększenia ze stosu
	mov cx, 9
	mul cx
	add word ptr cs:[x],ax				; zwiększenie współrzędnej x-owej, tak by wskazywała na miejsce rozpoczęcia wyświetlanie nowej litery (w pętli rysuj, po znaku 10, x został zmniejszony)
	inc di								; zwiększenie wskaźnika di, by wskazywał na kolejną literę
	
	mov cx,0							; powrót na początek pliku z literkami - bitmapami
	mov dx,0
	mov ah,42h
	mov al, 0h
	int 21h
	jc err
	
	
	pop cx
	dec cx								; pobranie i zmniejszenie ilości obiegów, które powinna wykonać pętla
	cmp cx,0
	jne wezlitere						; jeśli cx nie jest zerem, to wykonuje operacje od wtykiety 'wezlitere' raz jeszcze
	
;----KONIEC PĘTLI ZNAJDUJĄCEJ KOLEJNE LITERY Z WEJŚCIA-------------------
	
	
	xor ax,ax							; oczekiwanie na dowolny klawisz
	int 16h
	
	
;----ZAMKNIĘCIE PLIKU Z LITERAMI-----------------------------------------
	
	mov ah, 3eh							; zamknięcie pliku z literami
	int 21h								; w bx znajduje się handler do pliku
	jc err
	
zam:	
	mov al,3h							; przywrócenie normalnego trybu tekstowego
	mov ah,0
	int 10h
	
	
	mov al, 0							; zakończenie programu
	mov ah, 04ch
	int 21h	
	

;----------------------procedury---------------------------------------

wypisz:									; wypisuje napis w konsoli
	mov ax, cs
	mov ds, ax
	mov ah,9
	int 21h
	ret	

zapal:									; zapala piksel o współrzędnych w x i y
	mov ax, 0a000h 						; adres segmentowy pamięci obrazu
	mov es,ax
	mov ax,word ptr cs:[y]
	push bx								; wrzucenie na stos handlera do pliku
	mov bx,320 
	mul bx								;dx:ax=ax*bx=320*y
	
	mov bx,word ptr cs:[x] 				; bx=x, ax=320*y
	add bx,ax							; bx=320*y+x - obliczenie współrzędnej na podstawie x i y
	mov al, byte ptr cs:[k]				; do al numer koloru
	mov byte ptr es:[bx],al				; piksel w es (tam adres segmentowy pamięci obrazu) o offsecie bx dostaje kolor al
	pop bx								; pobranie ze stosu handlera do pliku
	ret

znajdzmape:								; znajduje w pliku bitmapę litery
	call poznaku
	
	mov al, byte ptr cs:[di]
	cmp byte ptr cs:[lit], al			; jeśli znaleziony znak nie jest równy znakowi w zmiennej buf, to szuka dalej
	jne znajdzmape
	ret
	

poznaku:								; czyta po znaku z pliku i zapisuje go do zmiennej 'lit'	
	mov cx,1
	mov ax, cs		
	mov ds, ax
	mov dx, offset lit
	mov ah, 3fh					
	int 21h
	ret



check:									; sprawdza, czy zapalenie kolejnej litery spowoduje wyjście poza zakres ekranu
	mov es,ax
	mov cx,9
	mul cx
	add ax,word ptr cs:[x]				; dodanie szerokości litery, aktualnej wartości x
	cmp ax, 320							; sprawdzenie czy ta wartość przekracza wymiary
	jnb hop1							; jeśli wartość w rejestrze ax jest większa lub równa 320, to skacze do etykiety 'hop1'
	jmp r								; jeśli nie - wróć 
	
hop1: call nwiersz						; wywołanie przeniesienia do nowego 'wiersza' na ekranie ('zawinięcia' tesktu)
	
r:	ret

nwiersz:								; 'zawija' tekst
	mov ah,0 
	mov al,byte ptr cs:[zoom]
	sub al,30h							; zapisanie w al powiększenia
	mov cx, 9
	mul cx								; obliczenie o ile musi przesunąć się współrzędna y
	add word ptr cs:[y],ax				; przesunięcie współrzędnej y
	
	mov word ptr cs:[x],0				; w nowym 'wierszu' wartość współrzędnej x będzie równa 0
	ret


spac1:									; pomija spacje (przed pierwszym argumentem)
	inc si
	dec cx
	jmp spr

err:
	mov dx, offset errend				; wypisuje informacje, że proces zakończył się z błędem i zamyka program
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