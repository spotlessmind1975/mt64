        ; *********************************************************************
        ; *** MULTITASKING SCHEDULER INSTALLER
        ; *********************************************************************
        ; Scritto da Marco Spedaletti (asimov@mclink.it)
        ;
        ; file: https://iwashere.eu/asm/scheduler_installer.asm
        ;
        ; Quest'opera e' stata rilasciata con licenza Creative Commons 
        ; Attribuzione - Non commerciale - Condividi allo stesso modo 3.0 
        ; Italia. Per leggere una copia della licenza visita il sito web 
        ; http://creativecommons.org/licenses/by-nc-sa/3.0/it/ 
        ; o spedisci una lettera a 
        ; Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
        
        ; Assembliamo il programma a partire dalla zona di memoria
        ; libera posizionata all'indirizzo $C000 (49152)
        * = 49152

        ; ============================================================ 
        ; INIZIO PROGRAMMA
        ; ============================================================ 
start
        ; Prima di tutto, disattiviamo gli interrupt prima di procedere
        ; alla copia delle ROM
        sei

        ; ============================================================ 
        ; COPIA KERNAL (ROM > RAM)
        ; ============================================================ 
        ; Dobbiamo eseguire 32 volte un loop che, a sua volta, e' composto
        ; da un loop di 256 iterazioni. L'indirizzo da cui leggere e in cui
        ; scrivere e' impostato a $E000 e viene suddiviso nella parte bassa ($FB)
        ; e in quella alta ($FC). 
        ldx #32
        lda #$E0
        sta $FC
        ldy #$00
        sty $FB

        ; Leggiamo e scriviamo il byte individuato dall'indirizzo contenuto
        ; nella locazione $FB-FC a cui andiamo a sommare il valore contenuto
        ; nel registro Y.
loop    lda ($FB),y
        sta ($FB),y

        ; Incrementiamo la locazione (registro Y) e ripetiamo fino a quando
        ; non torna a zero, che vuol dire che siamo arrivati alla fine del
        ; blocco da 256 bytes.
        iny
        bne loop

        ; Se abbiamo finito di copiare un blocco, incrementiamo la posizione
        ; da cui leggere e scrivere di 256 posizioni e decrementiamo il
        ; numero di blocchi ancora da copiare. Se vi sono ancora blocchi,
        ; ripetiamo la procedura di copia
        inc $FC
        dex
        bne loop

        ; ============================================================ 
        ; COPIA BASIC (ROM > RAM)
        ; ============================================================ 
        ; Dobbiamo eseguire 32 volte un loop che, a sua volta, e' composto
        ; da un loop di 256 iterazioni. L'indirizzo da cui leggere e in cui
        ; scrivere e' impostato a $A000 e viene suddiviso nella parte bassa ($FB)
        ; e in quella alta ($FC). 
        ldx #32
        lda #$A0
        sta $FC
        ldy #$00
        sty $FB

        ; Leggiamo e scriviamo il byte individuato dall'indirizzo contenuto
        ; nella locazione $FB-FC a cui andiamo a sommare il valore contenuto
        ; nel registro Y.
loop2   lda ($FB),y
        sta ($FB),y

        ; Incrementiamo la locazione (registro Y) e ripetiamo fino a quando
        ; non torna a zero, che vuol dire che siamo arrivati alla fine del
        ; blocco da 256 bytes.
        iny
        bne loop2

        ; Se abbiamo finito di copiare un blocco, incrementiamo la posizione
        ; da cui leggere e scrivere di 256 posizioni e decrementiamo il
        ; numero di blocchi ancora da copiare. Se vi sono ancora blocchi,
        ; ripetiamo la procedura di copia
        inc $FC
        dex
        bne loop2

        ; Salviamo il vettore precedente, di modo da poterlo richiamare
        ; "a catena" dopo che sara' stato richiamato il nostro.
        lda $fffe
        sta previous_lo
        lda $ffff
        sta previous_hi

        ; Impostiamo ora il nostro vettore.
        lda #<scheduler
        sta $fffe
        lda #>scheduler
        sta $ffff

        ; Spegniamo le ROM!
        lda #$35
        sta $01

        ; Ripristiniamo gli interrupt e terminiamo.
        cli
        rts

; Registro dove manteniamo l'indirizzo alla routine di gestione degli interrupt
; (parte bassa)
previous_lo byte 0
; Registro dove manteniamo l'indirizzo alla routine di gestione degli interrupt
; (parte alta)
previous_hi byte 0

        ; ============================================================ 
        ; SCHEDULER
        ; ============================================================ 
        ; Questa routine e', in realta', un semplice dimostrativo per verificare
        ; che la routine venga richiamata ad ogni interrupt in arrivo.

; Attuale colore dello sfondo (ciclico).
color1           BYTE 0

scheduler
        ; Per sicurezza, salviamo tutti i registri del processore.
        pha
        txa
        pha
        tya
        pha

        ; Piccola demo: modifichiamo il colore dello sfondo ad ogni
        ; interrupt che arriva, a prescindere dalla sorgente.
        ldx color1
        inx
        stx color1
        stx $D020

        ; Ripristiniamo tutti i registri del processore.
        pla
        tay
        pla
        tax
        pla

        ; Eseguiamo il precedente vettore, per garantire che il
        ; computer continui a funzionare come prima.
        jmp (previous_lo)