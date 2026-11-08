library(dplyr)
library(readr)
library(ggplot2)

data <- read_csv(
  "data/processed/model_ready_games.csv",
  show_col_types = FALSE
)

dir.create("figures", showWarnings = FALSE)

data <- data |>
  mutate(
    rest_category = case_when(
      rest_diff < 0 ~ "Away team advantage",
      rest_diff == 0 ~ "Equal rest",
      rest_diff > 0 ~ "Home team advantage"
    ),
    rest_category = factor(
      rest_category,
      levels = c(
        "Away team advantage",
        "Equal rest",
        "Home team advantage"
      )
    )
  )

cat("\nDataset summary:\n")
print(dim(data))
print(summary(data$rest_diff))

rest_distribution <- data |>
  count(rest_diff)

p1 <- ggplot(
  rest_distribution,
  aes(x = rest_diff, y = n)
) +
  geom_col(fill = "#861F41") +
  labs(
    title = "Most NFL Matchups Have Equal Rest",
    x = "Home Rest Minus Away Rest (Days)",
    y = "Number of Games"
  ) +
  theme_minimal(base_size = 14)

print(p1)

ggsave(
  "figures/rest_distribution.png",
  p1,
  width = 10,
  height = 6,
  dpi = 300
)

win_summary <- data |>
  group_by(rest_category) |>
  summarise(
    games = n(),
    wins = sum(home_win),
    win_rate = mean(home_win),
    se = sqrt(win_rate * (1 - win_rate) / games),
    lower = pmax(0, win_rate - 1.96 * se),
    upper = pmin(1, win_rate + 1.96 * se),
    .groups = "drop"
  )

cat("\nWin rates by rest category:\n")
print(win_summary)

p2 <- ggplot(
  win_summary,
  aes(x = rest_category, y = win_rate)
) +
  geom_col(fill = "#E87722", width = 0.65) +
  geom_errorbar(
    aes(ymin = lower, ymax = upper),
    width = 0.2
  ) +
  geom_text(
    aes(label = paste0("n = ", games)),
    vjust = -1,
    size = 4
  ) +
  scale_y_continuous(
    labels = scales::percent_format(),
    limits = c(0, 1)
  ) +
  labs(
    title = "Home Win Rate by Relative Rest Advantage",
    x = "Rest Advantage",
    y = "Home Win Rate"
  ) +
  theme_minimal(base_size = 14)

print(p2)

ggsave(
  "figures/win_rate_by_rest.png",
  p2,
  width = 10,
  height = 6,
  dpi = 300
)

epa_summary <- data |>
  group_by(rest_category) |>
  summarise(
    games = n(),
    mean_epa_change = mean(epa_change_diff),
    sd_epa_change = sd(epa_change_diff),
    se = sd_epa_change / sqrt(games),
    lower = mean_epa_change - 1.96 * se,
    upper = mean_epa_change + 1.96 * se,
    .groups = "drop"
  )

cat("\nEPA changes by rest category:\n")
print(epa_summary)

p3 <- ggplot(
  epa_summary,
  aes(x = rest_category, y = mean_epa_change)
) +
  geom_col(fill = "#861F41", width = 0.65) +
  geom_errorbar(
    aes(ymin = lower, ymax = upper),
    width = 0.2
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Relative Offensive EPA Change by Rest Advantage",
    x = "Rest Advantage",
    y = "Mean Relative EPA/Play Change"
  ) +
  theme_minimal(base_size = 14)

print(p3)

ggsave(
  "figures/epa_change_by_rest.png",
  p3,
  width = 10,
  height = 6,
  dpi = 300
)

p4 <- ggplot(
  data,
  aes(x = rest_diff, y = epa_change_diff)
) +
  geom_jitter(
    alpha = 0.12,
    width = 0.15,
    height = 0
  ) +
  geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = TRUE,
    color = "#E87722"
  ) +
  labs(
    title = "Rest Differential and Offensive EPA Change",
    x = "Home Rest Minus Away Rest (Days)",
    y = "Relative Offensive EPA/Play Change"
  ) +
  theme_minimal(base_size = 14)

print(p4)

ggsave(
  "figures/rest_vs_epa_change.png",
  p4,
  width = 10,
  height = 6,
  dpi = 300
)

write_csv(
  win_summary,
  "data/processed/rest_win_summary.csv"
)

write_csv(
  epa_summary,
  "data/processed/rest_epa_summary.csv"
)

cat("\nExploratory analysis completed successfully.\n")
