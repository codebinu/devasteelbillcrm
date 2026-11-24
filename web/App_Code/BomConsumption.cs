using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;

// Generic, batch-aware raw-material consumption engine for BOM based production.
//
// The engine is pure (no database, no web types): callers load the finished good (Item Master), the BOM line and the actual raw-material batch
// (tbl_item_batch) and pass them in. Every calculation method implements IConsumptionMethod and is registered in BomConsumption, so new
// methods can be added without touching production.
//
// Built-in method BATCH_WEIGHT_PER_METRE (the "coil" method):
//   kg per metre of raw material  = batch weight / batch length                       (tbl_item_batch: itbh_kg / (itbh_length x itbh_no_piece))
//   raw metres per finished unit  = 1 / finished width (m) for Area goods (SQMT), 1 for Length goods (MTR)   (Item Master: itsv_spec_width)
//   consumption factor (kg/unit)  = kg per metre x raw metres per finished unit x BOM multiplier
//   total requirement (kg)        = consumption factor x production quantity
// The requirement is converted to the batch's own stock UOM through the batch's own weight-to-quantity ratio
// (itbh_startqty / itbh_kg), so it is deducted from exactly the batch it was calculated for.

// What the finished good measures: decides how raw-material length relates to one finished unit.
public enum ConsumptionBasis
{
    Unsupported = 0,
    Length = 1,
    Area = 2
}

// Actual properties of one raw-material batch, as stored in tbl_item_batch. Zero means "not recorded".
public sealed class BatchProfile
{
    public int BatchId;
    public string BatchNo;
    public decimal WeightKg;
    // Length per unit (itbh_length) and the number of units (itbh_no_piece); the batch length is their product.
    public decimal LengthPerUnit;
    public decimal Pieces;
    // Quantity the batch was received with / still holds, both in the batch's stock UOM.
    public decimal StartQty;

    public decimal TotalLength
    {
        get { return LengthPerUnit * (Pieces > 0m ? Pieces : 1m); }
    }
}

public sealed class ConsumptionInput
{
    public string FinishedName;
    public string MaterialName;
    public ConsumptionBasis Basis;
    // Finished item width in metres (Item Master), required for Area goods.
    public decimal? FinishedWidthMetres;
    // BOM quantity of the line: how many raw-material layers/units go into one finished unit (1 for a normal line).
    public decimal Multiplier;
    public BatchProfile Batch;
}

// Per-unit result for one batch. All "PerUnit" figures are per ONE finished base unit (1 SQMT for Area goods, 1 MTR for Length goods).
public sealed class ConsumptionFactor
{
    public bool Ok { get { return Errors.Count == 0; } }
    public List<string> Errors = new List<string>();
    public string Method;
    public decimal KgPerMetre;
    public decimal MetresPerUnit;
    public decimal KgPerUnit;
    // Raw material in the batch's own stock UOM for one finished base unit.
    public decimal BatchQtyPerUnit;
}

public interface IConsumptionMethod
{
    string Code { get; }
    string Name { get; }
    ConsumptionFactor Calculate(ConsumptionInput input);
}

// A batch the production may draw from and how much of it is available (in the batch's stock UOM), in the order it is to be used.
public sealed class BatchSlice
{
    public BatchProfile Batch;
    public decimal AvailableQty;
    public object Tag;
}

public sealed class BatchAllocation
{
    public BatchSlice Slice;
    public ConsumptionFactor Factor;
    // Finished base units this batch covers, the kg it gives up and the quantity deducted from it (its stock UOM).
    public decimal FinishedUnits;
    public decimal Kg;
    public decimal Metres;
    public decimal BatchQty;
}

public sealed class AllocationResult
{
    public List<BatchAllocation> Rows = new List<BatchAllocation>();
    public List<string> Errors = new List<string>();
    // Finished base units that no batch could cover.
    public decimal Shortfall;
    public decimal TotalKg;
    public decimal TotalBatchQty;
    public bool Ok { get { return Errors.Count == 0 && Shortfall <= 0m; } }
}

