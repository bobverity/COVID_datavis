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
# CASES

# read in age-disaggregated case data
# from https://coronavirus.data.gov.uk/details/download
dat_cases <- read.csv("data/nation_E92000001_2021-07-21.csv")

# define age bands
age_df <- data.frame(age_lower = seq(0, 90, 5),
                     age_upper = c(seq(4, 89, 5), Inf),
                     age = c("00_04", "05_09", "10_14", "15_19", "20_24", "25_29", 
                             "30_34", "35_39", "40_44", "45_49", "50_54", "55_59", 
                             "60_64", "65_69", "70_74", "75_79", "80_84", "85_89", "90+"))

# merge age bands
dat_cases <- dat_cases %>%
  dplyr::filter(age %in% age_df$age) %>%
  dplyr::left_join(age_df)

# format dates
dat_cases <- dat_cases %>%
  dplyr::mutate(date = as.Date(date, format = "%Y-%m-%d"))

# ------------------------------------------------------------------
# DEATHS

# read in age-disaggregated deaths data
# from https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/datasets/weeklyprovisionalfiguresondeathsregisteredinenglandandwales
dat_deaths <- read.csv("data/age_deaths.csv")

# merge age bands
dat_deaths <- dat_deaths %>%
  dplyr::filter(age %in% age_df$age) %>%
  dplyr::left_join(age_df)

# format dates
dat_deaths <- dat_deaths %>%
  dplyr::mutate(date = as.Date(date, format = "%d/%m/%Y"))

# divide death figures by 7 to get daily deaths
dat_deaths <- dat_deaths %>%
  dplyr::mutate(deaths = deaths / 7)

# ------------------------------------------------------------------
# AGGREGATE CASES

# get week number for case data to match deaths data
week_breaks <- seq(as.Date("2020-01-03"), as.Date("2022-01-01"), "week")
dat_cases <- dat_cases %>%
  dplyr::mutate(week_no = as.numeric(cut(date, breaks = week_breaks)))

# get proportion of a week that is covered by data
cases_prop_week <- dat_cases %>%
  dplyr::group_by(week_no) %>%
  dplyr::summarise(prop_week = n() / 7 / nrow(age_df)) %>%
  dplyr::filter(prop_week == 1)

# filter to complete weeks only
dat_cases <- dat_cases %>%
  dplyr::filter(week_no %in% cases_prop_week$week_no)

# aggregate cases into weeks (cases now represent the mean over the week, and so
# are daily values)
dat_cases <- dat_cases %>%
  dplyr::group_by(week_no, age) %>%
  dplyr::summarise(date = date,
                   age = age[1],
                   age_lower = age_lower[1],
                   age_upper = age_upper[1],
                   cases = mean(cases)) %>%
  dplyr::ungroup() %>%
  dplyr::select(date, age, age_lower, age_upper, cases)

# ------------------------------------------------------------------
# HOSPITALISATIONS

# read in hospitalisation data
# from https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-hospital-activity/
dat_hosp <- read.csv("data/England_age_hospitalisation.csv")

# format dates
dat_hosp <- dat_hosp %>%
  dplyr::mutate(date = as.Date(date, "%d/%m/%Y"))

# get into long format
dat_hosp <- dat_hosp %>%
  tidyr::pivot_longer(cols = -date, names_to = "age", values_to = "hospitalisations")

# format age levels
age_df_hosp <- data.frame(age_lower = c(0, 6, 18, 65, 85),
                          age_upper = c(5, 17, 64, 84, Inf),
                          age = c("X0_5", "X6_17", "X18_64", "X65_84", "X85_999"))

dat_hosp <- dat_hosp %>%
  dplyr::left_join(age_df_hosp) %>%
  dplyr::select(-age)

# ------------------------------------------------------------------
# VACCINATION

# read in vaccination data
# from https://coronavirus.data.gov.uk/details/vaccinations?areaType=nation&areaName=England
vacc_raw <- jsonlite::fromJSON("data/vaccination.json")

# extract age-breakdown as list
vacc_list <- vacc_raw$data$vaccinationsAgeDemographics

