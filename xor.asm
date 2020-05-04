; Natalia Brzozowska

; Program przyjmuje trzy argumenty: nazwę pliku wejściowego, nazwę pliku wyjściowego, oraz klucz zawarty w cudzysłowie
; Jeśli plik wejściowy o podanej nazwie nie istnieje, program zwróci informację o nieprawidłowym zakończeniu programu i zakończy działanie
; Jeśli przy otwieraniu pliku wyjściowego o podanej nazwie, zostanie zwrócony błąd otwarcia pliku, to zostanie utworzony nowy plik o tej nazwie
; Jeśli w arumentach wejściowych nie będzie dwóch cudzysłowów, to również program zakończy się z informacją o błędnym zakończeniu
; Spacje pomiędzy argumentami są pomijane
; Kluczem jest ekst zawarty pomiędzy cudzysłowami (cudzysłowia się 'nie liczą')
 
; Program czyta 200 znaków z pliku wejściowego, szyfruje z kluczem, zapisuje do pliku wyjściowego, po czym czyta kolejne 200 znaków
; Po kolejnym pobraniu znaków szyfruje je zaczynając od kolejnej litery w kluczu na której skończył (tak, żeby ktoś, kto pobiera w swoim programie inną liczbę znaków, nie miał problemów z rozszyfrowaniem)

;--------------------------------------------------------------------------

data1 segment

wej db 30 dup(0),'$'				; '$' na końcach, żeby ładnie wypisywać
wyj db 30 dup(0),'$'
klucz db 50 dup('$')
buf db 201 dup('$')
nlinia db 10,13,'$'
pozend db "program zakonczyl sie poprawnie",'$'
errend db "program zakonczyl sie z bledem",'$'

data1 ends

code1 segment
start1:
	mov ax, seg top1
	mov ss, ax 
	mov sp, offset top1


;--------KOPIOWANIE ARGUMENTÓW DO ZMIENNYCH--------------------------
	
	mov si, 82h				
	mov ax, seg wej				
	mov es, ax
	mov di, offset wej				; pierwszy argument jest nazwą pliku wejściowego. Zapisujemy go do zmiennej 'wej'
	
	mov cx, 0				  		; zerowanie cx - licznika pętli
	mov cl, byte ptr ds:[80h] 		; pobranie ilość wpisanych znaków
	mov dl,0						; licznik spacji
	mov dh,0						; licznik cudzysłowów
	
	
spr:								; pomijanie spacji przed pierwszym argumentem
	cmp byte ptr ds:[si],' '
	je spac1
	
	cmp cx,0						; sprawdzenie czy zostały wpisane jakieś znaki poza wcześniej pominiętymi spacjami
	je err							; jeśli nie - wyświetla błąd i kończy program
	
lo:							
	mov al, byte ptr ds:[si]		; pobranie pierwszego znaku z linii komend
	cmp al, ' '						; porównanie wczytanego znaku ze spacją
	je cc							; jeśli wczytany znak jest spacją to skocz do miejsca z etykietą cc
	cmp al, 9						; porównanie wczytanego znaku z tabulaturą
	je cc							; jeśli wczytany znak jest tabulaturą to skocz do miejsca z etykietą cc
	cmp al, 34						
	je cudz							; jeśli wczytany znak jest cudysłowem to skocz do miejsca z etykietą cudz
	cmp al, 13						; na końcu wejścia znajduje się 13 - przejście na początek linii. Jeśli tam dojdziemy wychodzimy z pętli.
	je en
re:	mov byte ptr es:[di], al  		; zapisanie wczyanego znaku w odpowiednim miejscu w pamięci - w odpowiedniej zmiennej
	inc di
	
	jmp po
cc:	jmp copy
po:	inc si					
	
	mov ah,al						; zapisanie znaku w ah, żeby w następnym obrocie móc sprawdzić, czy była tam spacja (sprawdzanie w procedurach opisanych na końcu kodu)
	loop lo					
	
	
en:  				  				; koniec pętli
	
	
	
;-----SPRAWDZENIE DANYCH WEJŚCIOWYCH-------------------------------
	
	cmp dh,1						; jeśli nie było dwóch cudzysłowów, to wyświetl błąd i zakończ
	jne err
	
	mov ax, seg wyj
	mov ds,ax
	mov di, offset wyj				; plik o nazwie zaczynającej się od 0 jest traktowany jako niepoprawny
	cmp byte ptr ds:[di],'0'		; (również, gdy nie zostanie podana nazwa pliky wyjściowego, na początku nazwy pliku będzie 0)
	je err							; wtedy zostanie zwrócona informacja o błędzie i program zostanie zamknięty
	
	
