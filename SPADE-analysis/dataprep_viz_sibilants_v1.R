##
## first script doing rough visualization of s-retraction, for four datasets processed so far
##
## Morgan, late 10/2017
##
## you must have:
## '../SOTC/SOTC_sibilants.csv'
## '../buckeye/buckeye_sibilants.csv'
## same for raleigh and icecan
##
## (or change paths for your computer)
##


library(stringr)
library(ggplot2)
library(dplyr)


# 0. FUNCTIONS ------------------------------------------------------------


## function to make summary df with mean value of four vraibles (cog, frontslope, etc.)
## for each speaker/word pair

summaryDf <- function(x){

    ## dataframe summarizing measures for each word and speaker:
    summDf <- x %>% group_by(word, onset, speaker) %>% summarise(n=n(), cog=mean(cog), slope=mean(slope), spread=mean(spread), peak=mean(peak))

    ## long format:
    summDf <- gather(summDf, var, val, -word, -onset, -speaker, -n)
    return(summDf)
}


# 1. RALEIGH --------------------------------------------------------------

ral.sib = read.csv('../Raleigh/Raleigh_sibilants.csv')

## there are just 100 voiced sibilants in whole dataset (0.1% of total), so exclude them:
ral.sib <- subset(ral.sib, phone_label %in% c('S', 'SH'))

## we are interested in onset effects. let's exclude onset levels with  few observations (<100):
excludeLevels <- names(which(xtabs(~onset, ral.sib)<100))

cat("Excluding onsets:", paste(excludeLevels, sep=' '))
ral.sib <- droplevels(filter(ral.sib, !onset%in%excludeLevels))

## reorder onset so that /esh/ < /str/ < /sCr/ < others < /s/
ral.sib$onsetOrder <- 4
ral.sib[ral.sib$onset=='SH','onsetOrder'] <- 1
ral.sib[str_detect(ral.sib$onset,'R'),'onsetOrder'] <- 3
ral.sib[str_detect(ral.sib$onset,'S/T/R'),'onsetOrder'] <- 2
ral.sib[ral.sib$onset=='S','onsetOrder'] <- 5

ral.sib$onset <- with(ral.sib, reorder(onset, onsetOrder))



## subset of primary interest: /s/ versus /str/ versus /esh/ onsets
ral.sib.sub <- droplevels(filter(ral.sib, onset%in%c('S','SH','S/T/R')))

## reorder factors to expected order
ral.sib.sub$onset <- factor(ral.sib.sub$onset, levels=c('S','S/T/R', 'SH'))

ral.sib.sub.summ <- summaryDf(ral.sib.sub)
ral.sib.summ <- summaryDf(ral.sib)


## plot for just es/str/esh
ggplot(aes(x=onset, y=val), data=ral.sib.sub.summ) + geom_violin() + facet_wrap(~var, scales='free_y')
## looks basically OK, but why such low values for cog?
## comapre: Baker et al. Fig. 1

## examine by speaker, for cog:
## ggplot(aes(x=onset, y=val), data=filter(ral.sib.sub.summ, var=='cog')) + geom_violin() + facet_wrap(~speaker)


## plot for all onsets
ggplot(aes(x=onset, y=val), data=ral.sib.summ) + geom_violin() + facet_wrap(~var, scales='free')
## compare: Baker et al. Fig 2 for COG


# 2. BUCKEYE --------------------------------------------------------------

buck.sib = read.csv('../Buckeye/Buckeye_sibilants.csv')

## exclude z and zh onsets (though there are 750):
buck.sib <- subset(buck.sib, phone_label %in% c('s', 'sh'))

## we are interested in onset effects. let's exclude onset levels with  few observations (<100):
excludeLevels <- names(which(xtabs(~onset, buck.sib)<100))

cat("Excluding onsets:", paste(excludeLevels, sep=' '))
buck.sib <- droplevels(filter(buck.sib, !onset%in%excludeLevels))

## reorder onset so that /esh/ < /str/ < /sCr/ < others < /s/
buck.sib$onsetOrder <- 4
buck.sib[buck.sib$onset=='sh','onsetOrder'] <- 1
buck.sib[str_detect(buck.sib$onset,'r'),'onsetOrder'] <- 3
buck.sib[str_detect(buck.sib$onset,'s/t/r'),'onsetOrder'] <- 2
buck.sib[buck.sib$onset=='s','onsetOrder'] <- 5

buck.sib$onset <- with(buck.sib, reorder(onset, onsetOrder))



## subset of primary interest: /s/ versus /str/ versus /esh/ onsets
buck.sib.sub <- droplevels(filter(buck.sib, onset%in%c('s','sh','s/t/r')))

## reorder factors to expected order
buck.sib.sub$onset <- factor(buck.sib.sub$onset, levels=c('s','s/t/r', 'sh'))



buck.sib.sub.summ <- summaryDf(buck.sib.sub)
buck.sib.summ <- summaryDf(buck.sib)


## plot for just es/str/esh
ggplot(aes(x=onset, y=val), data=buck.sib.sub.summ) + geom_violin() + facet_wrap(~var, scales='free_y')


