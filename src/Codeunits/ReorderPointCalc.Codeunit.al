codeunit 50300 "Reorder Point Calculator"
{
    Permissions = tabledata Item = rm,
                  tabledata "Reorder Point Calculation Log" = ri;

    var
        Setup: Record "Reorder Point Setup";
        SetupLoaded: Boolean;

    /// <summary>
    /// Calculates and (optionally) updates the Reorder Point for a single item.
    /// Reorder Point = (Average Daily Demand x Lead Time in days) + Safety Stock.
    /// Returns the calculated reorder point. Logs to history if enabled.
    /// </summary>
    procedure CalculateForItem(ItemNo: Code[20]; Apply: Boolean): Decimal
    var
        ResultCode: Enum "Reorder Point Result Code";
        Note: Text[250];
    begin
        exit(CalculateForItem(ItemNo, Apply, ResultCode, Note));
    end;

    procedure CalculateForItem(ItemNo: Code[20]; Apply: Boolean; var ResultCode: Enum "Reorder Point Result Code"; var Note: Text[250]): Decimal
    begin
        exit(RunCalc(ItemNo, Apply, true, ResultCode, Note));
    end;

    /// <summary>
    /// Calculates the Reorder Point WITHOUT applying it to the item and WITHOUT writing
    /// a log entry. Use for an interactive preview before the user confirms, so a
    /// cancelled preview never leaves a misleading "OK" row in the calculation log.
    /// </summary>
    procedure CalculatePreview(ItemNo: Code[20]; var ResultCode: Enum "Reorder Point Result Code"; var Note: Text[250]): Decimal
    begin
        exit(RunCalc(ItemNo, false, false, ResultCode, Note));
    end;

    local procedure RunCalc(ItemNo: Code[20]; Apply: Boolean; DoLog: Boolean; var ResultCode: Enum "Reorder Point Result Code"; var Note: Text[250]): Decimal
    var
        Item: Record Item;
        AvgDemand: Decimal;
        Observations: Integer;
        LeadTimeDays: Decimal;
        LeadTimeSource: Text[50];
        SafetyStock: Decimal;
        DemandDuringLT: Decimal;
        ReorderPoint: Decimal;
        PreviousRP: Decimal;
        Applied: Boolean;
    begin
        EnsureSetup();

        if not Item.Get(ItemNo) then
            exit(0);

        if Item.Blocked then begin
            ResultCode := ResultCode::"Item Blocked";
            Note := 'Item is blocked.';
            if DoLog then
                LogResult(Item, 0, 0, 0, '', 0, 0, 0, Item."Reorder Point", false, ResultCode, Note);
            exit(0);
        end;

        if Setup."Skip Make-to-Order" and IsMakeToOrder(Item) then begin
            ResultCode := ResultCode::"Make-to-Order Skipped";
            Note := 'Make-to-order item. Reorder point does not apply: supply is created per demand (Order policy / order-to-order binding).';
            if DoLog then
                LogResult(Item, 0, 0, 0, '', 0, 0, 0, Item."Reorder Point", false, ResultCode, Note);
            exit(0);
        end;

        ComputeAvgDailyDemand(ItemNo, AvgDemand, Observations);
        if Observations < Setup."Min Demand Observations" then begin
            ResultCode := ResultCode::"Insufficient Demand Data";
            Note := StrSubstNo('Only %1 demand observations found (minimum %2). No reliable demand rate.', Observations, Setup."Min Demand Observations");
            if DoLog then
                LogResult(Item, AvgDemand, Observations, 0, '', 0, 0, 0, Item."Reorder Point", false, ResultCode, Note);
            exit(0);
        end;

        DetermineLeadTime(Item, LeadTimeDays, LeadTimeSource);
        if LeadTimeDays <= 0 then begin
            ResultCode := ResultCode::"No Lead Time Data";
            Note := 'No lead time available: no receipt history, no Lead Time Calculation, and the setup fallback is 0.';
            if DoLog then
                LogResult(Item, AvgDemand, Observations, 0, '', 0, 0, 0, Item."Reorder Point", false, ResultCode, Note);
            exit(0);
        end;

        if Setup."Include Safety Stock" then
            SafetyStock := Item."Safety Stock Quantity"
        else
            SafetyStock := 0;

        DemandDuringLT := AvgDemand * LeadTimeDays;
        ReorderPoint := DemandDuringLT + SafetyStock;

        if Setup."Round Up Result" then
            ReorderPoint := Round(ReorderPoint, 1, '>');

        PreviousRP := Item."Reorder Point";

        if Apply and Setup."Update Item Field" then begin
            Item.Validate("Reorder Point", ReorderPoint);
            if Setup."Set Reordering Policy" and (Item."Reordering Policy" = Item."Reordering Policy"::" ") then
                Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
            Item.Modify(true);
            Applied := true;
        end;

        ResultCode := ResultCode::OK;
        Note := CopyStr(
            BuildReason(SafetyStock) + ' ' +
            StrSubstNo('ROP = (D %1/day x LT %2 d) + SS %3 = %4. Lead time from %5; n=%6 obs.',
                Format(Round(AvgDemand, 0.01), 0, 9), Format(Round(LeadTimeDays, 0.01), 0, 9),
                Format(Round(SafetyStock, 0.01), 0, 9), Format(ReorderPoint, 0, 9),
                LeadTimeSource, Observations),
            1, 250);

        if DoLog then
            LogResult(Item, AvgDemand, Observations, LeadTimeDays, LeadTimeSource, DemandDuringLT, SafetyStock, ReorderPoint, PreviousRP, Applied, ResultCode, Note);

        exit(ReorderPoint);
    end;

    /// <summary>
    /// Bulk calculation for items currently filtered on the Item record passed in.
    /// Make-to-order items are processed but skipped (logged), so the run is honest about coverage.
    /// </summary>
    procedure CalculateBulk(var ItemFilter: Record Item; Apply: Boolean): Integer
    var
        Item: Record Item;
        ProcessedCount: Integer;
        Window: Dialog;
        Total: Integer;
        Done: Integer;
    begin
        EnsureSetup();

        Item.CopyFilters(ItemFilter);
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);
        Total := Item.Count();
        if Total = 0 then
            exit(0);

        if GuiAllowed then begin
            Window.Open('Calculating Reorder Point...\#1######### / #2#########');
            Window.Update(2, Format(Total));
        end;

        if Item.FindSet() then
            repeat
                Done += 1;
                if GuiAllowed then
                    Window.Update(1, Format(Done));
                CalculateForItem(Item."No.", Apply);
                ProcessedCount += 1;
            until Item.Next() = 0;

        if GuiAllowed then
            Window.Close();
        exit(ProcessedCount);
    end;

    local procedure EnsureSetup()
    begin
        if not SetupLoaded then begin
            Setup.GetSetup();
            SetupLoaded := true;
        end;
    end;

    /// <summary>
    /// Single source of truth for "is this item make-to-order". Two signals point at the
    /// same thing: supply is pegged to a single demand, so there is no replenished stock
    /// level for a reorder point to defend.
    /// </summary>
    procedure IsMakeToOrder(Item: Record Item): Boolean
    begin
        if Item."Manufacturing Policy" = Item."Manufacturing Policy"::"Make-to-Order" then
            exit(true);
        if Item."Reordering Policy" = Item."Reordering Policy"::Order then
            exit(true);
        exit(false);
    end;

    /// <summary>
    /// Counts items in the given filter that a bulk run will skip as make-to-order, using
    /// the SAME definition and population (Type = Inventory, not Blocked) as CalculateBulk,
    /// so a pre-run warning matches what actually happens.
    /// </summary>
    procedure CountMakeToOrderSkipped(var ItemFilter: Record Item): Integer
    var
        Item: Record Item;
        SkipCount: Integer;
    begin
        EnsureSetup();
        if not Setup."Skip Make-to-Order" then
            exit(0);

        Item.CopyFilters(ItemFilter);
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);
        if Item.FindSet() then
            repeat
                if IsMakeToOrder(Item) then
                    SkipCount += 1;
            until Item.Next() = 0;
        exit(SkipCount);
    end;

    local procedure ComputeAvgDailyDemand(ItemNo: Code[20]; var AvgDemand: Decimal; var Observations: Integer)
    var
        ILE: Record "Item Ledger Entry";
        DailyDemand: Dictionary of [Date, Decimal];
        Sum_Qty: Decimal;
        qty: Decimal;
        WindowStart: Date;
        SellingDays: Integer;
        CalendarDays: Integer;
        d: Date;
    begin
        AvgDemand := 0;
        Observations := 0;

        WindowStart := CalcDate(StrSubstNo('<-%1D>', Setup."History Window (Days)"), Today);
        CalendarDays := Today - WindowStart + 1;
        if CalendarDays <= 0 then
            exit;

        ILE.SetCurrentKey("Item No.", "Posting Date");
        ILE.SetRange("Item No.", ItemNo);
        ILE.SetRange("Posting Date", WindowStart, Today);
        ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
        if not ILE.FindSet() then
            exit;

        // Sales post as negative quantity on the Item Ledger Entry; flip to positive demand.
        repeat
            qty := -ILE.Quantity;
            if qty > 0 then begin
                if DailyDemand.ContainsKey(ILE."Posting Date") then
                    DailyDemand.Set(ILE."Posting Date", DailyDemand.Get(ILE."Posting Date") + qty)
                else
                    DailyDemand.Add(ILE."Posting Date", qty);
            end;
        until ILE.Next() = 0;

        SellingDays := DailyDemand.Count;
        if SellingDays = 0 then
            exit;

        foreach d in DailyDemand.Keys do
            Sum_Qty += DailyDemand.Get(d);

        // Average over ALL calendar days in the window (zero-demand days count toward
        // the divisor), so the daily rate lines up with a calendar-day lead time.
        AvgDemand := Sum_Qty / CalendarDays;
        Observations := SellingDays;
    end;

    local procedure DetermineLeadTime(Item: Record Item; var LeadTimeDays: Decimal; var LeadTimeSource: Text[50])
    begin
        LeadTimeDays := 0;
        LeadTimeSource := '';

        case Item."Replenishment System" of
            Item."Replenishment System"::Purchase:
                begin
                    LeadTimeDays := ComputePurchaseLeadTime(Item."No.");
                    if LeadTimeDays > 0 then
                        LeadTimeSource := 'Purchase receipt history'
                    else begin
                        LeadTimeDays := DaysFromDateFormula(Item."Lead Time Calculation");
                        if LeadTimeDays > 0 then
                            LeadTimeSource := 'Item Lead Time Calculation';
                    end;
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    LeadTimeDays := DaysFromDateFormula(Item."Lead Time Calculation");
                    if LeadTimeDays > 0 then
                        LeadTimeSource := 'Manufacturing lead time';
                end;
            Item."Replenishment System"::Assembly:
                begin
                    LeadTimeDays := DaysFromDateFormula(Item."Lead Time Calculation");
                    if LeadTimeDays > 0 then
                        LeadTimeSource := 'Assembly lead time';
                end;
        end;

        if LeadTimeDays <= 0 then begin
            LeadTimeDays := Setup."Default Lead Time (Days)";
            LeadTimeSource := 'Setup fallback';
        end;
    end;

    local procedure ComputePurchaseLeadTime(ItemNo: Code[20]): Decimal
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Sum_LT: Decimal;
        n: Integer;
        LTDays: Decimal;
    begin
        // By design this averages ALL purchase-receipt history (not just the demand window):
        // lead time is a supplier-performance trait that is more stable with more samples,
        // whereas demand is windowed because it trends. If recent supplier performance has
        // shifted materially, prefer the Lead Time Calculation field over receipt history.
        PurchRcptLine.SetCurrentKey("No.");
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        if not PurchRcptLine.FindSet() then
            exit(0);

        repeat
            if (PurchRcptLine."Order Date" <> 0D) and (PurchRcptLine."Posting Date" <> 0D) then begin
                LTDays := PurchRcptLine."Posting Date" - PurchRcptLine."Order Date";
                if LTDays >= 0 then begin
                    Sum_LT += LTDays;
                    n += 1;
                end;
            end;
        until PurchRcptLine.Next() = 0;

        if n = 0 then
            exit(0);
        exit(Sum_LT / n);
    end;

    local procedure BuildReason(SafetyStock: Decimal): Text
    begin
        if SafetyStock > 0 then
            exit('Reorder point covers expected demand during the replenishment lead time, on top of the existing safety stock buffer.');
        exit('Reorder point covers expected demand during the replenishment lead time (no safety stock buffer set).');
    end;

    local procedure DaysFromDateFormula(DF: DateFormula): Decimal
    var
        Today2: Date;
        ResultDate: Date;
    begin
        if Format(DF) = '' then
            exit(0);
        Today2 := Today;
        ResultDate := CalcDate(DF, Today2);
        exit(ResultDate - Today2);
    end;

    local procedure LogResult(Item: Record Item; AvgD: Decimal; Obs: Integer; LeadTime: Decimal; LeadTimeSource: Text[50]; DemandDuringLT: Decimal; SafetyStock: Decimal; Result: Decimal; PrevResult: Decimal; Applied: Boolean; ResultCode: Enum "Reorder Point Result Code"; Note: Text[250])
    var
        LogEntry: Record "Reorder Point Calculation Log";
    begin
        EnsureSetup();
        if not Setup."Log History" then
            exit;
        LogEntry.Init();
        LogEntry."Item No." := Item."No.";
        LogEntry."Calculation DateTime" := CurrentDateTime;
        LogEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(LogEntry."User ID"));
        LogEntry."Avg Daily Demand" := AvgD;
        LogEntry."Demand Observations" := Obs;
        LogEntry."Lead Time (Days)" := LeadTime;
        LogEntry."Lead Time Source" := LeadTimeSource;
        LogEntry."Demand During Lead Time" := DemandDuringLT;
        LogEntry."Safety Stock Used" := SafetyStock;
        LogEntry."Replenishment System" := CopyStr(Format(Item."Replenishment System"), 1, MaxStrLen(LogEntry."Replenishment System"));
        LogEntry."Calculated Reorder Point" := Result;
        LogEntry."Previous Reorder Point" := PrevResult;
        LogEntry.Applied := Applied;
        LogEntry."Result Code" := ResultCode;
        LogEntry.Note := Note;
        LogEntry.Insert(true);
    end;
}
