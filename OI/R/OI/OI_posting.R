library(tidyverse)

seasoned <- read_csv("week1_posting_seasoned.csv")

fresh <- read_csv("week1_posting_fresh.csv")

eg <- read_csv("week1_posting_eg.csv")

matchups <- bind_rows(seasoned, fresh, eg)

matchups %>% select(reddit, Race, Team, Team2, Race2, reddit2) %>% knitr::kable(col.names = c("Coach","Race","Team","Team","Race","Coach"), format = "markdown")
