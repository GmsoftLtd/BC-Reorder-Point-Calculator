page 50300 "Reorder Point Setup"
{
    Caption = 'Reorder Point Setup';
    PageType = Card;
    SourceTable = "Reorder Point Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Defaults)
            {
                Caption = 'Calculation Inputs';

                field("History Window (Days)"; Rec."History Window (Days)")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many days of posted sales history (backwards from today) to use for the demand rate. 365 days smooths seasonality into a steady daily average.';
                }
                field("Min Demand Observations"; Rec."Min Demand Observations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Minimum number of days with demand needed to calculate. Below this, the item is skipped as insufficient data.';
                }
                field("Default Lead Time (Days)"; Rec."Default Lead Time (Days)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fallback lead time used when there is no receipt history and no Lead Time Calculation on the item. Set to 0 to force a No Lead Time Data result instead of guessing.';
                }
            }
            group(Behaviour)
            {
                Caption = 'Behaviour';

                field("Include Safety Stock"; Rec."Include Safety Stock")
                {
                    ApplicationArea = All;
                    ToolTip = 'Add the item Safety Stock Quantity on top of demand-during-lead-time. This is the textbook reorder point. Turn off to get demand-during-lead-time only.';
                }
                field("Round Up Result"; Rec."Round Up Result")
                {
                    ApplicationArea = All;
                    ToolTip = 'Round the reorder point up to the next whole unit. Recommended for items counted in whole pieces.';
                }
                field("Update Item Field"; Rec."Update Item Field")
                {
                    ApplicationArea = All;
                    ToolTip = 'Write the result directly to Item.Reorder Point. Disable to preview calculations only.';
                }
                field("Set Reordering Policy"; Rec."Set Reordering Policy")
                {
                    ApplicationArea = All;
                    ToolTip = 'When the item has no reordering policy, switch it to Fixed Reorder Qty. so the planning engine actually reads the reorder point. Items already on Maximum Qty. are left as they are.';
                }
                field("Skip Make-to-Order"; Rec."Skip Make-to-Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Skip items with Manufacturing Policy = Make-to-Order or Reordering Policy = Order. These are pegged to demand and have no stock level for a reorder point to defend.';
                }
                field("Log History"; Rec."Log History")
                {
                    ApplicationArea = All;
                    ToolTip = 'Save each calculation to a history log for traceability and audit.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenLog)
            {
                Caption = 'Calculation Log';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "Reorder Point Calculation Log";
                ToolTip = 'Open the Reorder Point Calculation Log to review past calculation runs (all items, all users).';
            }
        }
        area(Promoted)
        {
            actionref(OpenLog_Promoted; OpenLog)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
