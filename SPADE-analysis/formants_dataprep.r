library(stringr)
library(ggplot2)
library(dplyr)
ral.form = read.csv('../Raleigh/Raleigh_formants.csv')
sotc.form = read.csv('../SOTC/SOTC_formants.csv')
icecan.form = read.csv('../ICECAN/ICECAN_formants.csv')

icecan.form %>% group_by(discourse,speaker) %>% summarise(n())

ral.form <- subset(ral.form, UnisynPrimStressedVowel1 != 'N/A')
ral.form <- subset()

ggplot(ral.form)

t <- subset(sotc.form, duration > 0.05)

ggplot(t, aes(x=F3)) + geom_histogram()
