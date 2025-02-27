library(dplyr)
library(ggplot2)
library(lattice)

# this script uses all the functions to compile tables of stats for each batter
trackman_data <- read.csv("TRACKMAN_DATASET_MARINERS.csv")

# split into dataframes for each batter
batters <- unique(trackman_data$batter_id)

batter1 <- trackman_data %>% 
  filter(batter_id==batters[1])
batter2 <- trackman_data %>% 
  filter(batter_id==batters[2])
batter3 <- trackman_data %>% 
  filter(batter_id==batters[3])
batter4 <- trackman_data %>% 
  filter(batter_id==batters[4])
batter5 <- trackman_data %>% 
  filter(batter_id==batters[5])


# this function gets the average exit velocity for each batter split by pitcher handedness
avg_exit_Velo <- function(df, hand) {
  inPlay <- df %>%
    filter(pitcher_hand == hand & outcome != "NULL" & exit_velo != "NA" & result != "BUIP")
  return(sum(inPlay$exit_velo, na.rm = TRUE)/length(inPlay$exit_velo))
}

# this function gets the average exit velocity for each batter
getAvgVelo <- function(df) {
  inPlay <- df %>%
    filter(outcome != "NULL" & exit_velo != "NA" & result != "BUIP")
  return(sum(inPlay$exit_velo, na.rm = TRUE)/length(inPlay$exit_velo))
}

# this function gets the average launch angle for each batter split by pitcher handedness
avg_launch_angle <- function(df, hand) {
  inPlay <- df %>%
    filter(pitcher_hand == hand & outcome != "NULL" & exit_velo != "NA" & result != "BUIP")
  return(sum(inPlay$vert_angle, na.rm = TRUE)/length(inPlay$vert_angle))
}

# this function gets the average launch angle for each batter
getAvgAngle <- function(df) {
  inPlay <- df %>%
    filter(outcome != "NULL" & exit_velo != "NA" & result != "BUIP")
  return(sum(inPlay$vert_angle, na.rm = TRUE)/length(inPlay$vert_angle))
}

# this function counts the number of Barrels for each batter split into pitcher handedness
# based on the "Barrels" definintion created by Tom Tango
countBarrels <- function(df, hand) {
  barrels_98 <- df %>%
    filter(pitcher_hand == hand & exit_velo >= 98 & exit_velo < 99 & vert_angle >= 26 & vert_angle <= 30)
  barrels_99 <- df %>%
    filter(pitcher_hand == hand & exit_velo >= 99 & exit_velo < 100 & vert_angle >= 25 & vert_angle <= 31)
  barrels <- nrow(barrels_98) + nrow(barrels_99)
  
  min <- 24
  max <- 33
  for (i in 100:115) {
    barrels_sub <- df %>%
      filter(pitcher_hand == hand & exit_velo >= i & exit_velo < i + 1 & vert_angle >= min & vert_angle <= max)
    barrels <- barrels + nrow(barrels_sub)
    min <- min - 1
    max <- max + 1
  }
  return(barrels)
}

getBarrels <- function(df) {
  barrels_98 <- df %>%
    filter(exit_velo >= 98 & exit_velo < 99 & vert_angle >= 26 & vert_angle <= 30)
  barrels_99 <- df %>%
    filter(exit_velo >= 99 & exit_velo < 100 & vert_angle >= 25 & vert_angle <= 31)
  barrels <- nrow(barrels_98) + nrow(barrels_99)
  
  min <- 24
  max <- 33
  for (i in 100:115) {
    barrels_sub <- df %>%
      filter(exit_velo >= i & exit_velo < i + 1 & vert_angle >= min & vert_angle <= max)
    barrels <- barrels + nrow(barrels_sub)
    min <- min - 1
    max <- max + 1
  }
  return(barrels)
}

