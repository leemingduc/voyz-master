# Voyz Travel Planning

This context covers travel planning information presented to Voyz users, including trip budgets and their monetary representation.

## Money

**Multi-currency converter**:
A travel-planning capability that converts monetary values between any supported currency; it is not limited to a traveller's home currency or destination currency.
_Avoid_: Vietnam-only converter, foreign-currency mode

**Display currency**:
The user's selected default currency for showing every trip budget and estimated price throughout Voyz. It is a presentation preference, not the currency in which the traveller actually pays.
_Avoid_: VND button, home currency, payment currency

**Original amount**:
The amount and currency in which a travel price or estimate was supplied before it is converted for display. It remains available alongside its displayed conversion.
_Avoid_: raw price, original-price text

**Exchange rate**:
The online-sourced reference rate used to convert an original amount into the user's display currency. It has a recorded retrieval time and is not a payment or cash-exchange guarantee.
_Avoid_: live price, guaranteed rate
