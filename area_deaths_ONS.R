
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
dat_raw <- read.csv("data/ons_week47.csv")

# split into COVID vs all cause deaths
dat_covid <- dat_raw %>%
  filter(Cause.of.death == "COVID 19")
dat_all <- dat_raw %>%
  filter(Cause.of.death == "All causes")

# merge together
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
  filter(Week.number <= 30) %>%
  group_by(Area.name) %>%
  summarise(prop_covid_wave1 = mean(prop_covid, na.rm = TRUE))

# order by proportion deaths in first wave
dat_wave1 <- dat_wave1[order(dat_wave1$prop_covid_wave1, decreasing = FALSE),]
dat_wave1$rank <- 1:nrow(dat_wave1)

# merge back
dat <- merge(dat, dat_wave1)
dat$Area.name <- factor(dat$Area.name, levels = dat_wave1$Area.name)

# convert weeks to calendar time

# ----------------------------------------------------------------

# plot
plot1 <- ggplot(data = dat) + theme_bw() +
  geom_raster(aes(x = Week.number, y = Area.name, fill = prop_covid)) +
  scale_fill_viridis_c(option = "magma", na.value = "black", name = "Proportion\ndeaths due to\nCOVID-19\n") +
  facet_wrap(~Place.of.death) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  scale_x_continuous(expand = c(0, 0)) +
  xlab("Week (year 2020)") + ylab("") +
  coord_cartesian(xlim = range(dat$Week.number), clip = "off") +
  theme(strip.background = element_blank(),
        strip.text = element_text(size = 10, face = "bold")) +
  ggtitle("Has the second wave affected the same or different\nparts of the UK?")

# annotate
df_ann <- data.frame(x = -20,
                     y = c(15, 330),
                     label = c("Areas spared\nin first wave", "Areas hit hard\nin first wave"),
                     Place.of.death = "Hospital")
df_ann$Place.of.death <- factor(df_ann$Place.of.death)

plot1 <- plot1 +
  theme(plot.margin = unit(c(0.5, 0.5, 0.5, 3), "cm")) +
  geom_text(aes(x = x, y = y, label = label), size = 3.5, data = df_ann) +
  annotate("segment", x = -20, y = 170, xend = -20, yend = 305,
           arrow = arrow(length = unit(0.3, "cm"))) +
  annotate("segment", x = -20, y = 170, xend = -20, yend = 40,
           arrow = arrow(length = unit(0.3, "cm")))

# add caption
plot1 <- plot1 +
  labs(caption = "\nData from ONS (https://tinyurl.com/y7vefxce). England and Wales only\ncode available at www.github.com/bobverity/COVID_datavis") +
  theme(plot.caption = element_text(hjust = 0))

plot1

# save to file
ggsave("output/prop_covid_deaths_by_area.png", width = 7, height = 6)

