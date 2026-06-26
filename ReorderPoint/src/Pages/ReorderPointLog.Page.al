/// <summary>
/// Read-only list of Reorder Point Calculation Log entries, newest first, showing the
/// inputs, result, and outcome of each calculation for traceability and audit.
/// </summary>
page 50301 "Reorder Point Calculation Log"
{
    Caption = 'Reorder Point Calculation Log';
    PageType = List;
    SourceTable = "Reorder Point Calculation Log";
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Calculation DateTime"; Rec."Calculation DateTime") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Result Code"; Rec."Result Code") { ApplicationArea = All; }
                field("Applied"; Rec."Applied") { ApplicationArea = All; }
                field("Calculated Reorder Point"; Rec."Calculated Reorder Point") { ApplicationArea = All; }
                field("Previous Reorder Point"; Rec."Previous Reorder Point") { ApplicationArea = All; }
                field("Avg Daily Demand"; Rec."Avg Daily Demand") { ApplicationArea = All; }
                field("Lead Time (Days)"; Rec."Lead Time (Days)") { ApplicationArea = All; }
                field("Lead Time Source"; Rec."Lead Time Source") { ApplicationArea = All; }
                field("Demand During Lead Time"; Rec."Demand During Lead Time") { ApplicationArea = All; }
                field("Safety Stock Used"; Rec."Safety Stock Used") { ApplicationArea = All; }
                field("Replenishment System"; Rec."Replenishment System") { ApplicationArea = All; }
                field("Demand Observations"; Rec."Demand Observations") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}
