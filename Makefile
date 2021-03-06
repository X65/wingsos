O:=obj/
E:=extras/
B:=bins/
BS:=bins/system/
BL:=bins/libs/
L:=$(BL)
BD:=$Bdrivers/
BG:=$Bgui/
BGF:=$(BG)fonts/
BP:=$Bprograms/
BPG:=$(BP)graphics/
BPS:=$(BP)sound/
BPD:=$(BP)devel/
BPU:=$(BP)utils/
BPN:=$(BP)net/
BDIRS:=$OBINDIRS.flag
BRDIRS:= $(BS) $(BL) $(BGF) $(BD) $(BG) $(BP) $(BPG) $(BPS) $(BPD) $(BPU) $(BPN)
BTARG:= $O% $B% $(BS)% $(BL)% $(BGF)% $(BD)% $(BG)% $(BP)% $(BPG)% $(BPS)% $(BPD)% $(BPU)% $(BPN)%
BINDIR = $(HOME)/bin
INSTBINS:=$Bbooter $(BPU)gunzip $Owings.zip
ALLOBJ = 
CFLAGS = -w

all: all2

include btools/Rules.mk
include drivers/Rules.mk
include kernel/Rules.mk
include programs/Rules.mk
include lib/src/Rules.mk
	
$(BDIRS):
	mkdir -p $(BRDIRS)
	touch $(BDIRS)
	
$O%.o65: %.a65 $(JA)
	$(JA) $(JAFLAGS) -o $@ $<
	
$O%.o65: %.c $(BINTOOLS)
	lcc $(CFLAGS) -c -o $@ $<

$(BTARG): %.c $OCRT.flag $(BDIRS)
	lcc $(CFLAGS) $(LDFLAGS) -o $@ $(filter %.c, $^) $(filter %.o65, $^)

$(BTARG): src%.c $OCRT.flag $(BDIRS)
	lcc $(CFLAGS) $(LDFLAGS) -o $@ $(filter %.c, $^) $(filter %.o65, $^)
	
$(BTARG): $Ebackgrounds/%
	cp $< $@ 

$(BTARG): $Efonts/%
	cp $< $@ 

$(BTARG): programs/scripts/%
	cp $< $@ 

$(BTARG): $O%.o65 $(JL65)
	$(JL65) -y -llibc -lcrt -G -p -o $@ $(filter %.o65, $^)	

all2: $(ALLOBJ) $Owings.zip $Oinstall.d81 $Owings.d81 $Oinstall.zip

$Owings.zip: $(ALLOBJ)
	cd bins/ ; zip -r ../$Owings.zip * -x $(subst bins/,, $(INITRD))

$Oinstall.d81: $(INSTBINS) $Oinitfirst.bin $(MKIM)
	rm -f $@
	cp $Oinitfirst.bin $Oinit
	$(MKIM) -o $@ -vs $(INSTBINS) $Oinit
	rm $Oinit

$Oinstall.zip: $(INSTBINS) $Oinitfirst.bin
	rm -f $@
	cp $Oinitfirst.bin $Oinit
	zip -j $@ $(INSTBINS) $Oinit
	rm $Oinit

$Owings.d81: $(ALLOBJ) $(MKIM)
	rm -f $@
	$(MKIM) -tc128 -o $@ -s -v $Bbooter
	$(MKIM) -tc128 -o $@ -i $@ -v -d media -r $Etestfiles/ $Etestfiles/*
	$(MKIM) -tc128 -o $@ -i $@ -v -d wings -r $B $B*

run: all sendboot wait sendnet
run2: all sendboot wait sendtst
run3: all sendboot wait sendnull
run4: all sendboot wait sendinst

sendkern:
	prmain --prload -r $Ojoskern.prg
sendboot:
	prmain --prload -r $Bbooter
wait:
	sleep 4

	
sendinst:
	prmain --prrfile $Oinstall.d81 2>/dev/null

sendnull:
	prmain --prrfile $Owings.d81 2>/dev/null
	
sendnet:
	prmain --prrfile $Owings.d81 </dev/ttyp4 >/dev/ttyp4

sendtst:
	prmain --prrfile $Owings.d81 <extras/testfiles/coconut.mod

jam:	
	prmain --prload $Edebug/JAM
	prmain --prload -j 0801 $Edebug/doJAM

dump: $(DEBCRASH)
	prmain --prsave 4000 @4000 > $Ocrashdump.prg
	$(DEBCRASH) $Ocrashdump.prg

realclean: cleanall
	;

cleanall: clean
	rm -f $(BO)*.o*
	rm -f $(BINTOOLS)
	
clean:
	rm -f $O*.*
	rm -f $(OB)*.o*
	rm -rf $B nonimg
	rm -f `find . -name '*~'`
	rm -rf screenshots/*
	rm -f $(CRT)
	rm -f $Oinit
	
