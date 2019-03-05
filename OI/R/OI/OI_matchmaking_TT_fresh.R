library(tidyverse)
library(httr)
library(rvest)
library(matchingR)
library(readr)
library(jsonlite)
library(tictoc)

win_rates <- readRDS("data/win_rates.rds")

### Data setup -----
#Signup info from rebbl.net
# https://rebbl.net/api/v1/oi
signups <- read_csv("data/OI_fresh.csv") %>% mutate(race = ifelse(race == "Dwarfs", "Dwarf", race))

#any non rebbl.net entry
#late_entry <- data_frame(`team name` = "Deepdeepdeep Undercoverer", race = "Underworld", discord = "CptBlood", `blood bowl 2 name` = "Wakrob", reqion = "REL")
#signups <- bind_rows(signups, late_entry)

signups[signups$`blood bowl 2 name`=="SoulOfDragnsFire",]$race <- "Dark Elf"

REL_s <- GET("https://rebbl.net/api/v1/standings/REL") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "REL", division = str_replace(competition, "Season 10 - Division ([0-9]*).?","\\1") %>% as.integer() %>% magrittr::divide_by(10) %>% magrittr::multiply_by(10))

#REL_s[REL_s$team=="Not An Anime Sports Team ",]$team <- "Not An Anime Sports Team"
#REL_s[REL_s$team==" Nightmare on Elf Street",]$team <- "Nightmare on Elf Street"

Gman_s <- GET("https://rebbl.net/api/v1/standings/GMan") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "Gman", division = str_replace(competition, "Season 10 - Division ([0-9]*).?","\\1") %>% as.integer() %>% magrittr::divide_by(10) %>% magrittr::multiply_by(10))

BigO_s <- GET(URLencode("https://rebbl.net/api/v1/standings/Big O")) %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "BigO", division = str_replace(competition, "Season 10 - Division ([0-9]*).?","\\1") %>% as.integer() %>% magrittr::divide_by(5) %>% magrittr::multiply_by(10))

#Last season standings
REL_rampup_s <- GET("https://rebbl.net/api/v1/standings/rampup/rel") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "Rampup")

GMAN_rampup_s <- GET("https://rebbl.net/api/v1/standings/rampup/gman") %>%
  content(as = "text") %>%
  jsonlite::fromJSON() %>%
  mutate(region = "Rampup")


add_ins <- tibble::tribble(
  ~competition, ~team, ~teamId, ~race, ~points, ~games, ~win, ~loss, ~draw, ~tddiff, ~region, ~division,
  "Minors","Mazdamundis heirs", 2235076, "Lizardman", 14, 9, 3,1,5,2, "Minors", 6,
  "Minors","Zoltans Zwords", 2224255, "ChaosDwarf", 23, 9, 7,0,2,7, "Minors", 6,
  "Minors","The Sit Down Boys", 2169444, "ProElf", 8, 9, 2,5,2,-4, "Minors", 6,
  "Minors","Legion of Dead Metal", 2170329, "Necromantic", 9, 9, 2,4,3,0, "Minors", 6,
  "Minors","Lackland Long Tongues", 2130792, "Lizardman", 27, 9, 9,0,0,9, "Minors", 6,
  "Minors","Bare Necessities", 2176772, "Kislev", 19, 9, 6,2,1,3, "Minors", 6,
  "Season 9 - Division 4", "Prof Paresthesia's Pets", 1927917, "Necromantic", 14, 13,4,7,2,-3,"GMAN", 4,
  "Minors","Tarot Alliance", 2390017, "ChaosDwarf", 14, 9, 4,3,2,2, "Minors", 6,
  "Minors","The last  action heroes", 2370554, "ChaosDwarf", 18, 9, 5,1,3,5, "Minors", 8,
  "Season 7 - Division 5A", "Merciless Avengers", 1616785, "ChaosDwarf", 10, 13,3,9,1,-11,"REL", 10
)

rampup_s = bind_rows(GMAN_rampup_s, REL_rampup_s)
#Combine everything together
all_standings <- bind_rows(REL_s, Gman_s, BigO_s, add_ins) %>%
  filter(!team %in% rampup_s$team) %>%
  bind_rows(rampup_s) %>%
  replace_na(list(competition = "Rampup", division = 8))

all_standings[all_standings$team==" Despicable Meme",]$team <- "Despicable Meme"
all_standings[all_standings$team=="\tThe Commodious Thunder",]$team <- "The Commodious Thunder"


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


#merge signups data with results
r1_teams <- signups %>%
  left_join(all_standings, by = c("team name" = "team")) %>%
  replace_na(list(division = 10, TV = 0))


TVs <- map_int(r1_teams$teamId, next_TV)

r1_teams$TV <- TVs

r1_teams <- r1_teams %>%
  mutate(ppg = as.integer(points)/as.integer(games)/3, division = ifelse(region == "Rampup", "10", division))


#fix TV - remove after week 1
#r1_teams[r1_teams$`team name`=="The last  action heroes",]$TV <- 1600
#r1_teams[r1_teams$`team name`=="Merciless Avengers",]$TV <- 1430


# Get old matchups to not allow doubling up
old_matches  <- read_csv("data/OI_S9_matches.csv")
r1_matchups <- read_csv("data/r1_matches.csv")
#r2_matchups <- read_csv("r2_matches.csv")
#r3_matchups <- read.csv("r3_matches.csv")
oi_matchups <- bind_rows(r1_matchups)
old_matchups <- bind_rows(old_matches, oi_matchups)


#Include OI performance into the r1_teams df
#OI_results <- api_matches(key, league="REBBL Open Invitational,REBBL Open Invitational 2,REBBL Open Invitational 3,REBBL Open Invitational 4,REBBL Playoffs", start = "2018-09-01", limit = 500)

oi_file <- read_file("data/oi_po_matches.json")
OI_results <- oi_file %>% jsonlite::fromJSON(simplifyDataFrame = simplify)

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

#tmp fix
#r1_teams$OI_ppg = 0

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
  
  payoff <- (0.95*fundamentals) + (0.05 * OIdiff)
  #payoff <- (1*fundamentals)
  
  # check for previous OI match races
  #tic("finding race")
  oi_races <-bind_rows(
    oi_matchups[oi_matchups$Team==team$`team name`,] %>% select("race"= Race2), 
    oi_matchups[oi_matchups$Team2==team$`team name`,] %>% select("race"= Race)
  ) %>% 
    group_by(race)
  
  if(any(opponent$race.x %in% oi_races)) payoff <- payoff * 0.8
  #toc()
  
  if (same_div) payoff <- 0.3
  
  #tic("finding old matchup")
  if(any(old_matchups$Team %in% c(team$`team name`, opponent$`team name`) & old_matchups$Team2 %in% c(team$`team name`, opponent$`team name`))) payoff <- 0.3
  #toc()
  payoff
}

#make even numbers
#remove one from lowest pool if necessary
#r1_teams <- filter(r1_teams, !`blood bowl 2 name` %in% c("Archie Bunker"))

payoff_mat <- matrix(data = 0, nrow = nrow(r1_teams), ncol = nrow(r1_teams), dimnames = list(r1_teams$`team name`,r1_teams$`team name`))

for (t in r1_teams$`team name`) {
  for (o in r1_teams$`team name`) {
    payoff_mat[t,o] <- payoff(r1_teams[r1_teams$`team name` == t, ], r1_teams[r1_teams$`team name` == o, ])
  }
}

payoff_mat[is.na(payoff_mat)] <- 0.3
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

write_csv(for_admins, "week2_admins_fresh.csv")
write_csv(for_posting, "week2_posting_fresh.csv")
