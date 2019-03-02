library(tidyverse)
#library(nufflytics)
source("c:/Users/ttrnecka/OneDrive - DXC Production/Aptana RadRails Workspace/R/nufflytics/R/api.R")
library(httr)
library(rvest)
library(matchingR)

key <- readRDS("api.key")
win_rates <- readRDS("data/win_rates.rds")

### Data setup -----
#Signup info from rebbl.net
# https://rebbl.net/api/v1/oi
signups <- read_csv("data/oi_week4.csv") %>% mutate(race = ifelse(race == "Dwarfs", "Dwarf", race))

late_entry <- data_frame(`team name` = "Deepdeepdeep Undercoverer", race = "Underworld", discord = "CptBlood", `blood bowl 2 name` = "Wakrob", reqion = "REL")

signups <- bind_rows(signups, late_entry)

#Playoff teams because they need to be checked which OI round they can enter
playoff_teams <- api_teams(key, league = "REBBL Playoffs")

#Last season standings
rampup_s <- GET("https://rebbl.net/api/v1/standings/rampup/rel") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "Rampup")

REL_s <- GET("https://rebbl.net/api/v1/standings/REL") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "REL", division = str_replace(competition, "Season 9 - Division ([0-9]*).?","\\1") %>% as.integer() %>% magrittr::divide_by(10) %>% magrittr::multiply_by(10))

REL_s[REL_s$team=="Not An Anime Sports Team ",]$team <- "Not An Anime Sports Team"
REL_s[REL_s$team=="  Lords of Decay",]$team <- "Lords of Decay"

Gman_s <- GET("https://rebbl.net/api/v1/standings/GMan") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "Gman", division = str_replace(competition, "Season 9 - Division ([0-9]*).?","\\1") %>% as.integer() %>% magrittr::divide_by(8) %>% magrittr::multiply_by(10))

BigO_s <- GET(URLencode("https://rebbl.net/api/v1/standings/Big O")) %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "BigO", division = str_replace(competition, "Season 9 - Division ([0-9]*).?","\\1") %>% as.integer() %>% magrittr::divide_by(4) %>% magrittr::multiply_by(10))

add_ins <- tibble::tribble(
  ~competition, ~team, ~teamId, ~race, ~points, ~games, ~win, ~loss, ~draw, ~tddiff, ~region, ~division,
  "Minors","Winged Centaurs", 1981750, "ChaosDwarf", 19, 11, 5,2,4,7, "Minors", 6,
  "Season 8 - Division 3", "The Revenge of the Franks",1547163, "Orc", 26,13, 8,3,2,5,"REL", 3,
  "Season 7 - Division 2", "Fruity Kisses", 874346, "DarkElf", 17,13,4,4,5,24,"REL", 4,
  "Minors", "Ghoul Busters!", 1957268, "Human", 26,11,8,1,2,9,"Minors", 6,
  "Minors", "Rat Street Boys", 1981698, "Skaven", 12,11,3,5,3,2,"Minors", 6,
  "Minors", "Balthor's Bashers", 1966353, "Dwarf", 14,11,4,4,3,-1,"Minors", 6,
  "Minors", "Red Velvet Titans", 1975702, "Dwarf", 17,11,5,4,2,2,"Minors", 6,
  "Minors", "The Sado-Masochrists", 2043945, "Human", 11,11,3,6,2,-4,"Minors", 6,
  "Minors", "Clann Nibblers", 1966791, "Skaven", 19,11,5,2,4,9,"Minors", 6,
  "Minors", "Hell's Doofuses", 2001958, "Chaos", 24,11,7,1,3,8,"Minors", 6,
  "Season 7 - Division 1", "WesC's Wolves", 1079174, "Necromantic", 18,11, 5,3,3,-1,"BigO", 1,
  "Minors", "The Lizzardblizzard", 1988441, "Lizardman", 24,11,7,1,3,9,"Minors", 6,
  "Season 8 - Division 3", "Cold Coast Creeps", 1617845, "Underworld", 15, 11, 5, 6, 0, -2, "BigO", 7.5,
  "Rampup", "Deepdeepdeep Undercoverer", 2519472, "Underworld", 3, 11, 1, 10, 0, -5, "REL", 10
)

#Combine everything together
all_standings <- bind_rows(REL_s, Gman_s, BigO_s, add_ins) %>%
  filter(!team %in% rampup_s$team) %>%
  bind_rows(rampup_s) %>%
  replace_na(list(competition = "Rampup", division = 1))

#Team TV for next round
next_TV <- function(teamID) {
  nTV_page <- GET(glue::glue("https://rebbl.net/rebbl/team/{teamID}")) %>%
        content() %>%
        html_children() %>%
        .[[2]] %>%
        html_children() %>%
        .[[4]] %>%
        html_children() %>%
        .[[1]] %>%
        html_children()

        if(is_empty(nTV_page)) return(0)

        nTV_page %>%
        .[[6]] %>%
        html_children() %>%
        .[[2]] %>%
        html_text() %>%
        as.integer()
}

#remove playoff round 2 teams
r1_teams <- signups %>%
  left_join(all_standings, by = c("team name" = "team"))

#Drop not registered on rebbl.net
#Teams kicked for not scheduling / accepting tickets previously - Artemis Black
r1_teams <- r1_teams %>% filter(!`blood bowl 2 name` %in% c("Notforscience", "Artemis Black" ))

TVs <- map_int(r1_teams$teamId, next_TV)

r1_teams$TV <- TVs

r1_teams <- r1_teams %>%
  mutate(ppg = as.integer(points)/as.integer(games)/3, division = ifelse(region == "Rampup", "10", division))

