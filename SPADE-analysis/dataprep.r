library(stringr)
library(ggplot2)
ral.sib = read.csv('../Raleigh/Raleigh_sibilants.csv')

ral.sib <- subset(ral.sib, phone_label %in% c('S', 'SH'))

ral.sib$Rness <- 'None'
ral.sib[str_detect(ral.sib$previous_phone,'R'),]$Rness <- "Rprevious"
ral.sib[str_detect(ral.sib$nucleus,'ER'),]$Rness <- "Rnucleus"
ral.sib[str_detect(ral.sib$onset,'R'),]$Rness <- "Ronset"

ggplot(ral.sib, aes(x=Rness, y = cog))+ geom_violin() + facet_wrap(~phone_label)
