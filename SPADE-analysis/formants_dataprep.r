library(stringr)
library(ggplot2)
ral.form = read.csv('../Raleigh/Raleigh_formants.csv')


ral.form <- subset(ral.form, UnisynPrimStressedVowel1 != 'N/A')
ral.form <- subset()

ggplot(ral.form)