# get into long format dataframe
dat_vacc <- do.call(rbind, mapply(function(i) {
  ret <- vacc_list[[i]]
  ret$date <- vacc_raw$data$date[i]
  ret
}, seq_along(vacc_list), SIMPLIFY = FALSE))

# format dates
dat_vacc <- dat_vacc %>%
  dplyr::mutate(date = as.Date(date, format = "%Y-%m-%d"))

# get simplified vaccination coverage as percentage
dat_vacc <- dat_vacc %>%
  dplyr::mutate(cov = cumVaccinationCompleteCoverageByVaccinationDatePercentage) %>%
  dplyr::select(date, age, cov)

# fill in missing dates with 0 coverage
vacc_buffer <- as.data.frame(expand_grid(age = unique(dat_vacc$age),
                                         date = seq(as.Date("2020-01-03"), as.Date("2020-12-07"), "day")))

vacc_buffer <- vacc_buffer %>%
  dplyr::mutate(cov = 0) %>%
  dplyr::select(date, age, cov)

dat_vacc <- rbind(dat_vacc, vacc_buffer)

# format age levels
age_df_vacc <- data.frame(age_lower = c(18, seq(25, 90, 5)),
                          age_upper = c(seq(24, 89, 5), Inf),
                          age = c("18_24", "25_29", "30_34", "35_39", "40_44", "45_49", "50_54", 
                                  "55_59", "60_64", "65_69", "70_74", "75_79", "80_84", "85_89", 
                                  "90+"))

dat_vacc <- dat_vacc %>%
  dplyr::left_join(age_df_vacc) %>%
  dplyr::select(-age)

# ------------------------------------------------------------------
# DEMOGRAPHICS

# read in UK population pyramid data
# from https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/analysisofpopulationestimatestoolforuk
pop_raw <- read.csv("data/population_pyramid.csv")

# get into same 5-year age bands as cases and deaths
pop_5y <- pop_raw %>%
  dplyr::mutate(age_band = as.numeric(cut(age_lower, breaks = seq(0, 100, 5), right = FALSE))) %>%
  dplyr::group_by(age_band) %>%
  dplyr::summarise(age_lower = min(age_lower),
                   age_upper = max(age_upper),
                   pop = sum(all)) %>%
  dplyr::mutate(age_nice = paste(age_lower, age_upper, sep = " to ")) %>%
  dplyr::mutate(age_nice = replace(age_nice, age_nice =="90 to Inf", "90+")) %>%
  dplyr::mutate(age_nice = factor(age_nice, levels = age_nice)) %>%
  dplyr::select(-age_band)

# merge weekly cases with demographics and get proportion cases (per 100k) in each age group
dat_cases <- dat_cases %>%
  dplyr::left_join(pop_5y) %>%
  dplyr::mutate(cases_per_100k = cases / pop * 1e5)

# same for deaths
dat_deaths <- dat_deaths %>%
  dplyr::left_join(pop_5y) %>%
  dplyr::mutate(deaths_per_100k = deaths / pop * 1e5)

# get into same age bands as hospitalisations
pop_hosp <- pop_raw %>%
  dplyr::mutate(age_band = as.numeric(cut(age_lower, breaks = c(0, age_df_hosp$age_upper), include.lowest = TRUE))) %>%
  dplyr::group_by(age_band) %>%
  dplyr::summarise(age_lower = min(age_lower),
                   age_upper = max(age_upper),
                   pop = sum(all)) %>%
  dplyr::mutate(age_nice = paste(age_lower, age_upper, sep = " to ")) %>%
  dplyr::mutate(age_nice = replace(age_nice, age_nice =="90 to Inf", "90+")) %>%
  dplyr::mutate(age_nice = factor(age_nice, levels = age_nice)) %>%
  dplyr::select(-age_band)

# merge weekly hospitalisations with demographics and get proportion (per 100k)
# in each age group
dat_hosp <- dat_hosp %>%
  dplyr::left_join(pop_hosp) %>%
  dplyr::mutate(hosps_per_100k = hospitalisations / pop * 1e5)

# ------------------------------------------------------------------
# PLOTS

