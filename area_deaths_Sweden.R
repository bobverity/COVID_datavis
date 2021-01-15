
# area_deaths_Sweden.R
#
# Author: Bob Verity
# Date: 2020-12-08
#
# Purpose:
# Explore whether the same or different regions of Sweden are being hit in the
# second COVID-19 wave.
#
# ------------------------------------------------------------------

library(ggplot2)
library(dplyr)

# read in deaths data
dat <- read.csv("data/Sweden.csv")

# format and filter
dat$Date <- as.Date(dat$Date, format = "%d/%m/%y")
dat <- subset(dat, Date >= as.Date("2020-03-13"))
dat$Deaths_today[dat$Deaths_today < 0] <- NA

# define regional population sizes
# credit to http://lacey.se/c19/
counties <- data.frame(
  Region = c("Stockholm", "Västmanland", "Värmland", "Örebro", "Jämtland", "Blekinge",
             "Uppsala", "Sörmland", "Östergötland", "Gotland", "Jönköping", "Kronoberg",
             "Västernorrland", "Kalmar", "Skåne", "Halland", "Gävleborg", "Västra Götaland",
             "Dalarna", "Västerbotten", "Norrbotten"),
  Pop = c(2344124, 273929, 281482, 302252, 130280, 159684, 376354, 294695, 461583, 59249,
          360825, 199886, 245453, 244670, 1362164, 329352, 286547, 1709814, 287191, 270154,
          250497)
  )

# merge deaths with pop sizes
dat <- merge(dat, counties)

# get deaths per 100,000
dat$Deaths_per_pop <- dat$Deaths_today / dat$Pop * 1e5

# get COVID deaths in first wave (up to a given date)
dat_wave1 <- dat %>%
  filter(Date < as.Date("2020-09-01")) %>%
  group_by(Region) %>%
  summarise(prop_covid_wave1 = mean(Deaths_per_pop, na.rm = TRUE))

# order by deaths in first wave
dat_wave1 <- dat_wave1[order(dat_wave1$prop_covid_wave1, decreasing = FALSE),]
dat_wave1$rank <- 1:nrow(dat_wave1)

# merge back
dat <- merge(dat, dat_wave1)
dat$Region <- factor(dat$Region, levels = dat_wave1$Region)

# ----------------------------------------------------------------

# plot
plot1 <- ggplot(data = dat) + theme_bw() +
  geom_raster(aes(x = Date, y = Region, fill = Deaths_per_pop)) +
  scale_fill_viridis_c(option = "magma", na.value = "black", name = "Daily deaths\nper 100,000\npopulation\n") +
  scale_x_date(expand = c(0, 0)) +
  xlab("Date (year 2020)") + ylab("") +
  coord_cartesian(xlim = range(dat$Date), clip = "off") +
  theme(strip.background = element_blank(),
        strip.text = element_text(size = 10, face = "bold")) +
  ggtitle("Has the second wave affected the same or different\nparts of Sweden?")

# annotate with text
df_ann <- data.frame(x = as.Date("2019-12-01"),
                     y = c(2, 21),
                     label = c("Areas spared\nin first wave", "Areas hit hard\nin first wave"))

plot1 <- plot1 +
  theme(plot.margin = unit(c(0.5, 0.5, 0.5, 3), "cm")) +
  geom_text(aes(x = x, y = y, label = label), size = 3.5, data = df_ann)

# anotate with arrow
df_arrow <- data.frame(x = df_ann$x,
                       y = c(10, 10),
                       yend = c(19, 4))

plot1 <- plot1 +
  geom_segment(aes(x = x, xend = x, y = y, yend = yend), arrow = arrow(length = unit(0.3, "cm")),
               data = df_arrow)

# add caption
plot1 <- plot1 +
  labs(caption = "\nDeath data from (https://c19.se/en/Sweden). \nPopulation sizes from (http://lacey.se/c19/). \nCode available at https://github.com/bobverity/COVID_datavis") +
  theme(plot.caption = element_text(hjust = 0))

# save to file
ggsave("output/Sweden_deaths_by_area.png", width = 7, height = 6)