public static class BomConsumption
{
    public const string MethodFixed = "FIXED";
    public const string MethodBatchWeightPerMetre = "BATCH_WEIGHT_PER_METRE";

    static readonly Dictionary<string, IConsumptionMethod> Methods = new Dictionary<string, IConsumptionMethod>(StringComparer.OrdinalIgnoreCase);

    static BomConsumption()
    {
        Register(new BatchWeightPerMetreMethod());
    }

    public static void Register(IConsumptionMethod method)
    {
        lock (Methods)
            Methods[method.Code] = method;
    }

    // A blank method or FIXED means the BOM line keeps its fixed quantity per unit (the original behaviour).
    public static bool IsDynamic(string code)
    {
        return !string.IsNullOrWhiteSpace(code) && !string.Equals(code.Trim(), MethodFixed, StringComparison.OrdinalIgnoreCase);
    }

    public static IConsumptionMethod Find(string code)
    {
        IConsumptionMethod m;
        lock (Methods)
            return code != null && Methods.TryGetValue(code.Trim(), out m) ? m : null;
    }

    public static string Describe(string code)
    {
        IConsumptionMethod m = Find(code);
        return m == null ? code : m.Name;
    }

    public static ConsumptionFactor Calculate(string code, ConsumptionInput input)
    {
        IConsumptionMethod m = Find(code);
        if (m != null)
            return m.Calculate(input);
        var f = new ConsumptionFactor { Method = code };
        f.Errors.Add("Unknown consumption method '" + code + "' on the BOM line of " + input.MaterialName + ".");
        return f;
    }

    // Quantity (finished base units) -> total requirement for one batch. Nothing is rounded here: callers round at the column they write to.
    public static decimal RequiredKg(ConsumptionFactor f, decimal finishedUnits) { return f.KgPerUnit * finishedUnits; }
    public static decimal RequiredMetres(ConsumptionFactor f, decimal finishedUnits) { return f.KgPerMetre > 0m ? f.KgPerUnit * finishedUnits / f.KgPerMetre : 0m; }
    public static decimal RequiredBatchQty(ConsumptionFactor f, decimal finishedUnits) { return f.BatchQtyPerUnit * finishedUnits; }

    // Finished base units a batch can still make from the quantity it has available.
    public static decimal Capacity(ConsumptionFactor f, decimal availableQty)
    {
        return f.Ok && f.BatchQtyPerUnit > 0m && availableQty > 0m ? availableQty / f.BatchQtyPerUnit : 0m;
    }

    // Spreads quantity (finished base units) over the batches in the order given, each batch with ITS OWN factor. A batch is used up before the next one
    // is touched; the quantity taken from a partly used batch is rounded UP to quantityDecimals (the precision stock is stored with) but never above
    // what the batch has. Any batch that is needed but cannot be calculated is reported, never skipped.
    public static AllocationResult Allocate(string code, ConsumptionInput template, IEnumerable<BatchSlice> slices, decimal quantity, int quantityDecimals)
    {
        var result = new AllocationResult();
        decimal left = quantity;
        foreach (BatchSlice slice in slices)
        {
            if (left <= 0m)
                break;
            if (slice.AvailableQty <= 0m)
                continue;
            ConsumptionInput input = ForBatch(template, slice.Batch);
            ConsumptionFactor f = Calculate(code, input);
            if (!f.Ok)
            {
                foreach (string e in f.Errors)
                    if (!result.Errors.Contains(e))
                        result.Errors.Add(e);
                continue;
            }
            decimal capacity = Capacity(f, slice.AvailableQty);
            decimal take = Math.Min(left, capacity);
            if (take <= 0m)
                continue;
            decimal batchQty = take >= capacity ? slice.AvailableQty : Math.Min(slice.AvailableQty, RoundUp(RequiredBatchQty(f, take), quantityDecimals));
            result.Rows.Add(new BatchAllocation
            {
                Slice = slice,
                Factor = f,
                FinishedUnits = take,
                Kg = RequiredKg(f, take),
                Metres = RequiredMetres(f, take),
                BatchQty = batchQty
            });
            result.TotalKg += RequiredKg(f, take);
            result.TotalBatchQty += batchQty;
            left -= take;
        }
        result.Shortfall = left > 0m ? left : 0m;
        return result;
    }

