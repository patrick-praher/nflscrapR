% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GameandRosterFunctions.R
\name{season_games}
\alias{season_games}
\title{Game Information for All Games in a Season}
\usage{
season_games(Season, Weeks = 16, sleep.seconds = 0)
}
\arguments{
\item{Season}{(numeric): A 4-digit year associated with a given NFL season}

\item{sleep.seconds}{(numeric): Allows the user to tell the function to sleep
between calls to the API to avoid disrupting the connection. Note, this 
will make the function take much longer.}

\item{Week}{(numeric): A number corresponding to the number of weeks of data
you want to be scraped and included in the output.}
}
\value{
A dataframe with the gameID, the game date, 
the home team abbreviation, and away team abbreviation
}
\description{
This function intakes a year associated with a given season
and outputs all the game matchups for all 17 weeks of the regular season
}
\details{
Reference the stored dataframe nflteams to match team abbreviations
with the full team names
}
\examples{
# All games in 2015 Season
season_games(2015) # Will output a dataframe
}
