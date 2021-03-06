.petscii
.include "godotlib.lib"

; ---------------------------
;
;    ldr.Loadstar
;  Loader for Loadstar splash screens, either hires or multi
;
;    1.00: 09.06.01, first release
;    1.01: 16.12.01, bugfix: background color could be wrong
;
;
; ---------------------------

         .ob "l_loads,p,w"
;
            .ba $c000
;
            .eq comprfl		=$30
            .eq counter		=$31
            .eq gbyte		=$33
            .eq byte		=$34
            .eq cnt		=byte
            .eq gmode		=$35
            .eq vr		=$36
            .eq cr		=$38
            .eq vv		=$3a
            .eq status		=$90

            .eq offx		=$b2
            .eq offy		=offx+1
;
            .eq vrbuf		=$c600
            .eq crbuf		=vrbuf+1000
            .eq col0		=vrbuf+2000
            .eq sprite		=$d015
;
; --------------------------- Header

            jmp start
            .by $80
            .by $00,$00
            .by <(modend),>(modend)
            .by $00,$00
;
;              0123456789abcdef
;
            .tx "Loadstar Splash "
            .tx "1.01"
            .tx "16.12.01"
            .tx "A.Dettke        "

; --------------------------- Main
;
jerror      jmp error
;
start       ldx #0
            stx counter		; clear byte counter 
            stx counter+1
            lda ls_nambuf	; First char in name is "spades"? (Koala)
            cmp #$c1
            bne stt1
            lda #$81		; yes, exchange
stt1        sta ls_nambuf
            ldx $a7		; length of name is shorter than 16?
            cpx #16
            beq stt2
            lda #$2a		; yes, attach a "*" to it
            sta ls_nambuf,x
            inc $a7		; increment length of name
            jsr getname		; store name
;
stt2        jsr gd_xopen	; open file
            jsr basin		; skip start address ($4000)
            bcs jerror
            jsr basin
            bcs jerror
            jsr basin		; get mode flag (hires/multi)
            bcs jerror
            sta gmode
            tax
            jsr basin		; get compression indicator
            bcs jerror
            sta comprfl
            txa			; mode= hires?
            bpl stt3		; no, get bg color
            jmp gethires	; yes, load hires

; --------------------------- Get Multicolor Image

stt3        jsr basin		; get background color (in multi mode)
            bcs jerror
            and #15		; isolate color value
            sta col0

            jsr gd_clrms	; clear message bar

            lda #50		; activity counter to 50
            sta cntwert
            sta $ff
            ldx #30		; "Bitmap"
            jsr tcopy
;
            lda #<(8000)	; count 8000 bytes (bitmap)
            sta ls_vekta8
            lda #>(8000)
            sta ls_vekta8+1
            ldx #0		; destination $4000
            ldy #$40
            stx sc_texttab
            sty sc_texttab+1
;
loop        jsr onebyte		; get bitmap
            bne jerror
            sta byte
            jsr action
            ldy #0
            ldx #4		; convert to 4bit indexes
bloop       lda #0
            asl byte
            rol
            asl byte
            rol
            sta (sc_texttab),y
            inc sc_texttab
            bne sk
            inc sc_texttab+1
sk          dex
            bne bloop
            lda ls_vekta8
            bne sk1
            dec ls_vekta8+1
sk1         dec ls_vekta8
            lda ls_vekta8
            ora ls_vekta8+1
            beq sk2
            lda status
            beq loop
;
sk2         lda #7		; get multi mode colors
            sta cntwert
            sta $ff
            ldx #0		; out: "Colors 1"
            stx comprfl		; compression with $00
            jsr tcopy

            lda #<(1000)	; count 1000 bytes (video RAM)
            sta ls_vekta8
            lda #>(1000)
            sta ls_vekta8+1
            lda #<(vrbuf)
            sta sc_texttab
            lda #>(vrbuf)
            sta sc_texttab+1
