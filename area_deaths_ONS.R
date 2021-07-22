
# area_deaths_ONS.R
#
# Author: Bob Verity
# Date: 2020-12-08
#
# Purpose:
# Explore whether the same or different regions of the UK are being hit in the
# second COVID-19 wave, using death data from ONS.
#
# ------------------------------------------------------------------

# load packages
library(dplyr)
library(ggplot2)

# read in raw data
dat_raw_2020 <- read.csv("data/ons_deaths_2020.csv")
dat_raw_2021 <- read.csv("data/ons_deaths_2021.csv")

# week number in 2021 should continue from 2020
dat_raw_2021$Week.number <- dat_raw_2021$Week.number + max(dat_raw_2020$Week.number)

# combine years
dat_raw <- rbind(dat_raw_2020, dat_raw_2021)

# split into COVID vs all cause deaths
dat_covid <- dat_raw %>%
  filter(Cause.of.death == "COVID 19")
dat_all <- dat_raw %>%
  filter(Cause.of.death == "All causes")

# merge back together with separate columns for COVID vs all
dat_covid <- dat_covid %>%
  rename(deaths_covid = Number.of.deaths) %>%
  select(-"Cause.of.death")
dat_all <- dat_all %>%
  rename(deaths_all = Number.of.deaths) %>%
  select(-"Cause.of.death")
dat <- merge(dat_covid, dat_all)

# filter by place of death
place_death <- c("Hospital", "Care home", "Home")
dat <- dat %>% filter(Place.of.death %in% place_death)
dat$Place.of.death <- factor(dat$Place.of.death, levels = place_death)

# get proportion COVID deaths
dat$prop_covid <- dat$deaths_covid / dat$deaths_all

# get proportion COVID deaths in first wave (up to a given week)
dat_wave1 <- dat %>%
  filter(Week.number < 36) %>%
  group_by(Area.name) %>%
  summarise(prop_covid_wave1 = mean(prop_covid, na.rm = TRUE))

# order by proportion deaths in first wave
dat_wave1 <- dat_wave1[order(dat_wave1$prop_covid_wave1, decreasing = FALSE),]
dat_wave1$rank <- 1:nrow(dat_wave1)

# merge back
dat <- merge(dat, dat_wave1)
dat$Area.name <- factor(dat$Area.name, levels = dat_wave1$Area.name)

# convert weeks to calendar time
max_weeks <- max(dat$Week.number)
dat$date <- seq(as.Date("2020-01-01"), length.out = max_weeks, by = "weeks")[dat$Week.number]

# subset to areas with complete data for the whole time series
df_complete <- dat %>%
  dplyr::group_by(Area.code) %>%
  dplyr::summarise(n = n()) %>%
  dplyr::filter(n == max_weeks * 3)

dat <- dat %>%
  dplyr::filter(Area.code %in% df_complete$Area.code)

# ----------------------------------------------------------------

# plot
plot1 <- ggplot(data = dat) + theme_bw() +
  geom_raster(aes(x = date, y = Area.name, fill = prop_covid)) +
  scale_fill_viridis_c(option = "magma", na.value = "black", name = "Proportion\ndeaths due to\nCOVID-19\n") +
  facet_wrap(~Place.of.death) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  scale_x_date(expand = c(0, 0), date_breaks = "6 month",
               date_labels = "%y-%b") +
  xlab("Date") + ylab("") +
  coord_cartesian(xlim = range(dat$date), clip = "off") +
  theme(strip.background = element_blank(),
        strip.text = element_text(size = 10, face = "bold"),
        panel.grid.minor.x = element_blank()) +
  ggtitle("Did areas hit hard in the first wave\nexperience softer second waves?")

# annotate with text
df_ann <- data.frame(x = as.Date("2019-02-01"),
                     y = c(15, 330),
                     label = c("Areas spared\nin first wave", "Areas hit hard\nin first wave"),
                     Place.of.death = "Hospital")
df_ann$Place.of.death <- factor(df_ann$Place.of.death, levels = levels(dat$Place.of.death))

plot1 <- plot1 +
  theme(plot.margin = unit(c(0.5, 0.5, 0.5, 3), "cm")) +
  geom_text(aes(x = x, y = y, label = label), size = 3.5, data = df_ann)

# anotate with arrow
df_arrow <- data.frame(x = df_ann$x,
                       y = c(170, 170),
                       yend = c(305, 40),
                       Place.of.death = "Hospital")
df_arrow$Place.of.death <- factor(df_arrow$Place.of.death, levels = levels(dat$Place.of.death))

plot1 <- plot1 +
  geom_segment(aes(x = x, xend = x, y = y, yend = yend), arrow = arrow(length = unit(0.3, "cm")),
               data = df_arrow)

# add caption
plot1 <- plot1 +
  labs(caption = "\nData from ONS (https://tinyurl.com/y7vefxce). England and Wales only\ncode available at https://github.com/bobverity/COVID_datavis") +
  theme(plot.caption = element_text(hjust = 0))

plot1

# save plot to file
ggsave("output/prop_covid_deaths_by_area.png", width = 7, height = 6)

# save data to file
saveRDS(dat, file = "output/area_deaths_data.rds")

