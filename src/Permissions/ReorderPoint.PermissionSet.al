permissionset 50300 "Reorder Point"
{
    Assignable = true;
    Caption = 'Reorder Point - All';

    Permissions = tabledata "Reorder Point Setup" = RIMD,
                  tabledata "Reorder Point Calculation Log" = RIMD,
                  table "Reorder Point Setup" = X,
                  table "Reorder Point Calculation Log" = X,
                  codeunit "Reorder Point Calculator" = X,
                  codeunit "Reorder Point Job Queue Run" = X,
                  page "Reorder Point Setup" = X,
                  page "Reorder Point Calculation Log" = X;
}
