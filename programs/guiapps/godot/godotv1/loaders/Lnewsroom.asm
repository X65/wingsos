.petscii
.ob "lnewsroom,p,w"
.include "godotlib.lib"

.ba $c000
; ----------------------------------- 
; Loader Newsroom Photos and Banners
;     1.00: 04.07.01, first release
;     1.01: 08.07.01, bug: hang on wrong header fixed
;     1.02: 11.07.01, bug: reject on no clip included fixed
;
; ----------------------------------- 

; ----------------------------------- Equates

            .eq width		=$30	; width in tiles
            .eq height		=$31
            .eq col0		=$32	; paper color (black)
            .eq col1		=$33	; ink colors (white)
            .eq col2		=$34
            .eq col3		=$35

            .eq dst		=$36	; /$37
            .eq dst0		=$38	; /$39
            .eq dst00		=$3a	; /$3b
            .eq adcnt		=$3c	; activity counter
            .eq btcnt		=$3d	; counts 4 bytes
            .eq tilecnt		=$3e	; counts WIDTH tiles
            .eq offx		=$3f
            .eq offy		=$40
            .eq lcnt		=$41
            .eq lines		=$42
            .eq gbyte		=$43
            .eq merky		=$44
            .eq blcnt		=$45
            .eq num		=$46

            .eq status		=$90	; floppy status byte

; ----------------------------------- Header

godheader   jmp start
            .by $80
            .by 0
            .by 0
            .wo modend
            .wo 0
            .tx "Newsroom Clips  "
            .tx "1.02"
            .tx "11.07.01"
            .tx "A.Dettke        "

; ----------------------------------- 

jerror      jmp error
fail        jmp faila

start       jsr getcols		; set color assignments
            jsr getname		; save name of file
            
            jsr gd_xopen	; open file for input
            ldx #0		; Start at $4000
            ldy #$40
            stx status		; clear status byte
            stx dst		; set destination address
            stx dst0
            stx dst00
            sty dst+1
            sty dst0+1
            sty dst00+1
            inx 		; activity to 1: start right off
            stx adcnt

            jsr onebyte		; get first byte (of address $a000)
            bne jerror
            sta header
            jsr onebyte		; get second byte
            bne jerror
            sta header+1

            ldy #2
st1         jsr onebyte		; get header
            sta header,y
            bne jerror
            iny
            cpy #8		; 8 bytes header
            bne st1
            lda header+1	; is second byte $a0?
            cmp #$a0
            beq st3
            jmp fail		; no, fail

st3         sec			; compute width (in pixels and tiles+1)
            lda right
            sbc left
            lsr
            lsr
            lsr
            sta width
            inc width
            sec			; compute height (in pixels) 
            lda bottom
            sbc top
            cmp #200
            bcc st21
            lda #200
st21        sta height
            jsr evalheader

st2         lda #8		; set # of lines per tile (8)
            sta lines
            lda height
            cmp #9
            bcs ld6
            sta lines		; then already last line, set value!

ld6         jsr gd_clrms	; clear gauge
            jsr tcopy

            lda #25		; set counter for screen height
            sta blcnt
            lda #4		; preset 4bit-Byte counter to 4
            sta btcnt
;
ld0         lda lines		; 8 lines per tile (except last row)
            sta lcnt

ld02        lda width		; WIDTH tiles per row
            sta tilecnt

ld03        ldy #0		; must be 0 for 1 tile
            jsr getbyte		; get 1 byte
ld01        jsr cnvbyte		; convert to 4 bytes
            sta (dst),y		; store to 4bit memory
            sty merky
            jsr action
            ldy merky
            iny
            dec btcnt		; all bits?
            bne ld01		; no, loop

            lda #4		; counter to 4 again
            sta btcnt

            clc
            lda dst		; inc vector to 4bit
            adc #32
            sta dst
            bcc ld10
            inc dst+1

ld10        dec tilecnt		; all tiles of a row?
            bne ld03

            clc			; next raster line
            lda dst0
            adc #4
            sta dst0
            sta dst
            bcc ld11
            inc dst0+1
ld11        lda dst0+1
            sta dst+1

            dec lcnt		; all lines of a tile?
            bne ld02