# Get old matchups to not allow doubling up
r1_matchups <- read_csv("r1matches.csv")
r2_matchups <- read_csv("r2_matches.csv")
r3_matchups <- read.csv("r3_matches.csv")

old_matchups <- bind_rows(r1_matchups, r2_matchups, r3_matchups)

#Include OI performance into the r1_teams df
OI_results <- api_matches(key, league="REBBL Open Invitational,REBBL Open Invitational 2,REBBL Open Invitational 3,REBBL Open Invitational 4,REBBL Playoffs", start = "2018-09-01", limit = 500)

OI_tmp <- OI_results$matches %>%
  map_df(~data_frame(
    homecoach = .$coaches[[1]]$coachname,
    awaycoach = .$coaches[[2]]$coachname,
    homescore = .$teams[[1]]$score,
    awayscore = .$teams[[2]]$score)
    ) %>%
  mutate(home_pts = case_when(homescore > awayscore ~ 3, homescore == awayscore ~ 1, T ~ 0), away_pts = case_when(home_pts == 3 ~ 0, home_pts == 1 ~ 1, T ~ 3))

OI_score <- bind_rows(
  OI_tmp %>% select("blood bowl 2 name" = homecoach, "pts" = home_pts),
  OI_tmp %>% select("blood bowl 2 name" = awaycoach, "pts" = away_pts)
  ) %>%
  group_by(`blood bowl 2 name`) %>%
  summarise(OI_ppg = sum(pts, na.rm = T)/n())

r1_teams <- left_join(r1_teams, OI_score) %>% replace_na(list(OI_ppg = 0))

payoff <- function(team, opponent) {

  #TV difference
  if(team$race.x == "Goblin") team$TV <- team$TV + 150
  if(team$race.x == "Halfling") team$TV <- team$TV + 300

  if(opponent$race.x == "Goblin") opponent$TV <- team$TV + 150
  if(opponent$race.x == "Halfling") opponent$TV <- team$TV + 300

  max_diff <- r1_teams$TV %>% range() %>% diff

  TVdiff <- 1 - (abs(floor((team$TV - opponent$TV)/50)/10) %>% scales::squish()) # cap out at 500TV difference

  #Race
  WR = win_rates %>% scales::rescale(c(0,1))

  WRdiff = 1 - abs(WR[team$race.x, opponent$race.x] - WR[opponent$race.x, team$race.x])
  if(team$race.x == opponent$race.x) {WRdiff <- 0.8}


  #Performance
  Pdiff <- 1 - abs(team$ppg - opponent$ppg)

  #Division
  Ddiff <- 1 - abs((as.numeric(team$division) - as.numeric(opponent$division))/10)

  #Played this season?
  same_div <- (team$competition == opponent$competition) & (team$region == opponent$region)

  #Putting it together
  fundamentals <- (0.4*TVdiff + 0.1*WRdiff + 0.2*Pdiff + 0.4*Ddiff)

  OIdiff <- 1 - abs(team$OI_ppg/3 - opponent$OI_ppg/3)

  payoff <- (0.80*fundamentals) + (0.20 * OIdiff)

  if (same_div) payoff <- 0.3

  if(any(old_matchups$Team %in% c(team$`team name`, opponent$`team name`) & old_matchups$Team2 %in% c(team$`team name`, opponent$`team name`))) payoff <- 0.3

  payoff
}

#make even numbers
#remove one from lowest pool if necessary
#r1_teams <- filter(r1_teams, !`blood bowl 2 name` %in% c("koso"))

payoff_mat <- matrix(data = 0, nrow = nrow(r1_teams), ncol = nrow(r1_teams), dimnames = list(r1_teams$`team name`,r1_teams$`team name`))

for (t in r1_teams$`team name`) {
  for (o in r1_teams$`team name`) {
    payoff_mat[t,o] <- payoff(r1_teams[r1_teams$`team name` == t, ], r1_teams[r1_teams$`team name` == o, ])
  }
}

matches = roommate(utils = payoff_mat)

while (is.null(matches)) {
  matches <- roommate(utils = payoff_mat + runif(nrow(payoff_mat)^2, c(-0.01,0.01)))
}

for_posting <- data_frame()

for (i in seq_along(matches)) {
  if (!r1_teams$`blood bowl 2 name`[i] %in% for_posting$BB2 & !r1_teams$`blood bowl 2 name`[i] %in% for_posting$BB22) {
    team1 <- r1_teams[i,]
    team2 <- r1_teams[matches[i], ]
    for_posting <- bind_rows(
      for_posting,
      data_frame(
                OI = team1$OI_ppg,
                perf = team1$ppg,
                div = team1$division,
                comp = team1$competition,
                region = team1$region,
                TV = team1$TV,
                BB2 = team1$`blood bowl 2 name`,
                reddit = paste0("/u/",team1$`reddit name`),
                Race = team1$race.x,
                Team = glue::glue("[{team1$`team name`}](https://rebbl.net/rebbl/team/{team1$teamId})"),
                Team2 = glue::glue("[{team2$`team name`}](https://rebbl.net/rebbl/team/{team2$teamId})"),
                Race2 = team2$race.x,
                reddit2 = paste0("/u/",team2$`reddit name`),
                BB22 = team2$`blood bowl 2 name`,
                TV2 = team2$TV,
                region2 = team2$region,
                comp2 = team2$competition,
                div2 = team2$division,
                perf2 = team2$ppg,
                OI2 = team2$OI_ppg
      )
      )
  }
}

for_posting <- for_posting %>% filter(!is.na(Race)) %>% sample_frac(size = 1)

for_admins <- for_posting %>% mutate(Team = str_replace(Team, "\\[(.*)\\].*","\\1"), Team2 = str_replace(Team2, "\\[(.*)\\].*","\\1"))



