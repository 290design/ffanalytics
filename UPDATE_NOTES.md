# Upstream refresh and projection cache correction

Includes upstream through 42711a0 (3.1.18): updated player IDs and bundled model coefficients, Yahoo's 2026 ADP endpoint, FantasyPros ranking parser, and scoring helpers. Preserves our ESPN appliedTotal capture and FantasySharks unmapped-season validation.

Projection caches now require matching provider, season, week, and position coverage. Missing or mismatched metadata clears the old entry before fetching and storing replacement data. This fixes season -> weekly and week -> week contamination, including small season totals that pass magnitude thresholds. FantasyPros writes to its own cache file rather than WalterFootball's.

Validation:
- `R CMD INSTALL --library=/tmp/ffanalytics-library .` succeeded.
- `R_LIBS=/tmp/ffanalytics-library Rscript tests/projection-cache.R`: 36 adapter/cache scenarios plus week/ROS checks passed using isolated cache fixtures. Rejected entries are removed and replaceable.
- Live CBS TE season -> Week 1 -> repeated Week 1: fresh weekly fetch followed by same-period cache reuse; Bentley absent from weekly data.
- Live Yahoo ADP: 200 rows. Live FantasyPros draft PPR rankings: 551 rows.

Bundled coefficients remain available to model/scoring functions. Including them does not enable a new scoring model or change the ETL database schema. ADP production routing is unchanged.
