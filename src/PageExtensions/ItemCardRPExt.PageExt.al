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
                    Details: Text;
                    MsgTxt: Label 'Reorder Point for %1: %2 units.\Previous value: %3.\Result: %4%5\\Apply this value to the item?';
                    MsgPreviewTxt: Label 'Reorder Point for %1 would be: %2 units (preview only).\Previous value: %3.\Result: %4%5';
                begin
                    Setup.GetSetup();

                    // Preview only: does not write to the item or the log, so a cancelled
                    // confirm leaves no misleading "applied" trail.
                    Result := Calc.CalculatePreview(Rec."No.", ResultCode, Note);
                    if Note <> '' then
                        Details := '\' + Note;

                    if Setup."Update Item Field" and (ResultCode = ResultCode::OK) then begin
                        if Confirm(MsgTxt, true, Rec."No.", Format(Result), Format(Rec."Reorder Point"), Format(ResultCode), Details) then begin
                            // Apply through the calculator: it owns the item write (with the
                            // right indirect permissions), logs it as Applied, and keeps the
                            // Reordering Policy switch in one place.
                            Calc.CalculateForItem(Rec."No.", true);
                            Rec.Get(Rec."No.");
                            CurrPage.Update(false);
                        end;
                    end else
                        Message(MsgPreviewTxt, Rec."No.", Format(Result), Format(Rec."Reorder Point"), Format(ResultCode), Details);
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
                Visible = IsSandboxEnv;
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

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // The demo-data action is a sandbox-only utility; keep it out of sight on production.
        IsSandboxEnv := EnvironmentInformation.IsSandbox();
    end;

    var
        IsSandboxEnv: Boolean;
}
