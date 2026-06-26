/// <summary>
/// Tests for the BC Reorder Point Calculator ("Reorder Point Calculator" codeunit).
/// </summary>
codeunit 59300 "Reorder Point Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure ReturnsItemBlockedForBlockedItem()
    var
        Item: Record Item;
        Calc: Codeunit "Reorder Point Calculator";
        ResultCode: Enum "Reorder Point Result Code";
        Note: Text[250];
        Result: Decimal;
    begin
        // [GIVEN] A blocked item
        CreateItem(Item);
        Item.Blocked := true;
        Item.Modify();

        // [WHEN] Calculating a reorder point preview
        Result := Calc.CalculatePreview(Item."No.", ResultCode, Note);

        // [THEN] It is skipped with the Item Blocked result code
        LibraryAssert.AreEqual(ResultCode::"Item Blocked", ResultCode, 'Blocked item should yield Item Blocked');
        LibraryAssert.AreEqual(0, Result, 'Blocked item should return 0');
    end;

    [Test]
    procedure ReturnsInsufficientDataWithoutDemand()
    var
        Item: Record Item;
        Calc: Codeunit "Reorder Point Calculator";
        ResultCode: Enum "Reorder Point Result Code";
        Note: Text[250];
    begin
        // [GIVEN] An item with no sales history
        CreateItem(Item);

        // [WHEN] Calculating a reorder point preview
        Calc.CalculatePreview(Item."No.", ResultCode, Note);

        // [THEN] It is skipped due to insufficient demand data
        LibraryAssert.AreEqual(ResultCode::"Insufficient Demand Data", ResultCode, 'No demand should yield Insufficient Demand Data');
    end;

    [Test]
    procedure CalculatesPositiveReorderPointWithLeadTimeFallback()
    var
        Item: Record Item;
        Setup: Record "Reorder Point Setup";
        Calc: Codeunit "Reorder Point Calculator";
        ResultCode: Enum "Reorder Point Result Code";
        Note: Text[250];
        Result: Decimal;
    begin
        // [GIVEN] Setup accepting 2 observations, no safety stock, default lead time fallback (7 days)
        Setup.GetSetup();
        Setup."Min Demand Observations" := 2;
        Setup."Include Safety Stock" := false;
        Setup."Default Lead Time (Days)" := 7;
        Setup."Skip Make-to-Order" := false;
        Setup.Modify();

        CreateItem(Item);
        CreateSale(Item."No.", CalcDate('<-5D>', Today), 10);
        CreateSale(Item."No.", CalcDate('<-10D>', Today), 4);

        // [WHEN] Calculating a reorder point preview
        Result := Calc.CalculatePreview(Item."No.", ResultCode, Note);

        // [THEN] Reorder point = avg demand x lead time is positive
        LibraryAssert.AreEqual(ResultCode::OK, ResultCode, 'Demand plus lead-time fallback should succeed');
        LibraryAssert.IsTrue(Result > 0, 'Reorder point should be greater than zero');
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := CopyStr('RPTEST-' + Format(Random(999999)), 1, MaxStrLen(Item."No."));
        Item.Type := Item.Type::Inventory;
        Item."Replenishment System" := Item."Replenishment System"::Purchase;
        Item.Insert(true);
    end;

    local procedure CreateSale(ItemNo: Code[20]; PostingDate: Date; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastEntry: Record "Item Ledger Entry";
        NextEntryNo: Integer;
    begin
        if LastEntry.FindLast() then
            NextEntryNo := LastEntry."Entry No." + 1
        else
            NextEntryNo := 1;
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := NextEntryNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Sale;
        ItemLedgerEntry.Quantity := -Qty; // sales post as negative quantity
        ItemLedgerEntry.Insert(false);
    end;
}
