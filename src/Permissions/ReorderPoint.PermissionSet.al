/// <summary>
/// Assignable permission set granting full access to all Reorder Point objects: the setup
/// and calculation log tables (with data) and the calculator, job queue, demo-data
/// codeunits and pages.
/// </summary>
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
                  codeunit "Reorder Point Demo Data" = X,
                  page "Reorder Point Setup" = X,
                  page "Reorder Point Calculation Log" = X;
}
