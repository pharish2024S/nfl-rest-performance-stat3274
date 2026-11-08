# NFL Rest Advantage and Team Performance

**Virginia Tech | STAT 3274: Sports Analytics | Fall 2026**  
**Project track:** Original Empirical Research (Track A)  
**Team:** Pranav Harish, Nate Mertz, Momen Muneer

## Research question

**How does a team's rest advantage, relative to its opponent, relate to its on-field performance and probability of winning an NFL game?**

We investigate two complementary outcomes:

1. **Offensive efficiency:** Whether relative rest is associated with a change in offensive expected points added per play (EPA/play), assessed using multiple linear regression.
2. **Game outcome:** Whether relative rest is associated with the home team's probability of winning, assessed using logistic regression.

Both models use the same core predictor, **rest differential** (`home_rest - away_rest`), and will be compared with otherwise similar baseline models that omit rest. The goal is to examine associations and out-of-sample predictive value, **not** to claim that rest causes a change in performance.

### Intended stakeholders

NFL coaches and coaching staffs, team management, and league scheduling officials may find evidence about scheduling-related performance differences useful for planning and evaluating competitive balance.

## Data

- **Source:** [nflverse](https://nflverse.nflverse.com/) data accessed through the [`nflreadr`](https://nflreadr.nflverse.com/) R package.
- **Seasons:** 2015–2025, regular season only.
- **Schedules:** Teams, game IDs, dates, scores, and home/away rest days.
- **Play-by-play:** Offensive EPA for plays coded as `run` or `pass`; aggregated by game and offensive team.
- **Observation unit:** One row per NFL game, expressed from the home team's perspective.

The completed-game schedule source contains **2,895** games. The current shared modeling sample contains **2,711** games. **184** games were excluded: **175** were Week 1 games; the remaining **9** were in later weeks. There were **10 tied games** among the exclusions (including some Week 1 ties), so these counts must not be added together. Most Week 1 exclusions occur because a current-season pregame EPA baseline does not yet exist. The analyses use a common sample to facilitate comparisons.

The game-level offensive EPA file contains **5,790 team-game records** across **2,895 games**. The data pipeline standardizes historical team abbreviations when joining sources (e.g., Oakland/Las Vegas Raiders, San Diego/Los Angeles Chargers, and St. Louis/Los Angeles Rams).

## Variables

| Variable | Definition | Use |
| --- | --- | --- |
| `rest_diff` | `home_rest - away_rest` in days | Main explanatory variable; positive values favor home team |
| `home_win` | 1 if the home team wins, 0 if it loses | Logistic regression response; ties excluded |
| `home_prior_epa`, `away_prior_epa` | Each team's play-weighted mean offensive EPA/play **before** the current game, calculated from earlier games in the same season | Pregame strength features |
| `pregame_epa_diff` | `home_prior_epa - away_prior_epa` | Pregame strength differential |
| `home_game_epa`, `away_game_epa` | Offensive EPA/play during the current game | Used only in response construction and descriptive analysis |
| `game_epa_diff` | `home_game_epa - away_game_epa` | Observed game-level efficiency difference |
| `epa_change_diff` | `game_epa_diff - pregame_epa_diff` | Multiple linear regression response |

**Leakage prevention:** The current game's EPA is never used to calculate its own pregame features. `home_game_epa`, `away_game_epa`, `game_epa_diff`, `epa_change_diff`, and game results must **not** be used as predictors of `home_win`. Any future modeling features must likewise be restricted to information available before kickoff.

## Repository structure

```text
R/
  01_schedules.R
  02_pbp_epa.R
  03_build_features.R
  04_quality_checks.R
  05_exploratory_analysis.R
  06_pipeline_audit.R
figures/
data/
  raw/           # Generated; excluded from Git
  processed/     # Generated CSVs; excluded from Git
reports/
.gitignore
README.md
nfl-rest-performance-stat3274.Rproj
```

## Reproducing the data pipeline

1. Install [R](https://cran.r-project.org/) and [RStudio](https://posit.co/download/rstudio-desktop/).
2. Clone this repository and open the `.Rproj` file in RStudio.
3. Install dependencies once in the RStudio Console:

   ```r
   install.packages(c("nflreadr", "dplyr", "readr", "ggplot2", "scales"))
   ```

4. Create the output directories if they do not already exist:

   ```r
   dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
   dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
   dir.create("figures", showWarnings = FALSE)
   ```

5. Run the scripts **in order**, from the project root:

   ```r
   source("R/01_schedules.R")
   source("R/02_pbp_epa.R")
   source("R/03_build_features.R")
   source("R/04_quality_checks.R")
   source("R/05_exploratory_analysis.R")
   source("R/06_pipeline_audit.R")
   ```

**Note:** Scripts read files using paths relative to the project root. Downloading historical play-by-play data can take time and requires an internet connection. NFL data may be revised by its upstream maintainers, so regenerated results may differ if the source changes.

### Generated outputs

- `data/raw/nfl_schedules_clean.csv`: cleaned schedule-level data.
- `data/raw/nfl_game_epa_2015_2025.csv`: game-by-offense EPA/play and offensive play counts.
- `data/processed/model_ready_games.csv`: shared analysis-ready game table (**2,711 rows in the current run**).
- `data/processed/rest_win_summary.csv` and `rest_epa_summary.csv`: grouped exploratory summaries.
- `figures/rest_distribution.png`
- `figures/win_rate_by_rest.png`
- `figures/epa_change_by_rest.png`
- `figures/rest_vs_epa_change.png`

Generated CSV files are excluded from Git via `.gitignore`. Teammates can reproduce them by running the scripts above or receive the model-ready CSV separately through a team-approved file-sharing method.

## Preliminary exploratory findings

The current analysis-ready sample includes **2,711 games**:

| Relative rest group | Games | Share of sample |
| --- | ---: | ---: |
| Away team has more rest | 551 | 20.3% |
| Equal rest | 1,694 | 62.5% |
| Home team has more rest | 466 | 17.2% |

The home win rates appear similar across rest categories (approximately 55–56%). The descriptive EPA/play-change comparison and scatterplot show only a small upward trend with rest differential. These are **unadjusted descriptive patterns**; they are not evidence of a causal effect or proof that rest has no predictive value. Regression estimates and held-out evaluation results are still pending.

## Planned statistical analysis

- **Multiple linear regression:** Predict `epa_change_diff` using pregame information and compare a baseline specification against one adding `rest_diff`.
- **Logistic regression:** Predict `home_win` using pregame information and compare a baseline specification against one adding `rest_diff`.
- **Evaluation:** Prefer chronological train/validation/test splits (proposed: 2015–2023 / 2024 / 2025) rather than random game splits. Use RMSE and MAE for the linear models; log loss, ROC-AUC, and Brier score for logistic models.
- **Interpretation:** Examine effect sizes, uncertainty, confounding, and whether adding rest materially improves out-of-sample prediction.

**Status:** Data collection, feature engineering, initial quality checks, and exploratory plots are completed. The regression models and final findings have not yet been completed or assigned to specific team members.

## Limitations and checks

- Rest is not assigned randomly; opponent quality, travel, scheduling, and other factors may confound associations.
- Most games feature equal rest, and large rest differentials are rare.
- Play-by-play EPA/play is based here on the subset of plays classified as `run` or `pass`.
- Current-season pregame EPA is unavailable for season openers, producing exclusions.
- The pipeline has passed missingness, duplicate, consistency, exclusion-count, and selected pregame-EPA checks; these are not a substitute for a full independent code review.
- Evaluation must avoid using game-level outcomes or postgame statistics as pregame predictors.

## Prior research and further reading

The project builds on existing work on NFL rest, bye weeks, and game outcomes. The literature review will compare prior findings with the 2015–2025 analysis and document any distinctions in outcome definitions, seasons, controls, and methodologies.

- [nflreadr documentation](https://nflreadr.nflverse.com/)
- [nflverse documentation](https://nflverse.nflverse.com/)
- [*Bye-bye, bye advantage* (2024)](https://doi.org/10.3389/frbhe.2024.1479832)
- [*The Relationship Between Relative Rest and Team Performance* (2025)](https://doi.org/10.1519/JSC.0000000000005148)
- [*Examining the Relationship Between Scheduling and NFL Game Outcomes* (2016)](https://doi.org/10.1177/1527002516672059)

## Team contributions

- **Pranav Harish:** Data acquisition, cleaning, feature engineering, validation, and initial exploratory analysis.
- **Nate Mertz and Momen Muneer:** Modeling responsibilities to be assigned by the group.
- **All members:** Literature review, interpretation, documentation, final presentation, and quality review.

## AI usage disclosure

ChatGPT was used to assist with project planning, drafting and debugging R code, interpreting diagnostics, and preparing documentation. The team is responsible for executing and validating all code, checking sources, interpreting results independently, and disclosing any additional AI use in the final submission and presentation.

## Course milestones

- **Draft submission:** November 20, 2026, 11:59 PM.
- **Group 6 presentation:** December 14, 2026, 9:20–9:45 AM; target presentation duration 22–25 minutes.
