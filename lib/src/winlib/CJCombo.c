#include <winlib.h>
#include <string.h>
#include <stdlib.h>

void JComboDraw(JCombo *Self)
{
    uint Type = Self->Type;
    JTree *Tree = Self->Tree;
    uchar *Value;
    int xsize,ysize,ocol;

    xsize = ((JW *)Self)->XSize;
    ysize = ((JW *)Self)->YSize;
    ocol = ((JW *)Self)->Colours;
    GfxSetCol(0x01);
    GfxBox(xsize, ysize, 0);
    Value = (uchar *)Self->Value;
    if (Value)
    {
	Value += Self->Offs;
        renderCell(Tree, Type, 0, Value, 0x01);
    }
}

void JComboClicked(JW *Self)
{
    JW *combo = JWGetData(Self);
    JW *popup;
    int xy[2];
    JWAbs(combo, xy);
    
    popup = ((JCombo *)combo)->Popup;
    printf("Combo %lx, %lx\n", combo, popup);
    JWSetBounds(popup, xy[0], xy[1]+combo->YSize, combo->XSize, 80);
    if (popup->HideCnt)
	JWinShow(popup);
}

void JComboItem(JW *Self, TNode *Item)
{
    JCombo *combo = JWGetData(Self);
    if (Item != combo->Value)
    {
        combo->Value = Item;
	if (combo->Changed)
	    combo->Changed(Item);
    }
    JPopupHide(combo->Popup);
    JWReDraw(combo);
}