;
loop1       jsr onebyte		; get color RAM (no conversion)
            sta (sc_texttab),y
            jsr action
            ldy #0
            inc sc_texttab
            bne sk3
            inc sc_texttab+1
sk3         lda ls_vekta8
            bne sk4
            dec ls_vekta8+1
sk4         dec ls_vekta8
            lda ls_vekta8
            ora ls_vekta8+1
            beq sk21
            jmp loop1
;
sk21        lda #7
            sta cntwert
            sta $ff
            ldx #$ff		; out: "Colors 2"
            stx comprfl		; compression with $ff
            ldx #10
            jsr tcopy

            lda #<(1000)	; count 1000 bytes (color RAM)
            sta ls_vekta8
            lda #>(1000)
            sta ls_vekta8+1
            lda #<(crbuf)
            sta sc_texttab
            lda #>(crbuf)
            sta sc_texttab+1
;
loop2       jsr onebyte		; get color RAM (no conversion)
            sta (sc_texttab),y
            jsr action
            ldy #0
            inc sc_texttab
            bne sk31
            inc sc_texttab+1
sk31        lda ls_vekta8
            bne sk41
            dec ls_vekta8+1
sk41        dec ls_vekta8
            lda ls_vekta8
            ora ls_vekta8+1
            beq sk5
            jmp loop2
;
sk5         jsr gd_xclose	; close file

            lda #<(vrbuf)	; convert to 4bit (set start addresses)
            sta vr
            lda #>(vrbuf)
            sta vr+1
            lda #<(crbuf)
            sta cr
            lda #>(crbuf)
            sta cr+1
            lda #<($4000)
            sta sc_texttab
            lda #>($4000)
            sta sc_texttab+1
            lda #<(1000)	; count 1000
            sta ls_vekta8
            lda #>(1000)
            sta ls_vekta8+1
;
            lda #200
            sta cntwert
            sta $ff
            ldx #20
            jsr tcopy
;
loop3       lda (vr),y		; convert video RAM colors to 4bit
            pha
            lsr
            lsr
            lsr
            lsr
            sta col0+1
            pla
            and #$0f
            sta col0+2
            lda (cr),y		; convert color RAM colors to 4bit
            and #$0f
            sta col0+3
            lda #32
            sta cnt
bloop1      jsr action
            ldy #0
            lda (sc_texttab),y	; get values from 4bit (0-3)
            tax
            lda col0,x		; get color values from table
            tax
            lda dnib,x		; get conversion values to GoDot palette from table
            sta (sc_texttab),y	; write back to 4bit (double nibbles)
            inc sc_texttab	; advance
            bne sk6
            inc sc_texttab+1
sk6         dec cnt		; one tile
            bne bloop1
            inc vr		; next tile
            bne sk7
            inc vr+1
sk7         inc cr
            bne sk8
            inc cr+1
sk8         lda ls_vekta8	; 1000 tiles
            bne sk9
            dec ls_vekta8+1
sk9         dec ls_vekta8
            lda ls_vekta8
            ora ls_vekta8+1
            bne loop3

            jsr setmtext	; set image information texts

; --------------------------- Close File

sk11        ldx #30		; reset text to default ("Bitmap")
            jsr tcopy
            jsr setinfo		; set filename
;
sk10        jsr gd_xmess	; error message from drive
            jsr gd_spron	; sprite pointer on
            sec			; leave loader
            rts

; ---------------------------------------
; --------------------------- get hires image
; ---------------------------------------

jerror2     jmp error

gethires    jsr gd_clrms	; clear message bar

            lda #50
            sta cntwert
            sta $ff
            ldx #30		; Text: "Bitmap"
            jsr tcopy
;
read1       lda #0		; get bitmap
            sta sc_texttab
            lda #$a0
            sta sc_texttab+1	; destination: $a000 (up to $bf3f)
            lda #<(8000)
            sta ls_vekta8
            lda #>(8000)
            sta ls_vekta8+1
            jsr rloop
            bne jerror2
