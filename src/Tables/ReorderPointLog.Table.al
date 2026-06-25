table 50301 "Reorder Point Calculation Log"
{
    Caption = 'Reorder Point Calculation Log';
    DataClassification = CustomerContent;
    LookupPageId = "Reorder Point Calculation Log";
    DrillDownPageId = "Reorder Point Calculation Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
        }
        field(3; "Calculation DateTime"; DateTime)
        {
            Caption = 'Calculation DateTime';
            DataClassification = CustomerContent;
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(10; "Avg Daily Demand"; Decimal)
        {
            Caption = 'Avg Daily Demand';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }
        field(11; "Demand Observations"; Integer)
        {
            Caption = 'Demand Observations';
            DataClassification = CustomerContent;
        }
        field(12; "Lead Time (Days)"; Decimal)
        {
            Caption = 'Lead Time (Days)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
        }
        field(13; "Lead Time Source"; Text[50])
        {
            Caption = 'Lead Time Source';
            DataClassification = CustomerContent;
        }
        field(14; "Demand During Lead Time"; Decimal)
        {
            Caption = 'Demand During Lead Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(15; "Safety Stock Used"; Decimal)
        {
            Caption = 'Safety Stock Used';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(16; "Replenishment System"; Text[30])
        {
            Caption = 'Replenishment System';
            DataClassification = CustomerContent;
        }
        field(20; "Calculated Reorder Point"; Decimal)
        {
            Caption = 'Calculated Reorder Point';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(21; "Previous Reorder Point"; Decimal)
        {
            Caption = 'Previous Reorder Point';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(22; "Applied"; Boolean)
        {
            Caption = 'Applied';
            DataClassification = CustomerContent;
        }
        field(30; "Result Code"; Enum "Reorder Point Result Code")
        {
            Caption = 'Result Code';
            DataClassification = CustomerContent;
        }
        field(31; "Note"; Text[250])
        {
            Caption = 'Note';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Item; "Item No.", "Calculation DateTime") { }
    }
}