# this function gets the stats for each batter split into pitcher handedness
handed_stats <- function(d, hand) {
  c.1B <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "1B"))
  c.2B <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "2B"))  
  c.3B <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "3B"))  
  c.HR <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "HR"))  
  c.H <- c.1B + c.2B + c.3B + c.HR
  c.BB <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "BB"))  
  c.OUT <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "OUT"))  
  c.HBP <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "HBP"))  
  c.RBOE <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "RBOE"))  
  c.SAC <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "OUT-SAC"))  
  c.K <- nrow(d %>% 
                 filter(pitcher_hand == hand & outcome == "OUT" & result == "S"))  
  c.PA <- length(unique((d %>%
                           filter(pitcher_hand == hand))$pa_key))
  c.AB <- c.PA - c.BB - c.SAC - c.HBP
  c.Avg <- c.H/c.AB
  c.OBP <- (c.H + c.BB + c.HBP)/(c.AB + c.BB + c.HBP + c.SAC)
  c.SLG <- (c.1B + 2*c.2B + 3*c.3B + 4*c.HR)/c.AB
  c.BABIP <- (c.H - c.HR)/(c.AB - c.K - c.HR + c.SAC)
  
  # the wOBA constants that I am using are from the FanGraphs website for 2017
  c.wOBA <- ((.693*c.BB+.723*c.HBP+.877*c.1B+1.232*c.2B+1.552*c.3B +1.98*c.HR)/
               (c.AB + c.BB + c.SAC + c.HBP))
  c.Barrels <- countBarrels(d, hand)
  c.avgVelo <- avg_exit_Velo(d, hand)
  c.LA <- avg_launch_angle(d, hand)
  data.frame(Hand = hand, PA = c.PA, AB = c.AB, H.per.PA = round(c.H*100/c.PA, digits = 2), 
             BB.per.PA = round(((c.BB/c.PA)*100), digits = 2), K.per.PA = round(((c.K/c.PA)*100), digits = 2),
             Avg = round(c.Avg, digits = 3), OBP = round(c.OBP, digits = 3), SLG = round(c.SLG, digits = 3), 
             OPS = round(c.OBP + c.SLG, digits = 3), wOBA = round(c.wOBA, digits = 3),
             BABIP = round(c.BABIP, digits = 3), barrels.per.PA=round(((c.Barrels/c.PA)*100), digits = 2),
             avg.exit.velo = round(c.avgVelo, digits = 2), avg.launch.angle = round(c.LA, digits = 2))
}

# get the handedness splits for each batter
stats_1r <- handed_stats(batter1, "RHP")
stats_1l <- handed_stats(batter1, "LHP")
stats_2r <- handed_stats(batter2, "RHP")
stats_2l <- handed_stats(batter2, "LHP")
stats_3r <- handed_stats(batter3, "RHP")
stats_3l <- handed_stats(batter3, "LHP")
stats_4r <- handed_stats(batter4, "RHP")
stats_4l <- handed_stats(batter4, "LHP")
stats_5r <- handed_stats(batter5, "RHP")
stats_5l <- handed_stats(batter5, "LHP")

# combine the splits for each batter
batter1_total <- rbind(stats_1r, stats_1l)
batter2_total <- rbind(stats_2r, stats_2l)
batter3_total <- rbind(stats_3r, stats_3l)
batter4_total <- rbind(stats_4r, stats_4l)
batter5_total <- rbind(stats_5r, stats_5l)


