pageextension 50301 "Item List RP Ext" extends "Item List"
{
    actions
    {
        addlast(Promoted)
        {
            actionref(CalcReorderPointBulk_Promoted; CalcReorderPointBulk)
            {
            }
        }
        addafter("Stockkeepin&g Units")
        {
            action(CalcReorderPointBulk)
            {
                Caption = 'Calculate Reorder Point (Bulk)';
                ApplicationArea = All;
                Image = CalculateLines;
                ToolTip = 'Run the Reorder Point calculation for the items currently filtered or selected and apply the result. Demand is sales-based and lead time comes from receipt history or the Lead Time Calculation field. Make-to-order items in the selection are processed but skipped, and each skip is written to the log.';

                trigger OnAction()
                var
                    Item: Record Item;
                    Calc: Codeunit "Reorder Point Calculator";
                    Processed: Integer;
                    MTOCount: Integer;
                    Confirmed: Boolean;
                    ConfirmTxt: Label 'Calculate the Reorder Point for items matching the current filters and apply the result?\\%1 of the selected items are make-to-order and will be skipped (logged).\\Continue?';
                    ConfirmPlainTxt: Label 'Calculate the Reorder Point for items matching the current filters and apply the result?';
                begin
                    CurrPage.SetSelectionFilter(Item);
                    if Item.GetFilter("No.") = '' then
                        Item.CopyFilters(Rec);

                    MTOCount := Calc.CountMakeToOrderSkipped(Item);
                    if MTOCount > 0 then
                        Confirmed := Confirm(ConfirmTxt, false, MTOCount)
                    else
                        Confirmed := Confirm(ConfirmPlainTxt, false);
                    if not Confirmed then
                        exit;

                    Processed := Calc.CalculateBulk(Item, true);
                    Message('Processed %1 item(s). See the Reorder Point Calculation Log for the result of each, including any skipped make-to-order items.', Processed);
                end;
            }
        }
    }
}
