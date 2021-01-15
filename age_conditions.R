# age_conditions.R
#
# Author: Bob Verity
# Date: 2021-01-15
#
# Purpose:
# Explore what the age-deaths profile looks like for people with vs without
# pre-existing conditions.
#
# ------------------------------------------------------------------

# load packages
library(ggplot2)
library(tidyr)
library(RColorBrewer)

# read in data
dat <- read.csv("data/referencetables_6b.csv")

# fix field formats
dat$Age <- factor(dat$Age, levels = unique(dat$Age))
dat$Number.of.deaths <- as.numeric(gsub(",", "", dat$Number.of.deaths))

# subset to all sexes
dat <- subset(dat, Sex == "Persons")

# subset pre-existing conditions
dat <- subset(dat, Main.pre.existing.condition %in% c("All deaths involving COVID-19", "No pre-existing condition"))

# get into wide format
dat_wide <- spread(dat, Main.pre.existing.condition, Number.of.deaths)

# get deaths with at least 1 pre-existing condition
dat_wide$Any_preexisting <- dat_wide$`All deaths involving COVID-19` - dat_wide$`No pre-existing condition`

# rename some columns
w <- match(c("No pre-existing condition", "Any_preexisting"), names(dat_wide))
names(dat_wide)[w] <- c("No_preexisting", "Any_preexisting")

# subset columns
dat_wide <- subset(dat_wide, select = c("Age", "No_preexisting", "Any_preexisting"))

# get into long format
dat <- gather(dat_wide, Conditions, Deaths, No_preexisting, Any_preexisting)

# define colours
col_vec <- RColorBrewer::brewer.pal(3, "Set1")

# make final titles
dat$Conditions <- c("No pre-existing\nconditions", "At least one pre-existing\ncondition")[match(dat$Conditions, c("No_preexisting", "Any_preexisting"))]

# produce plot
plot1 <- ggplot(dat) + theme_bw() +
  geom_bar(aes(x = Age, y = Deaths, fill = Conditions), position = "dodge", stat = "identity", width = 0.95) +
  ylab("Deaths involving COVID-19\nMarch - June 2020") +
  guides(fill = FALSE) +
  facet_wrap(~Conditions, scales = "free") +
  theme(strip.background = element_blank(),
        strip.text = element_text(size = 10),
        axis.text.x = element_text(size = 6))

# add caption
plot1 <- plot1 +
  labs(caption = "\nData from ONS (https://tinyurl.com/y7zduhya) Table 6b (England only)\ncode available at https://github.com/bobverity/COVID_datavis") +
  theme(plot.caption = element_text(hjust = 0))

plot1

# save to file
ggsave("output/age_conditions.png", width = 7, height = 4)