# this function gets the total stats for each batter
get_stats <- function(d) {
  c.PA <- length(unique(d$pa_key))
  c.1B <- length(subset(d, outcome == "1B")$outcome)
  c.2B <- length(subset(d, outcome == "2B")$outcome)
  c.3B <- length(subset(d, outcome == "3B")$outcome)
  c.HR <- length(subset(d, outcome == "HR")$outcome)
  c.H <- c.1B + c.2B + c.3B + c.HR
  c.BB <- length(subset(d, outcome == "BB")$outcome)
  c.OUTS <- length(subset(d, outcome == "OUT")$outcome)
  c.HBP <- length(subset(d, outcome == "HBP")$outcome)
  c.RBOE <- length(subset(d, outcome == "RBOE")$outcome)
  c.SAC <- length(subset(d, outcome == "OUT-SAC")$outcome)
  c.K <- length(subset(d, outcome == "OUT" & result == "S")$outcome)
  c.AB <- c.PA - c.BB - c.SAC - c.HBP
  c.Avg <- c.H/c.AB
  c.OBP <- (c.H + c.BB + c.HBP)/(c.AB + c.BB + c.HBP + c.SAC)
  c.SLG <- (c.1B + 2*c.2B + 3*c.3B + 4*c.HR)/c.AB
  c.BABIP <- (c.H - c.HR)/(c.AB - c.K - c.HR + c.SAC)
  
  # the wOBA constants that I am using are from the FanGraphs website for 2017
  c.wOBA <- ((.693*c.BB + .723*c.HBP + .877*c.1B + 1.232*c.2B + 1.552*c.3B + 1.98*c.HR)/
               (c.AB + c.BB + c.SAC + c.HBP))
  c.Barrels <- getBarrels(d)
  c.avgVelo <- getAvgVelo(d)
  c.LA <- getAvgAngle(d)
  data.frame(PA = c.PA, AB = c.AB, H.per.PA = round(c.H*100/c.PA, digits = 2), 
             BB.per.PA = round(((c.BB/c.PA)*100), digits = 2), K.per.PA = round(((c.K/c.PA)*100), digits = 2),
             Avg = round(c.Avg, digits = 3), OBP = round(c.OBP, digits = 3), SLG = round(c.SLG, digits = 3), 
             OPS = round(c.OBP + c.SLG, digits = 3), wOBA = round(c.wOBA, digits = 3),
             BABIP = round(c.BABIP, digits = 3), barrels.per.PA=round(((c.Barrels/c.PA)*100), digits = 2),
             avg.exit.velo = round(c.avgVelo, digits = 2), avg.launch.angle = round(c.LA, digits = 2))
}

# get the total stats for each batter
stats_1 <- get_stats(batter1)
stats_2 <- get_stats(batter2)
stats_3 <- get_stats(batter3)
stats_4 <- get_stats(batter4)
stats_5 <- get_stats(batter5)

# comine the toal stats into one table
total_stats <- rbind(stats_1, stats_2, stats_3, stats_4, stats_5)

#  display the tables
total_stats
batter1_total
batter2_total
batter3_total
batter4_total
batter5_total

# creates plots showing the locations of pitches that were swung at by the top two batters
# takes a random sample of 1000 pitches for each batter

# average strike zone parameters
inZone <- -.95
outZone <- 0.95
topZone <- 3.5
botZone <- 1.6

# strike zone
kZone <- data.frame(x = c(inZone, inZone, outZone, outZone, inZone), y = c(botZone, topZone, topZone, botZone, botZone))

# random samples from each batter
sampleRows3L <- sample(1:nrow(subset(batter3, swing == "swing", batter_hand == "LHB")), 2000)
sampleRows3R <- sample(1:nrow(subset(batter3, swing == "swing", batter_hand == "RHB")), 2000)
sampleRows5 <- sample(1:nrow(subset(batter5, swing == "swing")), 2000)

ggplot(filter(batter5, swing == "swing")[sampleRows5,], aes (x = pitch_x, y = pitch_z)) +
  stat_density2d(aes(fill = ..level.., alpha = ..level..), geom = 'polygon', colour = 'black') +
  scale_fill_continuous(low = "blue", high = "firebrick") +
  guides(alpha = "none") + geom_point(size = 0.2) + geom_path(aes(x,y), data = kZone, lwd = 2, col = "black", alpha = .6) + 
  coord_equal() + ggtitle("Contact for Batter 5")

ggplot(filter(batter3, swing == "swing")[sampleRows3R,], aes (x = pitch_x, y = pitch_z)) +
  stat_density2d(aes(fill = ..level.., alpha = ..level..), geom = 'polygon', colour = 'black') +
  scale_fill_continuous(low = "blue", high = "firebrick") +
  guides(alpha = "none") + geom_point(size = 0.2) + geom_path(aes(x,y), data = kZone, lwd = 2, col = "black", alpha = .6) + 
  coord_equal() + ggtitle("Contact for Batter 3 Righty")

ggplot(filter(batter3, swing == "swing")[sampleRows3L,], aes (x = pitch_x, y = pitch_z)) +
  stat_density2d(aes(fill = ..level.., alpha = ..level..), geom = 'polygon', colour = 'black') +
  scale_fill_continuous(low = "blue", high = "firebrick") +
  guides(alpha = "none") + geom_point(size = 0.2) + geom_path(aes(x,y), data = kZone, lwd = 2, col = "black", alpha = .6) + 
  coord_equal() + ggtitle("Contact for Batter 3 Lefty")