# set plotting date range
min_date <- as.Date("2020-02-01")
max_date <- max(max(dat_cases$date),
                max(dat_deaths$date),
                max(dat_vacc$date))

# plot vaccinations
plot1 <- dat_vacc %>%
  dplyr::mutate(age_upper = replace(age_upper, age_upper > 95, 95)) %>%
  dplyr::mutate(age_width = age_upper - age_lower + 1,
                age_mid = (age_upper + age_lower + 1) / 2) %>%
  ggplot() + theme_bw() +
  geom_tile(aes(x = date, y = age_mid, fill = cov, height = age_width)) +
  scale_fill_viridis_c(option = "A", limits = c(0, 100), name = "Proportion fully\nvaccinated (%)\n                                    ") +
  coord_cartesian(ylim = c(0, 95), expand = c(0, 0)) +
  xlab("Date") + ylab("Age") + ggtitle("Vaccination") +
  scale_x_date(limits = c(min_date, max_date), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

# plot cases
plot2 <- dat_cases %>%
  dplyr::mutate(age_upper = replace(age_upper, age_upper > 95, 95)) %>%
  dplyr::mutate(age_width = age_upper - age_lower + 1,
                age_mid = (age_upper + age_lower + 1) / 2) %>%
  ggplot() + theme_bw() +
  geom_tile(aes(x = date, y = age_mid, fill = cases_per_100k, height = age_width)) +
  scico::scale_fill_scico(palette = "vik", name = "Daily cases\nper 100 thousand\n(linear scale)\n                                    ") +
  coord_cartesian(ylim = c(0, 95), expand = c(0, 0)) +
  xlab("Date") + ylab("Age") + ggtitle("Cases") +
  scale_x_date(limits = c(min_date, max_date), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

# plot hospitalisations
plot3 <- dat_hosp %>%
  dplyr::mutate(age_upper = replace(age_upper, age_upper > 90, 90)) %>%
  dplyr::mutate(age_width = age_upper - age_lower + 1,
                age_mid = (age_upper + age_lower + 1) / 2) %>%
  ggplot() + theme_bw() +
  geom_tile(aes(x = date, y = age_mid, fill = hosps_per_100k, height = age_width)) +
  scico::scale_fill_scico(palette = "vik", trans = "log", breaks = c(0.1, 1, 10, 100), name = "Daily hospitalisations\nper 100 thousand\n(log scale)\n                                    ") +
  coord_cartesian(ylim = c(0, 95), expand = c(0, 0)) +
  xlab("Date") + ylab("Age") + ggtitle("Hospitalisations") +
  scale_x_date(limits = c(min_date, max_date), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

# plot deaths
plot4 <- dat_deaths %>%
  dplyr::mutate(age_upper = replace(age_upper, age_upper > 95, 95)) %>%
  dplyr::mutate(age_width = age_upper - age_lower + 1,
                age_mid = (age_upper + age_lower + 1) / 2) %>%
  ggplot() + theme_bw() +
  geom_tile(aes(x = date, y = age_mid, fill = deaths_per_100k, height = age_width)) +
  scico::scale_fill_scico(palette = "vik", trans = "log", breaks = c(0.1, 1, 10, 100), name = "Daily deaths\nper 100 thousand\n(log scale)\n                                    ") +
  coord_cartesian(ylim = c(0, 95), expand = c(0, 0)) +
  xlab("Date") + ylab("Age") + ggtitle("Deaths") +
  scale_x_date(limits = c(min_date, max_date), expand = c(0, 0)) +
  theme(strip.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

# produce main title
title_gg <- ggplot() + 
  labs(title = 'How does age interact with vaccination to explain\ncurrent trends?') +
  theme(plot.title = element_text(size = 22))

# produce combined plot
plot_c <- cowplot::plot_grid(title_gg, plot1, plot2, plot3, plot4, ncol = 1, rel_heights = c(0.35, rep(1, 4)))

# add caption
plot_c <- plot_c +
  labs(caption = "\nCode and full data description available at https://github.com/bobverity/COVID_datavis") +
  theme(plot.caption = element_text(hjust = 0, vjust = 1, size = 10))

plot_c

# save to file
ggsave("output/age_vaccination.png", width = 9, height = 10)
