---
name: copilot-credit-pacing
description: Calculates where Copilot credit usage should be this month. Counts Monday-Friday working days minus Canada federal statutory holidays, divides the 1900-credit monthly allowance across them, and reports expected usage up to today. Use when the user asks how many Copilot credits they should have used, their pacing, daily credit allowance, or where usage should be this month. Does not fetch actual usage.
---

# Copilot Credit Pacing

Work out the expected Copilot credit usage for the current month. Do not retrieve actual usage.

## Steps

1. Run the bundled script from any directory:

   ```bash
   python3 /home/brandon/.agents/skills/copilot-credit-pacing/scripts/pacing.py
   ```

   To evaluate a different date, add `--date YYYY-MM-DD`. To change the allowance, add `--budget <credits>` (default 1900).

2. Report the script output to the user. Include:
   - Working days this month, and which federal holidays were excluded
   - Credits per working day
   - Calendar days completed and working days completed
   - Expected usage in credits and as a percentage, plus the expected remaining amount

## Rules

- Working days are Monday to Friday. Weekend holidays do not reduce the count.
- Holidays come from the Canada Labour Code list: New Year's Day, Good Friday, Victoria Day, Canada Day, Labour Day, National Day for Truth and Reconciliation, Thanksgiving, Remembrance Day, Christmas Day, and Boxing Day. Family Day, Easter Monday, and other provincial holidays are not excluded.
- Today is not counted as elapsed. Expected usage covers only fully completed working days.
- Credits per working day = monthly allowance / working days in the month (for example, 1900 / 20 = 95).
