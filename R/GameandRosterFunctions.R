################################################################## 
###               Game and Roster Functions                    ###
# Author: Maksim Horowitz                                        #
# Code Style Guide: Google R Format                              #
##################################################################

# Games in a Season
#' Game Information for All Games in a Season
#' @description This function intakes a year associated with a given season
#' and outputs all the game matchups for all 17 weeks of the regular season
#' @param Season (numeric): A 4-digit year associated with a given NFL season
#' @param Week (numeric): A number corresponding to the number of weeks of data
#' you want to be scraped and included in the output.
#' @param sleep.seconds (numeric): Allows the user to tell the function to sleep
#' between calls to the API to avoid disrupting the connection. Note, this 
#' will make the function take much longer.
#' @return A dataframe with the gameID, the game date, 
#' the home team abbreviation, and away team abbreviation 
#' @details Reference the stored dataframe nflteams to match team abbreviations
#' with the full team names
#' @examples
#' # All games in 2015 Season
#' season_games(2015) # Will output a dataframe
#' @export
season_games <- function(Season, Weeks = 16, sleep.seconds = 0) {
  
  game_ids <- extracting_gameids(Season)
  
  # If statement to specify the week variable
  if (Weeks %in% 4:13) {
    game_ids <- game_ids[1:(16*Weeks)-1]
  } else if (Weeks %in% c(1:3, 14:15)) {
    game_ids <- game_ids[1:(16*Weeks)]
  }
  
  game_urls <- sapply(game_ids, proper_jsonurl_formatting)
  
  # Game Dates
  year <- substr(game_ids, start = 1, stop = 4)
  month <- substr(game_ids, start = 5, stop = 6)
  day <- substr(game_ids, start = 7, stop = 8)
  date <- as.Date( paste(month, day, year, sep = "/"), format = "%m/%d/%Y")
  
  # Home and Away Teams
  
  games.unformatted <- lapply(game_urls, 
                              FUN = function(x) {
                                Sys.sleep(sleep.seconds)
                                games.df <- cbind(t(sapply(RJSONIO::fromJSON(RCurl::getURL(x))[[1]]$home[2]$abbr,
                                               c)),
                                      t(sapply(RJSONIO::fromJSON(RCurl::getURL(x))[[1]]$away[2]$abbr,
                                               c)),
                                      t(sapply(max(RJSONIO::fromJSON(RCurl::getURL(x))[[1]]$home$score),
                                               c)),
                                      t(sapply(max(RJSONIO::fromJSON(RCurl::getURL(x))[[1]]$away$score),
                                               c)))
                                
                                data.frame(home = games.df[1],
                                           away = games.df[2],
                                           homescore = games.df[3] %>% as.numeric(),
                                           awayscore = games.df[4] %>% as.numeric())
                              })
  
  games <- suppressWarnings(dplyr::bind_rows(games.unformatted) %>% 
            dplyr::mutate(GameID = game_ids, 
                   date = date))

  # Output Dataframe
  
  games %>% dplyr::select(GameID, date, 
                          home, away, homescore, awayscore)
  
}

################################################################## 
#' Season Rosters for Teams
#' @description This function intakes a year and a team abbreviation and outputs
#' a dataframe with each player who has played for the specified team and 
#' recorded a measurable statistic
#' @param Season: A 4-digit year associated with a given NFL season
#' @param TeamInt: A string containing the abbreviations for an NFL Team
#' @details To find team associated abbrevations use the nflteams dataframe 
#' stored in this package!
#' @return A dataframe with columns associated with season/year, full player name,
#' team initial, position, and formated player name.
#' players who played and recorded some measurable statistic, and the 
#' last column specifyng the number of games they played in.
#' @examples
#' # Roster for Baltimore Ravens in 2013
#' season_rosters(2013, TeamInt = "BAL") 
#' @export
season_rosters <- function(Season, TeamInt) {
  
  positions <- c("QUARTERBACK","RUNNING_BACK" ,   
                 "WIDE_RECEIVER", "TIGHT_END"  ,      
                 "DEFENSIVE_LINEMAN", "LINEBACKER" ,      
                 "DEFENSIVE_BACK", "KICKOFF_KICKER",   
                 "KICK_RETURNER", "PUNTER",           
                 "PUNT_RETURNER", "FIELD_GOAL_KICKER")
  
  rosters <- positions %>% purrr::map_df(getPlayers, season=Season) %>%
    dplyr::filter(Team == TeamInt) %>% dplyr::group_by(Player, Team, Pos) %>% 
    dplyr::slice(n= 1) %>% 
    dplyr::mutate(Season = Season) %>% 
    dplyr::select(Season, Player, Team, Pos, name)
  
  ## Return the rosters DF ##
  rosters 
}

