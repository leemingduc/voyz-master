# Vietnam tourism data baseline for Explore and AI suggestions (research, 2026-10-09)

Audience: Voyz project. This note identifies defensible numbers for explaining the app's relevance and for displaying *estimates* in Explore and AI suggestions. It does **not** treat any price below as a live quote.

## Short answer

Vietnam travel is large enough, fast-growing enough, and price-variable enough to justify a planning aid: official 2025 figures record nearly **21.2 million international arrivals**, **137 million domestic trips**, and roughly **VND 1 quadrillion** in tourism receipts. Prices should be presented as an **AI estimate / planning range**, with travel dates and source clearly shown; only a live supplier checkout can be called a price.

## Evidence for the problem the app solves

| Official measure | Latest usable figure | Why it matters |
| --- | --- | --- |
| International arrivals | Nearly 21.2 million in 2025, +20.4% year-on-year | Fast-changing demand makes static destination and cost assumptions unreliable. |
| Domestic trips | 137 million in 2025 | The core domestic-trip flow serves a very large planning audience. |
| Tourism receipts | About VND 1 quadrillion in 2025 | It is material consumer spending, so helping users compare a plan and budget is meaningful. |
| Accommodation & food-service revenue | VND 767.8 trillion in Jan–Nov 2025, +14.6% YoY | Accommodation is a major, changing trip-cost component. |
| Travel-service revenue | VND 85.4 trillion in Jan–Nov 2025, +19.9% YoY | Demand and purchasing activity are growing quickly. |

Sources: [National Statistics Office (NSO), 2025 year-end release](https://www.nso.gov.vn/en/data-and-statistics/2026/01/socio-economic-situation-in-the-fourth-quarter-and-2025/) (21.2m arrivals and +20.4%); [Vietnam National Authority of Tourism (VNAT), 2025 summary](https://vietnamtourism.gov.vn/printer/66328) (137m domestic trips and about VND 1 quadrillion); [VNAT/Tourism Information Technology Center, Jan–Nov 2025](https://vietnamtourism.gov.vn/en/post/21480) (revenue figures, compiled from NSO data).

## Transport: a safe baseline, not a quotation

For basic domestic economy airfare sold in Vietnam, the Ministry of Transport's effective framework groups routes by distance and sets maximum base fares of **VND 1.6m** for socio-economic routes under 500 km, **VND 1.7m** for other routes under 500 km, then **VND 2.25m**, **2.89m**, **3.40m**, and **4.00m** for the successive 500–<850, 850–<1,000, 1,000–<1,280 and >=1,280 km groups. The caps exclude VAT and certain statutory airport/security charges, so they are not an all-in ticket price. [Circular 34/2023/TT-BGTVT](https://vanban.chinhphu.vn/?classid=1&docid=209156&pageid=27160), effective 2024-03-01, is the governing primary source.

The Civil Aviation Authority's published August 2024 market check also illustrates variability: Hanoi–Phu Quoc's VND 4.0m regulated maximum contrasted with a then-highest observed Vietnam Airlines base fare of VND 3.05m; other dates had tickets at 30–50% of the maximum. This supports using a date-specific range, rather than a single "real" fare. [CAA release](https://caa.gov.vn/Pages/Print.aspx?NewsId=20240802125845245).

**App rule:** label every generated airfare `Ước tính vé một chiều, chưa gồm thuế/phí — kiểm tra lại khi đặt`; do not add fees unless a live provider has supplied them. Do not represent the regulatory ceiling as an expected ticket price.

## Accommodation: do not invent a national official price range

I found official demand/revenue statistics, but no national government tariff or verified public API that supplies current room prices by destination, dates and room type. A generic "hotel VND X–Y/night" would therefore be an AI planning estimate, not official data. It is acceptable only when clearly labeled, for example: `Ước tính lưu trú/đêm (mùa, hạng phòng và số khách có thể làm thay đổi giá)`.

For the capstone, keep the estimate simple: choose a conservative destination-specific range in seeded content, show its assumptions (one room, one night, number of guests), and never store it as a historical/actual booking price. For current quotes, link out to a booking flow or integrate a supplier only after its API/terms are approved; this research did not verify a suitable official accommodation-price API.

## Official data to refresh Explore, not to quote as live prices

- [VNAT Statistics: International visitors](https://vietnamtourism.gov.vn/en/statistic/international) provides monthly arrival statistics by period/year. It is suitable for an Explore insight such as `Nguồn: Cục Du lịch Quốc gia Việt Nam, tháng/năm ...`, not for price calculation.
- [VNAT tourism operations dashboard](https://dash.vietnamtourism.gov.vn/) exposes public aggregate indicators (arrivals, rated accommodation establishments, international travel businesses and reporting coverage). It is a dashboard, not a documented public API; do not depend on undocumented endpoints.
- [NSO's statistical releases](https://www.nso.gov.vn/en/data-and-statistics/) are the primary source behind nationwide monthly/annual arrival, transport and service-revenue figures. Refresh a small manually reviewed app fact rather than have Gemini fabricate a current statistic.

## Implementation wording for Explore and Gemini output

1. Present a total only as `Tổng chi phí ước tính`; show its breakdown (transport, stay, activities) and assumptions.
2. Require Gemini to state `ước tính` beside every VND amount and to avoid claims of availability, promotions or exact fares.
3. Keep `Nguồn số liệu du lịch` separate from `Ước tính chi phí`: the former is an official dated statistic; the latter is a planning heuristic.
4. The user must re-check final prices at the airline/hotel supplier before booking.

This distinction satisfies the repository rule that AI-generated numbers are estimates and must not be stored as real data.
