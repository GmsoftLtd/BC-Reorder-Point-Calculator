pageextension 50300 "Item Card RP Ext" extends "Item Card"
{
    actions
    {
        addlast(Promoted)
        {
            actionref(CalcReorderPoint_Promoted; CalcReorderPoint)
            {
            }
        }
        addafter("Stockkeepin&g Units")
        {
            action(CalcReorderPoint)
            {
                Caption = 'Calculate Reorder Point';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Compute the Reorder Point for this item as (average daily demand x lead time) + safety stock. Demand comes from posted SALES over the history window; lead time comes from purchase-receipt history or the Lead Time Calculation field. Make-to-order items are skipped because their supply is pegged to demand and has no stock level to defend.';

                trigger OnAction()
                var
                    Setup: Record "Reorder Point Setup";
                    Calc: Codeunit "Reorder Point Calculator";
                    ResultCode: Enum "Reorder Point Result Code";
                    Note: Text[250];
                    Result: Decimal;
                    ApplyResult: Boolean;
                    Details: Text;
                    MsgTxt: Label 'Reorder Point for %1: %2 units.\Previous value: %3.\Result: %4%5\\Apply this value to the item?';
                    MsgPreviewTxt: Label 'Reorder Point for %1 would be: %2 units (preview only).\Previous value: %3.\Result: %4%5';
                begin
                    Setup.GetSetup();

                    Result := Calc.CalculateForItem(Rec."No.", false, ResultCode, Note);
                    if Note <> '' then
                        Details := '\' + Note;

                    if Setup."Update Item Field" and (ResultCode = ResultCode::OK) then begin
                        ApplyResult := Confirm(MsgTxt, true, Rec."No.", Format(Result), Format(Rec."Reorder Point"), Format(ResultCode), Details);
                        if ApplyResult then begin
                            Rec.Validate("Reorder Point", Result);
                            if Setup."Set Reordering Policy" and (Rec."Reordering Policy" = Rec."Reordering Policy"::" ") then
                                Rec.Validate("Reordering Policy", Rec."Reordering Policy"::"Fixed Reorder Qty.");
                            Rec.Modify(true);
                        end;
                    end else
                        Message(MsgPreviewTxt, Rec."No.", Format(Result), Format(Rec."Reorder Point"), Format(ResultCode), Details);

                    CurrPage.Update(true);
                end;
            }
            action(ShowRPLog)
            {
                Caption = 'Reorder Point Log';
                ApplicationArea = All;
                Image = Log;
                ToolTip = 'Show the Reorder Point Calculation Log entries for this item.';

                trigger OnAction()
                var
                    LogEntry: Record "Reorder Point Calculation Log";
                    LogPage: Page "Reorder Point Calculation Log";
                begin
                    LogEntry.SetRange("Item No.", Rec."No.");
                    LogPage.SetTableView(LogEntry);
                    LogPage.Run();
                end;
            }
            action(GenerateRPDemoData)
            {
                Caption = 'Generate Demo Data (Sandbox)';
                ApplicationArea = All;
                Image = TestFile;
                ToolTip = 'SANDBOX ONLY. Creates ~6 past Purchase Orders (for lead time and inventory) and ~30 past Sales Orders (last 365 days) plus 3 future Sales Orders, all linked to this item and unposted. Post the Purchase Orders first, then the Sales Orders, then run Calculate Reorder Point to see real numbers. Do not run in production.';

                trigger OnAction()
                var
                    Demo: Codeunit "Reorder Point Demo Data";
                    ConfirmTxt: Label 'SANDBOX UTILITY\\This will create approximately:\  - 6 unposted Purchase Orders dated in the last 365 days\  - 30 unposted Sales Orders dated in the last 365 days\  - 3 unposted Sales Orders dated 1-4 weeks ahead\\All linked to item %1. Post the Purchase Orders first, then the Sales Orders, then re-run Calculate Reorder Point.\\Continue?';
                begin
                    if not Confirm(ConfirmTxt, false, Rec."No.") then
                        exit;
                    Demo.GenerateForItem(Rec."No.");
                end;
            }
        }
    }
}
