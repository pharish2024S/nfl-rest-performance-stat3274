library(dplyr)
library(readr)

data <- read_csv(
  "data/processed/model_ready_games.csv",
  show_col_types = FALSE
)

cat("\nDataset dimensions:\n")
print(dim(data))

cat("\nGames by season:\n")
print(data |> count(season))

cat("\nMissing values:\n")
print(colSums(is.na(data)))

cat("\nDuplicate game IDs:\n")
print(sum(duplicated(data$game_id)))

cat("\nRest differential summary:\n")
print(summary(data$rest_diff))

cat("\nPregame EPA difference summary:\n")
print(summary(data$pregame_epa_diff))

cat("\nEPA change difference summary:\n")
print(summary(data$epa_change_diff))

cat("\nHome win rate:\n")
print(mean(data$home_win))

cat("\nRest differential consistency:\n")
print(all(data$rest_diff == data$home_rest - data$away_rest))

cat("\nWin outcome consistency:\n")
print(all(
  data$home_win ==
    as.integer(data$home_score > data$away_score)
))

cat("\nUnexpected infinite values:\n")
print(sum(
  !is.finite(data$pregame_epa_diff) |
    !is.finite(data$epa_change_diff)
))

stopifnot(
  nrow(data) > 0,
  !anyNA(data),
  !anyDuplicated(data$game_id),
  all(data$home_win %in% c(0, 1)),
  all(data$rest_diff == data$home_rest - data$away_rest),
  all(data$home_win ==
        as.integer(data$home_score > data$away_score)),
  all(is.finite(data$pregame_epa_diff)),
  all(is.finite(data$epa_change_diff))
)

cat("\nAll quality checks passed.\n")