;------OTWARCIE PLIKU WEJŚCIOWEGO----------------------------------
	
	mov ax, seg wej			
	mov ds, ax
	mov dx, offset wej
	mov al, 0						; 0 oznacza, że tylko do odczytu
	mov ah, 3dh						; otwarcie pliku z ds:dx
	int 21h
	jc err 							; jeśli nie da sie otworzyć pliku to zwróć informację o błędzie i zamyknij program
	push ax							; wrzucenie handlera do pliku na stos



;-------OTWARCIE PLIKU WYJŚCIOWEGO---------------------------------
	
	mov ax, seg wyj			
	mov ds, ax
	mov dx, offset wyj
	mov al, 1						; 1 znaczy ze tylko do zapisu
	mov ah, 3dh						; otwarcie pliku z ds:dx
	int 21h
	jc crjmp2						; jeśli pojawił się błąd otwarcia, to tworzy nowy plik wyjściowy o podanej nazwie (procedura create)
	jmp psh2
crjmp2: call create
psh2:
	push ax							; wrzucenie handlera do pliku na stos
	
	mov ax,0
	push ax							; wrzucenie znaku na stos, w celu utrzymania później poprawnej kolejności w pętlach 
									; (ta wartość zostanie później głównie zastąpiona ilością przeczytanych bajtów)
	
	

;-------CZYTANIE Z PLIKU WEJŚCIOWEGO - 200 ZNAKÓW------------------
	
czyt:
	pop cx
	pop ax							; pobranie handlera pliku wyjściowego
	mov es,ax						
	pop ax							; pobranie handlera pliku wejściowego
	push ax							; wrzucenie go znowu na stos
	push es							; wrzucenie na niego handlera do pliku wyjściowego
	push cx
	
	mov bx, ax						; zapisanie do bx handlera pliku wejściowego
	mov cx, 200						; do licznika 200, żeby odczytać 200 znaków
	mov ax, seg buf
	mov ds, ax
	mov dx, offset buf				; ds:[dx] -> buf
	mov ah, 3fh						; odczytanie z pliku do 200 znakow (jak odczyta mniej znaków to informacja o błedzie zostanie zapisane we fladze)
	int 21h
	jc err							; jeśli wystąpi błąd to zostanie zwrócona informacja o błędnym zakończeniu i program zostanie zamknięty
	mov cx, ax 						; przeniesienie liczby przeczytanych znaków z ax do cx
	
	pop ax							; pobranie wcześniejszego elementu ze stosu oznaczającego ilość przeczytanych znaków
	push cx 						; wrzucenie na stos liczby przeczytanych 'przed chwilą' znaków z pliku wejściowego

	
;-------SZYFROWANIE XOR-------------------------------------------
	
	cmp ax,1						; jeśli ax zostało ustawione na 1, to przeskakujemy ustawienie offsetu klucza na nowo,
	je et							; po to, by zacząć szyfrować następną partię znaków nie od początku klucza, ale od znaku, na którym skończyliśmy 
	
	mov si, offset klucz			; si będzie wskazywał na znaki klucza

et:	
	mov ax, seg klucz
	mov ds, ax
	
	mov ax, seg buf
	mov es, ax
	mov di, offset buf				; di będzie wskazywał na znaki bufora - znaki pobrane z pliku
	
	pop cx
	push cx							; zapisanie liczby pobranych znaków z pliku w cx
	
lo2:								; pętla główna szyfrowania - w niej odbywa się iterowanie po znakach bufora
	push cx
	cmp byte ptr ds:[si], '$' 		
	je lop							; jeśli doszliśmy do końca klucza, skacze do funkcji, która przesunie wskaźnik si w kluczu na pierwszy znak klucza (w procedurach)

pop1:
	mov al, byte ptr ds:[si]
	xor byte ptr es:[di], al		; xor znaków bufora i klucza
	inc di
	inc si
	
	pop cx
	loop lo2



	
	pop cx 							; zabranie ze stosu liczby przeczytanych znaków z pliku wejściowego

	
