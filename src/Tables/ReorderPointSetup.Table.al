table 50300 "Reorder Point Setup"
{
    Caption = 'Reorder Point Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "History Window (Days)"; Integer)
        {
            Caption = 'Demand History Window (Days)';
            DataClassification = CustomerContent;
            MinValue = 30;
            MaxValue = 1095;
            InitValue = 365;
        }
        field(11; "Min Demand Observations"; Integer)
        {
            Caption = 'Min Demand Observations to Calculate';
            DataClassification = CustomerContent;
            MinValue = 3;
            InitValue = 20;
        }
        field(12; "Default Lead Time (Days)"; Integer)
        {
            Caption = 'Fallback Lead Time (Days)';
            DataClassification = CustomerContent;
            MinValue = 0;
            InitValue = 7;
        }
        field(13; "Include Safety Stock"; Boolean)
        {
            Caption = 'Add Item Safety Stock Quantity';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(14; "Round Up Result"; Boolean)
        {
            Caption = 'Round Up Result to Whole Units';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(15; "Update Item Field"; Boolean)
        {
            Caption = 'Auto-Update Item.Reorder Point';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(16; "Set Reordering Policy"; Boolean)
        {
            Caption = 'Set Policy to Fixed Reorder Qty. when None';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(17; "Skip Make-to-Order"; Boolean)
        {
            Caption = 'Skip Make-to-Order Items';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(18; "Log History"; Boolean)
        {
            Caption = 'Log Calculation History';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
