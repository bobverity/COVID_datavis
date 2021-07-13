# age_vaccination.R
#
# Author: Bob Verity
# Date: 2021-07-09
#
# Purpose:
# Produce chloropleth plots of cases and deaths broken down by age. Explore how
# the "vaccine wall" interacts with these patterns.
#
# ------------------------------------------------------------------

library(stringr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(scico)
library(tidyr)
library(cowplot)
library(jsonlite)

# ------------------------------------------------------------------

# read in age-disaggregated case data
dat_cases <- read.csv("data/nation_E92000001_2021-07-13.csv")

# define age bands
age_lower <- stringr::str_pad(seq(0, 85, 5), width = 2, pad = "0")
age_upper <- stringr::str_pad(seq(0, 85, 5) + 4, width = 2, pad = "0")
age_band_names <- c(paste(age_lower, age_upper, sep = "_"), "90+")

# filter age bands
dat_cases <- dat_cases %>%
  dplyr::filter(age %in% age_band_names)

# format dates
dat_cases <- dat_cases %>%
  dplyr::mutate(date = as.Date(date, format = "%Y-%m-%d"))

# ------------------------------------------------------------------

# read in age-disaggregated deaths data
dat_deaths <- read.csv("data/age_deaths.csv")

# format dates
dat_deaths <- dat_deaths %>%
  dplyr::mutate(date = as.Date(date, format = "%d/%m/%Y"))

# ------------------------------------------------------------------

# get week number for case data to match deaths data
week_breaks <- seq(as.Date("2020-01-03"), as.Date("2022-01-01"), "week")
dat_cases <- dat_cases %>%
  dplyr::mutate(week_no = as.numeric(cut(date, breaks = week_breaks)))

# aggregate cases into weeks (cases now represent the mean over the week)
dat_cases <- dat_cases %>%
  dplyr::group_by(week_no, age) %>%
  dplyr::summarise(date = date,
                   age = age[1],
                   cases = mean(cases)) %>%
  dplyr::ungroup() %>%
  dplyr::select(date, age, cases)

# ------------------------------------------------------------------

# read in UK population pyramid data. NB, these data are originally sourced from ONS data here:
# https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/analysisofpopulationestimatestoolforuk
pop_raw <- read.csv("data/population_pyramid.csv")

# use same age 5-year age bands
pop <- data.frame(age_nice = factor(pop_raw$Age, levels = pop_raw$Age),
                  age = age_band_names,
                  pop = pop_raw$All)

# merge weekly cases with demographics and get proportion cases (per 100k) in each age group
dat_cases <- dat_cases %>%
  dplyr::left_join(pop) %>%
  dplyr::mutate(cases_per_100k = cases / pop * 1e5)

# same for deaths
dat_deaths <- dat_deaths %>%
  dplyr::left_join(pop) %>%
  dplyr::mutate(deaths_per_100k = deaths / pop * 1e5)

# ------------------------------------------------------------------

# read in vaccination data
vacc_raw <- jsonlite::fromJSON("data/vaccination.json")

# extract age-breakdown as list
vacc_list <- vacc_raw$data$vaccinationsAgeDemographics

# get into long format dataframe
vacc_df <- do.call(rbind, mapply(function(i) {
  ret <- vacc_list[[i]]
  ret$date <- vacc_raw$data$date[i]
  ret
}, seq_along(vacc_list), SIMPLIFY = FALSE))

# format dates
vacc_df <- vacc_df %>%
  dplyr::mutate(date = as.Date(date, format = "%Y-%m-%d"))

# merge with demographic data (for nice age bands) and get simplified vaccination coverage as percentage
vacc_df <- vacc_df %>%
  dplyr::left_join(pop) %>%
  dplyr::filter(!is.na(pop)) %>%
  dplyr::mutate(cov = cumVaccinationCompleteCoverageByVaccinationDatePercentage) %>%
  dplyr::select(age, age_nice, cov, date)

# fill in missing dates with 0 coverage
vacc_buffer <- as.data.frame(expand_grid(age = unique(vacc_df$age),
                                         date = seq(as.Date("2020-01-03"), as.Date("2020-12-07"), "day")))
vacc_buffer$cov <- 0
vacc_buffer <- vacc_buffer %>%
  dplyr::left_join(pop) %>%
  dplyr::select(age, age_nice, cov, date)

vacc_df <- rbind(vacc_df, vacc_buffer)

# ------------------------------------------------------------------

# plot
plot1 <- ggplot(dat_cases) + theme_bw() +
  geom_tile(aes(x = date, y = age_nice, fill = cases_per_100k)) +
  scico::scale_fill_scico(palette = "vik", name = "Daily cases\nper 100 thousand\n(linear scale)\n                                    ") +
  xlab("Date") + ylab("Age group") + ggtitle("Cases") +
  scale_x_date(limits = c(as.Date("2020-02-01"), as.Date("2021-07-08")), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

plot2 <- ggplot(dat_deaths) + theme_bw() +
  geom_tile(aes(x = date, y = age_nice, fill = deaths_per_100k / 7)) +
  scico::scale_fill_scico(palette = "vik", trans = "log", breaks = c(0.1, 1, 10, 100), name = "Daily deaths\nper 100 thousand\n(log scale)\n                                    ") +
  xlab("Date") + ylab("Age group") + ggtitle("Deaths") +
  scale_x_date(limits = c(as.Date("2020-02-01"), as.Date("2021-07-08")), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

plot3 <- ggplot(vacc_df) + theme_bw() +
  geom_tile(aes(x = date, y = age_nice, fill = cov)) +
  scale_fill_viridis_c(option = "A", limits = c(0, 100), name = "Proportion fully\nvaccinated (%)\n                                    ") +
  xlab("Date") + ylab("Age group") + ggtitle("Vaccination") +
  scale_x_date(limits = c(as.Date("2020-02-01"), as.Date("2021-07-08")), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

# produce main title
title_gg <- ggplot() + 
  labs(title = 'How does age interact with vaccination to explain\ncurrent trends?') +
  theme(plot.title = element_text(size = 22))

# produce combined plot
plot_c <- cowplot::plot_grid(title_gg, plot3, plot1, plot2, ncol = 1, rel_heights = c(0.35, rep(1, 3)))

# add caption
plot_c <- plot_c +
  labs(caption = "\nCode and full data description available at https://github.com/bobverity/COVID_datavis") +
  theme(plot.caption = element_text(hjust = 0, vjust = 1, size = 10))

plot_c

# save to file
ggsave("output/age_vaccination.png", width = 9, height = 8)