################################################################## 
# Do not export
#' Building URL to scrape player season stat pages
#' @description This is a sub-function for the season_rosters
#' function.
#' @param position: (character string) Specifies a player position page for the URL
#' @param season: 4-digit year associated with a given NFL season
#' @param page: 1-digit page number to look into
#' @param type: A three character string specifying the season type
buildURL <- function(position, season=2016, page=1, 
                     type=c('REG', 'POST', 'PRE'))
{
  type <- match.arg(type)
  
  # season, type, page, position
  baseString <- 'http://www.nfl.com/stats/categorystats?tabSeq=1&season=%s&seasonType=%s&d-447263-p=%s&conference=null&statisticPositionCategory=%s'
  sprintf(baseString, 
          season, type, page, position)
  
}

################################################################## 
# Do not export
#' Get Number of Player Position Pages 
#' @description For each position, this function extracts the number of pages 
#' there are to scrape. This is a sub-function for the season_rosters function
getPageNumbers <- . %>% 
  # get list of pages if it exists
  rvest::html_node('.linkNavigation') %>% 
  # extract text
  rvest::html_text() %>%
  # break it up by |
  stringr::str_split('|') %>%
  # this gives a list, get the first element
  magrittr::extract2(1) %>% 
  # keep just numbers
  stringr::str_extract('\\d+') %>% 
  # convert to integer
  as.integer() %>% 
  # replace NAs with 1
  replace(., is.na(.), 1) %>%
  # find unique and sort
  unique %>% sort

################################################################## 
# Do not export
#' Build formatted player name from full player name
#' @description This sub-function, called in the season_rosters function,
#' takes the full name of each player and formats it into the first initial of 
#' their first name and last initial of their last name.
buildNameAbbr <- . %>% 
  # get the result table node
  rvest::html_node('#result') %>% 
  # extract the table
  rvest::html_table() %>% 
  # get columns 2, 3, 4
  magrittr::extract(2:4) %>% 
  # make sure names are what we want
  setNames(nm=c('Player', 'Team', 'Pos')) %>% 
  # get rid of a row if the player is player
  dplyr::filter(Player != 'Player') %>% 
  # get the first initial and last name
  dplyr::mutate(First=stringr::str_sub(Player, 1, 1),
                Last=stringr::str_extract(Player, ' [^ ]+$')) %>% 
  # remove space before last name
  dplyr::mutate(Last=stringr::str_trim(Last)) %>% 
  # combine them into one column
  tidyr::unite(name, First, Last, sep='.', remove=TRUE)

################################################################## 
# Do not export
#' Scrape Player Names and Positions
#' @description This sub-function, calls buildNameAbbr and getPageNumbers to
#' scrape player positions by season.
getPlayers <- function(position, season, 
                       type=c('REG', 'POST', 'PRE'))
{
  # Give position name
  message(sprintf('Extracting %s', position))
  
  type <- match.arg(arg = type)
  
  ## get first page
  firstUrl <- buildURL(position=position, season=season, page=1, type=type)
  firstPage <- xml2::read_html(firstUrl)
  
  # get number of pages
  pageSeq <- getPageNumbers(firstPage)
  
  # build urls
  pageUrls <- buildURL(position=position, 
                       season=season, page=pageSeq, type=type)
  
  # read the pages and extract info
  pageUrls %>% 
    # read each URL
    purrr::map(., .f = function(x) xml2::read_html(x)) %>% 
    # get the name and position, combine everything into a data.frame
    purrr::map_df(buildNameAbbr)
}