;
            lda #7
            sta cntwert
            sta $ff
            ldx #0		; Text: "Colors 1"
            jsr tcopy
;
read2       lda #0		; get colors
            sta comprfl
            sta sc_texttab
            lda #>(vrbuf)
            sta sc_texttab+1
            lda #<(1000)
            sta ls_vekta8
            lda #>(1000)
            sta ls_vekta8+1
            jsr rloop
            bne jerror2

            jsr gd_xclose	; close file
;
conhir      lda #7
            sta cntwert
            sta $ff
            ldx #40		; Text: "Move"
            jsr tcopy
;
            ldx #4		; move colors
            stx cnt
            lda #0
            tay
            sta ls_vekta8
            sta sc_texttab
            lda #>(vrbuf)	; from $c600
            sta ls_vekta8+1
            lda #>(crbuf)	; to $c9e8 (up to $cde8)
            sta sc_texttab+1
ml2         lda (ls_vekta8),y
            sty vv
            asl
            rol vv
            asl
            rol vv
            asl
            rol vv
            asl
            rol vv
            ora vv
            sta (sc_texttab),y
            tya
            pha
            jsr action
            pla
            tay
            iny
            bne ml2
            inc ls_vekta8+1
            inc sc_texttab+1
            dec cnt		; 4 pages
            bne ml2

hires       lda #50		; convert hires to 4bit
            sta cntwert
            sta $ff
            ldx #20		; Text: "Convert"
            jsr tcopy
;
            lda #<(8000)
            sta ls_vekta8
            lda #>(8000)
            sta ls_vekta8+1
            lda #0
            tay
            sta vr
            sta cr
            sta sc_texttab
            lda #$a0		; vector to bitmap ($a000)
            sta cr+1
            asl			; vector to 4bit ($4000)
            sta sc_texttab+1
            lda #>(vrbuf)	; vector to hires colors ($c600)
            sta vr+1
            lda #<(crbuf)
            sta vv
            lda #>(crbuf)	; vector to hires colors ($c9e8)
            sta vv+1
;
hloop1      ldx #8		; 8 pages
            stx cnt
hilp        lda (cr),y		; get hires bits
            sta byte
            jsr action
            ldy #0
            ldx #4
hl2         asl byte
            bcc hl3
            lda (vv),y
            .by $2c
hl3         lda (vr),y
            and #$0f
            tay
            lda dnib,y
            and #$f0
            sta col0
            ldy #0
            asl byte
            bcc hl4
            lda (vv),y
            .by $2c
hl4         lda (vr),y
            and #$0f
            tay
            lda dnib,y
            and #$0f
            ora col0
            ldy #0
            sta (sc_texttab),y
;
            inc sc_texttab
            bne lh5
            inc sc_texttab+1
lh5         dex
            bne hl2
            inc cr
            bne hl6
            inc cr+1
hl6         lda ls_vekta8
            bne hl7
            dec ls_vekta8+1
hl7         dec ls_vekta8
            lda ls_vekta8
            ora ls_vekta8+1
            beq hl9
            dec cnt
            bne hilp
            inc vr
            bne hl8
            inc vr+1
hl8         inc vv
            bne hloop1
            inc vv+1
            bne hloop1

hl9         jsr sethtext	; set image information texts
            jmp sk11		; close file
;
; --------------------------- Hires get data loop

rloop       jsr onebyte
            sta (sc_texttab),y
            txa
            and #$bf
            bne rl3
            jsr action
            ldy #0
            inc sc_texttab
            bne rl1
            inc sc_texttab+1
rl1         lda ls_vekta8
            bne rl2
            dec ls_vekta8+1
rl2         dec ls_vekta8
            lda ls_vekta8
            ora ls_vekta8+1
            bne rloop
rl3         rts