ld13        sec			; yes, subtract 8 from height
            lda height
            sbc #8
            sta height
            beq ld3		; finished if zero
            bcc ld3		; or below
            cmp #9		; >8?
            bcs ld12		; no, not last row yet
            sta lines		; yes, don't fill last row completely 
            inc lines

ld12        clc			; add 1280 to start address for next row
            lda dst00+1
            adc #5
            sta dst00+1
            sta dst0+1
            sta dst+1
            lda dst00
            sta dst0
            sta dst

            dec blcnt		; bottom of screen?
            bne ld0		; no, loop

ld3         jsr setinfo		; set fileinfo
ld7         jsr gd_xclose	; close file
            jsr gd_spron	; pointer on
            jsr gd_xmess	; display floppy message
cancel      sec			; leave loader
            rts

; ----------------------------------- 

getbyte     jsr basin		; uncompressed image: get byte
;            eor #$ff
getdata     sta gbyte		; and store 
            rts

; ----------------------------------- 

cnvbyte     lda #0		; convert:
            asl gbyte		; fetch 2 pixels
            rol
            asl gbyte
            rol
            tax			; assign color and return value
            lda col0,x
            rts

; ----------------------------------- File Error

error       jsr ld7
            clc
            rts

; ----------------------------------- Get 1 Byte for Header

onebyte     jsr basin
            ldx status
            rts

; ----------------------------------- 

evalheader  ldy #1
            jsr onebyte		; get # of clips included
            tax
            beq noclip		; if $00: short header or no clip?
            sta num		; store number

            ldy #12		; header is 13 times # of clips...
ehd0        clc
            adc num
            dey
            bne ehd0
            tay
            iny
ehd4        jsr onebyte		; skip header
            dey
            bne ehd4
            tay			; ends with $00?
            bne fail2
            ldy #0		; yes, followed by signature...?
ehd1        jsr onebyte
            cmp signature,y
            bne fail2
            iny
            cpy #8
            bne ehd1
ehd3        jsr onebyte		; yes, followed by 7 times $00 and then $ff?
            dey
            bne ehd3
            cmp #$ff
            bne fail2
            rts			; yes, finished header

noclip      dey
            jsr onebyte		; next byte $00?
            tax
            beq ehd1		; yes, no clip, now check signature
            inx			; no, check for short header
            bne fail2		; no short header: fail
            rts

fail2       pla			; if not: error message
            pla
            jsr error
            jmp faila

            
; ----------------------------------- 

header      .by 0,0
            .wo 0
top         .by 0
bottom      .by 0
left        .by 0
right       .by 0
signature   .tx "newsroom"

cntwert     .by 200

; ----------------------------------- 

faila       lda #0
            pha
            jsr ld7
            pla
            tax
            ldy #0
fl0         lda err1,x
            sta message,y
            inx
            iny
            cpy #32
            bne fl0
            jsr gd_clrms
           
messout     ldx #<(message)
            ldy #>(message)
            jmp gd_xtxout2
;
action      dec adcnt
            bne ld4
            lda cntwert
            sta adcnt
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
tcopy       ldy #0
tc0         lda txt,x
            beq clrmess
            sta message,y
            inx
            iny
            bne tc0
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
message     .ts " NR Photo  "
mess        .ts "                     @"
txt         .ts " NR Photo  @" ; 0
err1        .ts " ERROR: No valid Newsroom image."

; ----------------------------------- Assign colors

getcols     lda #0		; %00: black
            sta col0
            lda gr_picked	; colorize, if not black
            and #$0f
            tax
            bne gc0
            ldx #1		; (white; a value 15 would be lgrey)
gc0         lda gdcols,x	; %11: comes from PICKED 
            sta col3
            tax			; %01: same as %11
            and #$0f
            sta col1
            txa			; %10: same as %01
            and #$f0
            sta col2
            rts

; ----------------------------------- 
;
gdcols      .by $00,$ff,$44,$cc,$55,$aa,$11,$dd
            .by $66,$22,$99,$33,$77,$ee,$88,$bb
;
; ----------------------------------- 

getname     ldx #0
si0         lda ls_lastname,x
            beq si1
            sta nbuf,x
            inx
            cpx #16
            bcc si0
si1         rts
;
; ----------------------------------- 

setinfo     jsr setname
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
            .ts "Newsrm @"
modetx      .ts "320x200@"
datatype    .ts "Color@"

modend      .en

