library(nflreadr)
library(dplyr)
library(readr)

seasons <- 2015:2025

epa_list <- list()

for (yr in seasons) {
  
  cat("Processing season:", yr, "\n")
  
  pbp <- load_pbp(yr)
  
  season_epa <- pbp |>
    filter(
      season_type == "REG",
      !is.na(epa),
      !is.na(posteam),
      !is.na(game_id),
      play_type %in% c("run", "pass")
    ) |>
    group_by(game_id, posteam) |>
    summarise(
      offensive_epa_per_play = mean(epa),
      offensive_plays = n(),
      .groups = "drop"
    ) |>
    mutate(season = yr)
  
  epa_list[[as.character(yr)]] <- season_epa
  
  rm(pbp, season_epa)
  gc(verbose = FALSE)
}

game_epa_all <- bind_rows(epa_list)

write_csv(
  game_epa_all,
  "data/raw/nfl_game_epa_2015_2025.csv"
)

cat("\nDataset dimensions:\n")
print(dim(game_epa_all))

cat("\nGames by season:\n")
print(
  game_epa_all |>
    group_by(season) |>
    summarise(
      games = n_distinct(game_id),
      team_observations = n(),
      .groups = "drop"
    )
)

cat("\nMissing EPA values:\n")
print(sum(is.na(game_epa_all$offensive_epa_per_play)))

cat("\nDuplicate team-game observations:\n")
print(
  game_epa_all |>
    count(game_id, posteam) |>
    filter(n > 1)
)
