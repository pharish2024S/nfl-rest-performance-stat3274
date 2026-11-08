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


epa_data <- read_csv(
  "data/raw/nfl_game_epa_2015_2025.csv",
  show_col_types = FALSE
) |>
  mutate(
    posteam = case_when(
      posteam == "LV" & season < 2020 ~ "OAK",
      posteam == "LAC" & season < 2017 ~ "SD",
      posteam == "LA" & season < 2016 ~ "STL",
      TRUE ~ posteam
    )
  )

home_games <- schedules |>
  transmute(
    game_id,
    season,
    week,
    gameday,
    team = home_team,
    side = "home"
  )

away_games <- schedules |>
  transmute(
    game_id,
    season,
    week,
    gameday,
    team = away_team,
    side = "away"
  )

team_games <- bind_rows(home_games, away_games) |>
  left_join(
    epa_data |>
      select(
        game_id,
        posteam,
        offensive_epa_per_play,
        offensive_plays
      ),
    by = c("game_id", "team" = "posteam"),
    relationship = "one-to-one"
  )

missing_epa <- team_games |>
  filter(
    is.na(offensive_epa_per_play) |
      is.na(offensive_plays)
  ) |>
  select(
    game_id,
    season,
    week,
    team,
    side
  )

cat("\nNumber of unmatched team-game records:\n")
print(nrow(missing_epa))

cat("\nUnmatched team-game records:\n")
print(missing_epa, n = Inf)

cat("\nSchedule game IDs missing from EPA:\n")
print(
  anti_join(
    schedules |> distinct(game_id),
    epa_data |> distinct(game_id),
    by = "game_id"
  ),
  n = Inf
)

cat("\nEPA game IDs missing from schedules:\n")
print(
  anti_join(
    epa_data |> distinct(game_id),
    schedules |> distinct(game_id),
    by = "game_id"
  ),
  n = Inf
)

cat("\nEPA teams missing from schedule team records:\n")
print(
  anti_join(
    epa_data |>
      distinct(game_id, team = posteam),
    bind_rows(home_games, away_games) |>
      distinct(game_id, team),
    by = c("game_id", "team")
  ),
  n = Inf
)

if (nrow(missing_epa) > 0) {
  stop(
    "Unmatched EPA records detected. ",
    "Review diagnostic output before continuing."
  )
}

team_games <- team_games |>
  group_by(season, team) |>
  arrange(gameday, game_id, .by_group = TRUE) |>
  mutate(
    prior_plays = lag(
      cumsum(offensive_plays),
      default = 0
    ),
    prior_total_epa = lag(
      cumsum(
        offensive_epa_per_play * offensive_plays
      ),
      default = 0
    ),
    prior_epa = if_else(
      prior_plays > 0,
      prior_total_epa / prior_plays,
      NA_real_
    )
  ) |>
  ungroup()

home_features <- team_games |>
  filter(side == "home") |>
  transmute(
    game_id,
    home_prior_epa = prior_epa,
    home_game_epa = offensive_epa_per_play,
    home_prior_plays = prior_plays
  )

away_features <- team_games |>
  filter(side == "away") |>
  transmute(
    game_id,
    away_prior_epa = prior_epa,
    away_game_epa = offensive_epa_per_play,
    away_prior_plays = prior_plays
  )

model_data <- schedules |>
  select(
    game_id,
    season,
    week,
    gameday,
    home_team,
    away_team,
    home_rest,
    away_rest,
    home_score,
    away_score
  ) |>
  left_join(
    home_features,
    by = "game_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    away_features,
    by = "game_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    rest_diff = home_rest - away_rest,
    home_win = case_when(
      home_score > away_score ~ 1L,
      home_score < away_score ~ 0L,
      TRUE ~ NA_integer_
    ),
    pregame_epa_diff =
      home_prior_epa - away_prior_epa,
    game_epa_diff =
      home_game_epa - away_game_epa,
    epa_change_diff =
      game_epa_diff - pregame_epa_diff
  )

model_data <- model_data |>
  filter(
    !is.na(home_win),
    !is.na(pregame_epa_diff),
    !is.na(epa_change_diff)
  ) |>
  arrange(season, week, gameday, game_id)

cat("\nFinal dataset dimensions:\n")
print(dim(model_data))

cat("\nGames per season:\n")
print(model_data |> count(season))

cat("\nMissing values by column:\n")
print(colSums(is.na(model_data)))

cat("\nDuplicate game IDs:\n")
print(sum(duplicated(model_data$game_id)))

cat("\nDataset preview:\n")
print(head(model_data))

stopifnot(
  nrow(model_data) > 0,
  !anyDuplicated(model_data$game_id),
  !anyNA(model_data),
  all(model_data$home_win %in% c(0L, 1L))
)

write_csv(
  model_data,
  "data/processed/model_ready_games.csv"
)

cat("\nModel-ready dataset saved successfully.\n")
