enum 50300 "Reorder Point Result Code"
{
    Extensible = true;

    value(0; OK)
    {
        Caption = 'OK';
    }
    value(1; "Insufficient Demand Data")
    {
        Caption = 'Insufficient Demand Data';
    }
    value(2; "No Lead Time Data")
    {
        Caption = 'No Lead Time Data';
    }
    value(3; "Make-to-Order Skipped")
    {
        Caption = 'Make-to-Order Skipped';
    }
    value(4; "Item Blocked")
    {
        Caption = 'Item Blocked';
    }
    value(5; "Skipped By Filter")
    {
        Caption = 'Skipped By Filter';
    }
    value(99; Error)
    {
        Caption = 'Error';
    }
}
