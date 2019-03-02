library(tidyverse)
library(httr)
library(rvest)
library(matchingR)

win_rates <- readRDS("data/win_rates.rds")

### Data setup -----
#Signup info from rebbl.net
# https://rebbl.net/api/v1/oi
signups <- read_csv("data/oi_week4.csv") %>% mutate(race = ifelse(race == "Dwarfs", "Dwarf", race))

#any non rebbl.net entry
#late_entry <- data_frame(`team name` = "Deepdeepdeep Undercoverer", race = "Underworld", discord = "CptBlood", `blood bowl 2 name` = "Wakrob", reqion = "REL")
#signups <- bind_rows(signups, late_entry)