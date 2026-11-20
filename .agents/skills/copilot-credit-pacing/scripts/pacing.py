#!/usr/bin/env python3
"""Compute where Copilot credit usage should be this month, pro-rated over Canada federal working days."""
import argparse
import calendar
import datetime as dt


def easter(year):
    # Anonymous Gregorian algorithm
    a = year % 19
    b, c = divmod(year, 100)
    d, e = divmod(b, 4)
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = divmod(c, 4)
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month, day = divmod(h + l - 7 * m + 114, 31)
    return dt.date(year, month, day + 1)


def nth_weekday(year, month, weekday, n):
    """n-th weekday (Mon=0) of a month; n=-1 means last."""
    if n > 0:
        first = dt.date(year, month, 1)
        offset = (weekday - first.weekday()) % 7
        return first + dt.timedelta(days=offset + 7 * (n - 1))
    last = dt.date(year, month, calendar.monthrange(year, month)[1])
    return last - dt.timedelta(days=(last.weekday() - weekday) % 7)


def federal_holidays(year):
    """Canada Labour Code federal statutory holidays, keyed by actual date."""
    # Victoria Day is the Monday preceding May 25.
    may25 = dt.date(year, 5, 25)
    victoria = may25 - dt.timedelta(days=may25.weekday() or 7)
    return {
        dt.date(year, 1, 1): "New Year's Day",
        easter(year) - dt.timedelta(days=2): "Good Friday",
        victoria: "Victoria Day",
        dt.date(year, 7, 1): "Canada Day",
        nth_weekday(year, 9, 0, 1): "Labour Day",
        dt.date(year, 9, 30): "National Day for Truth and Reconciliation",
        nth_weekday(year, 10, 0, 2): "Thanksgiving Day",
        dt.date(year, 11, 11): "Remembrance Day",
        dt.date(year, 12, 25): "Christmas Day",
        dt.date(year, 12, 26): "Boxing Day",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--budget", type=float, default=1900, help="Monthly credit allowance (default 1900)")
    parser.add_argument("--date", help="Date to evaluate as YYYY-MM-DD (default: today)")
    args = parser.parse_args()

    today = dt.date.fromisoformat(args.date) if args.date else dt.date.today()
    year, month = today.year, today.month
    days_in_month = calendar.monthrange(year, month)[1]
    holidays = {d: name for d, name in federal_holidays(year).items() if d.month == month and d.weekday() < 5}

    weekdays = [dt.date(year, month, d) for d in range(1, days_in_month + 1)]
    weekdays = [d for d in weekdays if d.weekday() < 5]
    working_days = [d for d in weekdays if d not in holidays]

    # Today is excluded: only fully completed days count.
    completed_working = [d for d in working_days if d < today]
    completed_calendar = today.day - 1

    per_day = args.budget / len(working_days)
    expected_credits = per_day * len(completed_working)
    expected_pct = expected_credits / args.budget * 100

    print(f"Date evaluated:          {today.isoformat()} ({today.strftime('%A')})")
    print(f"Monthly allowance:       {args.budget:,.0f} credits")
    print(f"Weekdays in month:       {len(weekdays)}")
    for d, name in sorted(holidays.items()):
        print(f"  - excluded {d.isoformat()} ({d.strftime('%a')}): {name}")
    print(f"Working days this month: {len(working_days)}")
    print(f"Credits per working day: {per_day:,.2f}")
    print()
    print(f"Calendar days completed: {completed_calendar} of {days_in_month}")
    print(f"Working days completed:  {len(completed_working)} of {len(working_days)} (today not counted)")
    print(f"Expected usage:          {expected_credits:,.2f} credits ({expected_pct:.1f}% of allowance)")
    print(f"Expected remaining:      {args.budget - expected_credits:,.2f} credits ({100 - expected_pct:.1f}%)")


if __name__ == "__main__":
    main()