# 3. SOTC -----------------------------------------------------------------


sotc.sib = read.csv('../SOTC/SOTC_sibilants.csv')

## exclude z onsets (no ZH apparently?)
sotc.sib <- subset(sotc.sib, phone_label %in% c('s', 'S'))

## we are interested in onset effects. let's exclude onset levels with  few observations (<100):
excludeLevels <- names(which(xtabs(~onset, sotc.sib)<100))

cat("Excluding onsets:", paste(excludeLevels, sep=' '))
sotc.sib <- droplevels(filter(sotc.sib, !onset%in%excludeLevels))

## reorder onset so that /esh/ < /str/ < /sCr/ < others < /s/
sotc.sib$onsetOrder <- 4
sotc.sib[sotc.sib$onset=='S','onsetOrder'] <- 1
sotc.sib[str_detect(sotc.sib$onset,'r'),'onsetOrder'] <- 3
sotc.sib[str_detect(sotc.sib$onset,'s/t/r'),'onsetOrder'] <- 2
sotc.sib[sotc.sib$onset=='s','onsetOrder'] <- 5

sotc.sib$onset <- with(sotc.sib, reorder(onset, onsetOrder))



## subset of primary interest: /s/ versus /str/ versus /esh/ onsets
sotc.sib.sub <- droplevels(filter(sotc.sib, onset%in%c('s','S','s/t/r')))

## reorder factors to expected order
sotc.sib.sub$onset <- factor(sotc.sib.sub$onset, levels=c('s','s/t/r', 'S'))



sotc.sib.sub.summ <- summaryDf(sotc.sib.sub)
sotc.sib.summ <- summaryDf(sotc.sib)

icecan.sib = read.csv('../ICECAN/ICECAN_sibilants.csv')


## exclude z and zh onsets
icecan.sib <- subset(icecan.sib, phone_label %in% c('S', 'SH'))

## we are interested in onset effects. let's exclude onset levels with  few observations (<50 in this corpus):
excludeLevels <- names(which(xtabs(~onset, icecan.sib)<50))

cat("Excluding onsets:", paste(excludeLevels, sep=' '))
icecan.sib <- droplevels(filter(icecan.sib, !onset%in%excludeLevels))

## reorder onset so that /esh/ < /str/ < /sCr/ < others < /s/
icecan.sib$onsetOrder <- 4
icecan.sib[icecan.sib$onset=='SH','onsetOrder'] <- 1
icecan.sib[str_detect(icecan.sib$onset,'R'),'onsetOrder'] <- 3
icecan.sib[str_detect(icecan.sib$onset,'S/T/R'),'onsetOrder'] <- 2
icecan.sib[icecan.sib$onset=='S','onsetOrder'] <- 5

icecan.sib$onset <- with(icecan.sib, reorder(onset, onsetOrder))



## subset of primary interest: /s/ versus /str/ versus /esh/ onsets
icecan.sib.sub <- droplevels(filter(icecan.sib, onset%in%c('S','SH','S/T/R')))

## reorder factors to expected order
icecan.sib.sub$onset <- factor(icecan.sib.sub$onset, levels=c('S','S/T/R', 'SH'))



icecan.sib.sub.summ <- summaryDf(icecan.sib.sub)
icecan.sib.summ <- summaryDf(icecan.sib)


#
# ## 'Rness': where is there an adjacent R?
# ## phone preceding sibialnt = R
# ## syllable nucleus = r-colored vowel
# ## syllable onset contains R
# ral.sib$Rness <- 'None'
# ral.sib[str_detect(ral.sib$previous_phone,'R'),]$Rness <- "Rprevious"
# ral.sib[str_detect(ral.sib$nucleus,'ER'),]$Rness <- "Rnucleus"
# ral.sib[str_detect(ral.sib$onset,'R'),]$Rness <- "Ronset"
#
# ggplot(ral.sib, aes(x=Rness, y = cog))+ geom_violin() + facet_wrap(~phone_label)

all.sib.sub.summ <- rbind(data.frame(buck.sib.sub.summ, dataset='buckeye'),
                          data.frame(ral.sib.sub.summ, dataset='raleigh'),
                          data.frame(sotc.sib.sub.summ, dataset='sotc'),
                          data.frame(icecan.sib.sub.summ, dataset='icecan')
)


## standardize onset names
## change S in SOTC to sh
temp <- as.character(all.sib.sub.summ$onset)
temp[which(with(all.sib.sub.summ, onset=='S' & dataset=='sotc'))] <- 'sh'
all.sib.sub.summ$onset <- factor(temp)
## lowercase
all.sib.sub.summ$onset <- factor(tolower(as.character(all.sib.sub.summ$onset)), levels=c('s','s/t/r','sh'))

## plot for just es/str/esh, across datasets and variables
dialectVarPlot <- ggplot(aes(x=dataset, y=val), data=all.sib.sub.summ) + geom_violin(aes(fill=onset)) + facet_wrap(~var, scales='free') + ylab("Value (Hz)")
## check it out
dialectVarPlot

ggsave(dialectVarPlot, file="dialectVarPlot.pdf", width=6,height=4)


