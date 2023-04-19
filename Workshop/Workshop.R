
# Set up session
# library(tidyverse)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(tibble)
library(stringr)
library(forcats)
library(stargazer)
setwd("/Users/pfer/Desktop")

AFL_data_set <- read_csv("AFL_data_set.csv")

# Question 1 - What are the statistical properties of the performance measures?

stargazer(data.frame(AFL_data_set), type = "text")

plot(density(AFL_data_set$Goals), main='Goals',
     xlab='No. of Goals')

plot(density(AFL_data_set$Disposals), main='Disposals',
     xlab='No. of Disposals')

# 1b

AFL_data_set <- AFL_data_set %>%
  group_by(Player_ID) %>%
  mutate(Disposals_lag = lag(Disposals, order_by=Game_ID),
         Distance_lag = lag(GameTotalDistance_km, order_by=Game_ID))

time_series_disposals <- AFL_data_set %>%
  group_by(Disposals_lag) %>%
  summarize(avg_Disposals=mean(Disposals))

plot(time_series_disposals$Disposals_lag, time_series_disposals$avg_Disposals,
     xlab='Disposals at t-1', ylab='Avg. Disposals at t')

# Question 2 - How are the performance measures related to team success?

# 2a and 2b 
grouped <- AFL_data_set %>%
  group_by(Game_ID) %>%
  summarise(avg_GameTotalMins=mean(GameTotalMins),
            avg_GameTotalDistance_km=mean(GameTotalDistance_km),
            avg_Disposals=mean(Disposals),
            avg_Disposal_efficiency=mean(Disposal_efficiency),
            avg_Goals=mean(Goals), avg_Tackles=mean(Tackles),
            avg_Marks=mean(Marks), avg_Clearances=mean(Clearances),
            Margin=mean(Margin))

cor_matrix <- cor(grouped)

cor_margin <- round(cor_matrix[,10],2)
cor_margin

plot(grouped$avg_GameTotalDistance_km, grouped$Margin,
     xlab='Avg. Running Distance', ylab='Margin')

plot(grouped$avg_Disposals, grouped$Margin,
     xlab='Avg. Disposals', ylab='Margin')

plot(grouped$avg_Tackles, grouped$Margin,
     xlab='Avg. Tackles', ylab='Margin')

midfielders <- AFL_data_set %>%
  filter(Position=="MIDFIELD") %>%
  group_by(Game_ID) %>%
  summarise(avg_GameTotalMins=mean(GameTotalMins),
            avg_GameTotalDistance_km=mean(GameTotalDistance_km),
            avg_Disposals=mean(Disposals),
            avg_Disposal_efficiency=mean(Disposal_efficiency),
            avg_Goals=mean(Goals), avg_Tackles=mean(Tackles),
            avg_Marks=mean(Marks), avg_Clearances=mean(Clearances),
            Margin=mean(Margin))

defenders <- AFL_data_set %>%
  filter(Position=="DEFENCE") %>%
  group_by(Game_ID) %>%
  summarise(avg_GameTotalMins=mean(GameTotalMins),
            avg_GameTotalDistance_km=mean(GameTotalDistance_km),
            avg_Disposals=mean(Disposals),
            avg_Disposal_efficiency=mean(Disposal_efficiency),
            avg_Goals=mean(Goals), avg_Tackles=mean(Tackles),
            avg_Marks=mean(Marks), avg_Clearances=mean(Clearances),
            Margin=mean(Margin))

plot(defenders$avg_Disposals, defenders$Margin,
     xlab='Avg. Disposals', ylab='Margin', col="Green")

plot(midfielders$avg_Disposals, midfielders$Margin,
     xlab='Avg. Disposals', ylab='Margin', col="Red")

# Question 3 - Controlling for differences in inputs: How do we construct measures of performance efficiency?

# 3a

cor_matrix_player_level <- AFL_data_set %>%
  select(-Position) %>%
  cor()

cor_mins <- round(cor_matrix_player_level[,3],2)
cor_mins

AFL_data_set <- AFL_data_set %>%
  mutate(Disposals_per_min=Disposals/GameTotalMins,
         Goals_per_min=Goals/GameTotalMins,
         Tackles_per_min=Tackles/GameTotalMins,
         Marks_per_min=Marks/GameTotalMins,
         Clearances_per_min=Clearances/GameTotalMins)

# Question 4 - Is worker performance within teams interdependent?

# 4a

interdependent <- AFL_data_set %>%
  group_by(Game_ID) %>%
  summarise(avg_Disposals_mid=mean(Disposals[Position=="MIDFIELD"], na.rm=TRUE),
            avg_Goals_fwd=mean(Goals[Position=="FORWARD"], na.rm=TRUE))

plot(interdependent$avg_Disposals_mid, interdependent$avg_Goals_fwd,
     xlab='Avg. Disposals per midfielder', ylab='Avg. Goals per forward')

# 4b

abline(lm(avg_Goals_fwd ~ avg_Disposals_mid, data = interdependent), col = "blue")

summary(lm(avg_Goals_fwd ~ avg_Disposals_mid, data = interdependent))


# Question 5 - How to identify (and filter out) common noise?

# 5a
AFL_data_set <- AFL_data_set %>%
  mutate(Wet=ifelse(Rainfall_mm>0, 1, 0),
         Wind=ifelse(Wind_mph>median(Wind_mph), 1, 0))

plot(density(filter(AFL_data_set, Wet == 1)$Disposal_efficiency), col='blue', main='Wet weather as a negative performance shock',
     xlab='Disposal efficiency')
lines(density(filter(AFL_data_set, Wet == 0)$Disposal_efficiency), col="red")
legend("topright", legend=c("Wet", "Dry"),
       col=c("blue", "red"), lty=1, cex=0.8)

plot(density(filter(AFL_data_set, Wet == 0)$Tackles), col='red', main='Wet weather as a positive performance shock',
     xlab='Tackles')
lines(density(filter(AFL_data_set, Wet == 1)$Tackles), col="blue")
legend("topright", legend=c("Wet", "Dry"),
       col=c("blue", "red"), lty=1, cex=0.8)

# 5b

AFL_data_set <- AFL_data_set %>%
  group_by(Game_ID) %>%
  mutate(avg_Disposal_efficiency=mean(Disposal_efficiency),
         abn_Disposal_efficiency=(Disposal_efficiency-avg_Disposal_efficiency)/avg_Disposal_efficiency) %>%
  ungroup()

plot(density(filter(AFL_data_set, Wet == 1)$abn_Disposal_efficiency), col='blue', main='Filtering out a common shock',
     xlab='Abnormal Disposal Efficiency (Normalized)')
lines(density(filter(AFL_data_set, Wet == 0)$abn_Disposal_efficiency), col="red")
legend("topright", legend=c("Wet", "Dry"),
       col=c("blue", "red"), lty=1, cex=0.8)

