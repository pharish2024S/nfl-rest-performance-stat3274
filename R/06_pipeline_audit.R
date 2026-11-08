library(nflreadr)
library(dplyr)
library(readr)

schedules <- load_schedules(2015:2025) |>
  filter(
    game_type == "REG",
    !is.na(home_score),
    !is.na(away_score),
    !is.na(home_rest),
    !is.na(away_rest)
  )

data <- read_csv(
  "data/processed/model_ready_games.csv",
  show_col_types = FALSE
)

excluded <- schedules |>
  anti_join(
    data |> select(game_id),
    by = "game_id"
  )

cat("\nOriginal games:\n")
print(nrow(schedules))

cat("\nModeling games:\n")
print(nrow(data))

cat("\nExcluded games:\n")
print(nrow(excluded))

cat("\nExcluded games by week:\n")
print(excluded |> count(week))

cat("\nExcluded games by season:\n")
print(excluded |> count(season))

cat("\nExcluded tied games:\n")
print(
  excluded |>
    filter(home_score == away_score) |>
    select(game_id, season, week)
)

cat("\nPregame EPA availability:\n")
print(
  data |>
    summarise(
      min_home_prior_plays = min(home_prior_plays),
      min_away_prior_plays = min(away_prior_plays),
      missing_pregame_epa =
        sum(is.na(pregame_epa_diff))
    )
)

cat("\nModeling dataset checks:\n")
stopifnot(
  nrow(data) + nrow(excluded) == nrow(schedules),
  !anyDuplicated(data$game_id),
  all(data$home_prior_plays > 0),
  all(data$away_prior_plays > 0),
  !anyNA(data$pregame_epa_diff),
  all(data$season >= 2015 & data$season <= 2025)
)

cat("\nAudit checks passed.\n")