    // Finished base units the batches can make in total (invalid batches add nothing and their problems are listed).
    public static decimal TotalCapacity(string code, ConsumptionInput template, IEnumerable<BatchSlice> slices, List<string> errors)
    {
        decimal total = 0m;
        foreach (BatchSlice slice in slices)
        {
            if (slice.AvailableQty <= 0m)
                continue;
            ConsumptionFactor f = Calculate(code, ForBatch(template, slice.Batch));
            if (!f.Ok)
            {
                foreach (string e in f.Errors)
                    if (errors != null && !errors.Contains(e))
                        errors.Add(e);
                continue;
            }
            total += Capacity(f, slice.AvailableQty);
        }
        return total;
    }

    // A copy of the calculation input for one particular batch.
    public static ConsumptionInput ForBatch(ConsumptionInput t, BatchProfile batch)
    {
        return new ConsumptionInput
        {
            FinishedName = t.FinishedName,
            MaterialName = t.MaterialName,
            Basis = t.Basis,
            FinishedWidthMetres = t.FinishedWidthMetres,
            Multiplier = t.Multiplier,
            Batch = batch
        };
    }

    static decimal RoundUp(decimal value, int decimals)
    {
        decimal scale = 1m;
        for (int i = 0; i < decimals; i++)
            scale *= 10m;
        // The 1e-9 guard stops a value that is exact at the target precision (e.g. 2.5 x 4 = 10.000000000001 after division) from being pushed up a step.
        return Math.Ceiling(value * scale - 0.000000001m) / scale;
    }

    // Maps a UOM category name from tbl_item_uom_type to the basis the calculation works on.
    public static ConsumptionBasis BasisOf(string uomTypeName)
    {
        string n = (uomTypeName ?? "").Trim();
        if (string.Equals(n, "Area", StringComparison.OrdinalIgnoreCase))
            return ConsumptionBasis.Area;
        if (string.Equals(n, "Length", StringComparison.OrdinalIgnoreCase))
            return ConsumptionBasis.Length;
        return ConsumptionBasis.Unsupported;
    }

    // Raw materials received by length, area or weight (coils in KG) are consumed from the actual batch: kg per metre = batch kg / batch length.
    public static bool IsBatchMeasured(string uomTypeName)
    {
        return BasisOf(uomTypeName) != ConsumptionBasis.Unsupported
            || string.Equals((uomTypeName ?? "").Trim(), "Weight", StringComparison.OrdinalIgnoreCase);
    }

    // The calculation is done in metres and square metres, so the default UOM of the Area / Length category has to be one of those.
    public static string CheckBaseUnit(ConsumptionBasis basis, string defaultUomName)
    {
        string n = (defaultUomName ?? "").Trim().ToUpperInvariant();
        string[] metre = { "M", "MTR", "MTRS", "METER", "METERS", "METRE", "METRES" };
        string[] squareMetre = { "SQMT", "SQM", "SQMTR", "SQMTRS", "M2", "SQ.M", "SQ.MTR" };
        if (basis == ConsumptionBasis.Length && Array.IndexOf(metre, n) < 0)
            return "The default Length UOM is '" + defaultUomName + "' but the calculation works in metres. Set the default Length UOM to metres (MTR).";
        if (basis == ConsumptionBasis.Area && Array.IndexOf(squareMetre, n) < 0)
            return "The default Area UOM is '" + defaultUomName + "' but the calculation works in square metres. Set the default Area UOM to square metres (SQMT).";
        return null;
    }

