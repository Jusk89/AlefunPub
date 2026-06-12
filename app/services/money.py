from decimal import Decimal, ROUND_HALF_UP

MONEY_QUANT = Decimal("0.01")


def money(value: Decimal) -> Decimal:
    """Normalize monetary and bonus values to two decimal places."""
    return Decimal(value).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)
