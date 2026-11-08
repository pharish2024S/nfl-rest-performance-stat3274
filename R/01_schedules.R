library(nflreadr)
library(dplyr)
library(readr)

schedules <- load_schedules(2015:2025)

games <- schedules |>
  filter(
    game_type == "REG",
    !is.na(home_score),
    !is.na(away_score),
    !is.na(home_rest),
    !is.na(away_rest)
  ) |>
  mutate(
    rest_diff = home_rest - away_rest,
    home_win = case_when(
      home_score > away_score ~ 1L,
      home_score < away_score ~ 0L,
      TRUE ~ NA_integer_
    ),
    score_diff = home_score - away_score
  )

games <- games |>
  filter(!is.na(home_win))

write_csv(games, "data/raw/nfl_schedules_clean.csv")

print(dim(games))
print(head(games))
summary(games$rest_diff)