; --------------------------- Set Image Data Information texts

sethtext    ldx #6
            .by $2c
setmtext    ldx #13
            ldy #6
smt0        lda htext,x
            sta modetx,y
            dex
            dey
            bpl smt0
            rts
; --------------------------- 
error       jsr gd_xclose
            jsr sk10
            clc
            rts
; --------------------------- 

; compression: flag, counter, byte ; $00 counts 256

; --------------------------- Decompress Image 

onebyte     lda counter		; repeated byte?
            ora counter+1
            bne getit2		; yes, re-get value

            inc counter		; no, counter to 1
            jsr basin		; get 1 byte
            cmp comprfl		; compression flag?
            bne getit1		; no

            jsr basin		; compressed: get counter
            sta counter
            beq rb2		; $00 equals 256 bytes
            lda #0
            beq rb3
rb2         lda #1
rb3         sta counter+1
            jsr basin		; get byte to compress

getit1      sta gbyte		; and store

getit2      lda counter		; count repetition
            bne rb4
            dec counter+1
rb4         dec counter
            lda gbyte		; re-get byte
            ldx status
            rts

; --------------------------- Activity Display

messout     ldx #<(message)
            ldy #>(message)
            jmp gd_xtxout2
;
tcopy       ldy #0
tc0         lda txt,x
            beq clrmess
            sta message,y
            inx
            iny
            bne tc0
;
action      dec $ff
            bne ld4
            lda cntwert
            sta $ff
            ldy offy
            ldx offx
            lda filltab,x
            sta mess,y
            jsr messout
            dec offx
            bpl ld4
            inc offy
            lda #7
            sta offx
ld4         rts
;
clrmess     ldx #20
            lda #32
cl0         sta mess,x
            dex
            bpl cl0
            ldy #0
            ldx #7
            sty offy
            stx offx
            rts
;
filltab     .by 160,93,103,127,126,124,105,109
;
cntwert     .by 50
;
txt         .ts " Colors 1@"	; 0
            .ts " Colors 2@"	; 10
            .ts " Convert @"	; 20
            .ts " Bitmap  @"    ; 30
            .ts " Move    @"    ; 40
;
message     .ts " Bitmap    "
mess        .tx "                     "
            .by 0

; --------------------------- Palette Table for MC double pixels
;
dnib        .by $00,$ff,$44,$cc,$55,$aa,$11,$dd
            .by $66,$22,$99,$33,$77,$ee,$88,$bb

; --------------------------- Save Filename
;
getname     ldx #0
si0         lda ls_lastname,x
            beq si1
            sta nbuf,x
            inx
            cpx #16
            bcc si0
si1         rts
;
; --------------------------- Image Information

getdatac    ldx #4
            ldy #4
sinfo0      lda dtextc,x
            sta datatype,y
            dex
            dey
            bpl sinfo0
            rts
;
setinfo     jsr getdatac
            jsr setname
            jsr setloader
            jsr setmode
            jmp setdata
;
setname     lda #0
            ldx #<(ls_picname)
            ldy #>(ls_picname)
            bne si3
setloader   lda #17
            ldx #<(ls_iloader)
            ldy #>(ls_iloader)
            bne si3
setmode     lda #25
            ldx #<(ls_imode)
            ldy #>(ls_imode)
            bne si3
setdata     lda #33
            ldx #<(ls_idrive)
            ldy #>(ls_idrive)
si3         stx sc_texttab
            sty sc_texttab+1
            tax
            ldy #0
si4         lda nbuf,x
            beq si5
            sta (sc_texttab),y
            inx
            iny
            bne si4
si5         rts
;
nbuf        .by 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,0
            .ts "Loadstr@"		; 17
modetx      .ts "160x200@"		; 25
datatype    .ts "Color@"		; 33

htext       .ts "320x200"		; 46
mtext       .ts "160x200"

dtextc      .ts "Color"

modend      .en