;--------PISANIE DO PLIKU WYJŚCIOWEGO - ILOŚĆ ZNAKÓW RÓWNA CX------------
	
	pop ax							; ściągnięcie ze stosu handlera do pliku wyjściowego
	mov bx, ax						; zapisanie handlera w bx
	push ax							; wrzucenie handlera na stos
	mov ax, seg wyj			
	mov ds, ax	
	mov ah, 40h						; zapisanie do pliku, którego handler znajduje się w bx, znaków z ds:dx w ilości określonej w cx
	mov dx, offset buf
	int 21h
	jc err							; jeśli wystąpi błąd to zostanie zwrócona informacja o błędnym zakończeniu i program zostanie zamknięty
	
	
	cmp cx, 199 					; jeśli liczba przeczytanych znaków jest mniejsza niż 199 (jednorazowo pobieranych jest 200 znaków) to znaczy, że osiągnęliśmy koniec pliku
	jb zamk							; skok do instrukcji zamykających pliki i program
	
	mov ax,1						; ustawienie ax równego 1, po to by nie wykonywać xor'a od pierwszego znaku klucza
	push ax							; wrzucenie ax na stos
	jmp czyt 						; skok do czytania kolejnych znaków z pliku
	


;--------ZAMKNIĘCIE PLIKU WYJ-------------------------------------------
	
zamk:
	
	pop ax							; ściągnięcie handlera do pliku wyjściowego
	mov bx, ax	
	mov ah, 3eh
	int 21h 						; zamkniecie pliku

	
	
;-------ZAMKNIĘCIE PLIKU WEJ--------------------------------------------
	
	pop ax							; ściągnięcie handlera do pliku wejściowego
	mov bx, ax	
	mov ah, 3eh
	int 21h							; zamkniecie pliku

	
;--------WYPISANIE WCZYTANYCH DANYCH-----------------------------------
	
	mov dx,offset wej 		
	call wypisz						; wypisanie tego co jest aktualnie w ds:dx
	mov dx,offset nlinia			; po każdym ciągu znaków wypisywana jest 'nowa linia' - znaki 10,13,'$'
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

;--------ZAMKNIĘCIE PROGRAMU--------------------------------------------

zam:	
	mov al, 0
	mov ah, 04ch
	int 21h							; koniec programu


;------------procedury--------------------------------------------------
wypisz:								; wypisanie tego co jest aktualnie w ds:dx
	mov ax, seg data1
	mov ds, ax
	mov ah,9
	int 21h
	ret						

copy:						;jeśli weszliśmy tu z powodu kolejnej spacji między argumentami to zostanie ona zignorowana i przeniesiemy się
	cmp dh,1
	je re
	cmp dl,0
	je copywyj
	jmp po					; jeśli nic się nie 'zgodzi' wróć do pętli do etykiety 'po'

copywyj:					; ustawnienie w di offsetu zmiennej 'wyj', po to by zapisywać do niej kolejne wczytane znaki
	mov di, offset wyj
	mov dl,1				; ustawienie licznika spacji na 1
	jmp po

copyklucz:					; ustawnienie w di offsetu zmiennej 'klucz', po to by zapisywać do niej kolejne wczytane znaki
	mov di, offset klucz
	inc dh					; zwiększenie licznika cudzysłowów 
	jmp po

cudz:						; decyduje czy rozpocząć czytanie klucza, czy zakończyć czytanie klucza
	cmp dh,0				; jeśli wystąpił pierwszy cudzysłów, rozpoczyna czytanie klucza
	je copyklucz
	cmp dh,1				; jeśli wystąpił drugi cudzysłów, kończy czytanie klucza
	je en					; i kończy pętlę czytającą argumenty

lop:						; przesuwa wskaźnik si w kluczu na pierwszy znak klucza
	mov si, offset klucz
	jmp pop1

spac1:						; jeśli pojawiła się spacja to zwiększa wskaźnik si, żeby czytać kolejne znaki (w argumentach programu)
	inc si
	jmp spr

create:						; tworzy nowy plik
	mov al, 0					
	mov ah, 3ch					
	int 21h
	ret

err:
	mov dx, offset errend	;wypisuje informacje, że proces zakończył się z błędem i skacze do zamknięcia programu
	call wypisz
	jmp zam

code1 ends


stos1 segment stack
	dw 100 dup(?)
	top1 dw ?
stos1 ends

end start1