    static readonly Regex DimensionPattern = new Regex(
        "^\\s*(\\d+(?:\\.\\d+)?|\\.\\d+)\\s*(MM|CM|M|MTR|MTRS|METER|METERS|METRE|METRES|FT|FEET|FOOT|IN|INCH|INCHES|'|\")?\\s*$",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

    // Item Master spec values are text such as "1.10M", "0.45MM", "8 FEET" or 10". A value without a unit is taken as metres.
    // 0.3048 m per foot and 0.0254 m per inch are the exact definitions.
    public static bool TryParseMetres(string text, out decimal metres, out string error)
    {
        metres = 0m;
        error = null;
        string t = (text ?? "").Replace("&quot;", "\"").Trim();
        if (t.Length == 0)
        {
            error = "no value";
            return false;
        }
        Match m = DimensionPattern.Match(t);
        decimal value;
        if (!m.Success || !decimal.TryParse(m.Groups[1].Value, NumberStyles.Number, CultureInfo.InvariantCulture, out value))
        {
            error = "'" + t + "' is not a recognised dimension";
            return false;
        }
        string unit = m.Groups[2].Value.ToUpperInvariant();
        decimal factor;
        switch (unit)
        {
            case "MM": factor = 0.001m; break;
            case "CM": factor = 0.01m; break;
            case "FT":
            case "FEET":
            case "FOOT":
            case "'": factor = 0.3048m; break;
            case "IN":
            case "INCH":
            case "INCHES":
            case "\"": factor = 0.0254m; break;
            case "": factor = 1m; break;
            default: factor = 1m; break;
        }
        if (unit == "" && value >= 10m)
        {
            error = "'" + t + "' has no unit and is too large to be metres; write it with a unit such as 1.10M or 1100MM";
            return false;
        }
        metres = value * factor;
        if (metres <= 0m)
        {
            error = "'" + t + "' must be greater than zero";
            return false;
        }
        return true;
    }

    sealed class BatchWeightPerMetreMethod : IConsumptionMethod
    {
        public string Code { get { return MethodBatchWeightPerMetre; } }
        public string Name { get { return "Batch weight per metre"; } }

        public ConsumptionFactor Calculate(ConsumptionInput input)
        {
            var f = new ConsumptionFactor { Method = Code };
            string material = string.IsNullOrEmpty(input.MaterialName) ? "the raw material" : input.MaterialName;
            string finished = string.IsNullOrEmpty(input.FinishedName) ? "the finished item" : input.FinishedName;
            BatchProfile b = input.Batch;
            string batch = b == null ? "" : (string.IsNullOrEmpty(b.BatchNo) ? "#" + b.BatchId : b.BatchNo);

            if (b == null)
                f.Errors.Add("The selected batch of " + material + " was not found in the batch records.");
            else
            {
                if (b.WeightKg <= 0m)
                    f.Errors.Add("Batch " + batch + " of " + material + " has no weight (Total KG). Enter the batch weight before producing.");
                if (b.TotalLength <= 0m)
                    f.Errors.Add("Batch " + batch + " of " + material + " has no length. Enter the batch length before producing.");
                if (b.StartQty <= 0m)
                    f.Errors.Add("Batch " + batch + " of " + material + " has no received quantity, so its weight cannot be matched to stock.");
            }
            if (input.Multiplier <= 0m)
                f.Errors.Add("The BOM quantity of " + material + " must be greater than zero.");

            decimal metresPerUnit = 0m;
            if (input.Basis == ConsumptionBasis.Area)
            {
                if (!input.FinishedWidthMetres.HasValue || input.FinishedWidthMetres.Value <= 0m)
                    f.Errors.Add("The width of " + finished + " is not configured in the Item Master (Spec Width). It is needed to convert square metres to raw-material length.");
                else
                    metresPerUnit = 1m / input.FinishedWidthMetres.Value;
            }
            else if (input.Basis == ConsumptionBasis.Length)
                metresPerUnit = 1m;
            else
                f.Errors.Add("The sales UOM of " + finished + " must be a Length or Area unit for the weight-per-metre calculation.");

            if (f.Errors.Count > 0)
                return f;

            f.KgPerMetre = b.WeightKg / b.TotalLength;
            f.MetresPerUnit = metresPerUnit;
            f.KgPerUnit = f.KgPerMetre * metresPerUnit * input.Multiplier;
            f.BatchQtyPerUnit = f.KgPerUnit * b.StartQty / b.WeightKg;
            return f;
        }
    }
}
