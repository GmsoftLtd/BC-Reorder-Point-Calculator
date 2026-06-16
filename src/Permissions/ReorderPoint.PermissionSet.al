permissionset 50300 "Reorder Point"
{
    Assignable = true;
    Caption = 'Reorder Point - All';

    Permissions = tabledata "Reorder Point Setup" = RIMD,
                  tabledata "Reorder Point Calculation Log" = RIMD;
}
