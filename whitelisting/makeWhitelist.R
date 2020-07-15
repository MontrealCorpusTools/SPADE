## script for constructing "whitelist" of words, which are  
## - found in Subtlex US or UK
## - spell-check OK for UK or US spellings (helps remove names/places)
## - not *known* names (never POS tagged as 'name')
##
## This is a very conservative whitelist -- any word which *ever* could be a name
## or place or part of one (after lowercasing) is tagged. That includes 
## see, school, story..
##

library(tidyverse)
library(hunspell)

## vectorized version of spell checker with US dictionary
spellCheck <- Vectorize(hunspell_check)

uk <- read.delim("~/spade/whitelist/SUBTLEX-UK.txt", sep='\t')
us <- read.delim("~/spade/whitelist/SUBTLEX-US.txt", sep='\t')

uk.sub <- uk %>% filter(!is.na(FreqCount)) %>% # gets rid of two empty row
  filter(!str_detect(AllPoS, 'name')) %>% # remove entry tagged as name ever
  filter(Spell_check != 'X') %>%
  arrange(Spelling) %>% mutate(Spelling=as.character(Spelling))


us.sub <- us %>% filter(!str_detect(All_PoS_SUBTLEX, 'Name')) %>% ## remove entries tagged as name ever
  mutate(Word=as.character(Word)) %>% ## needed for spellchecking
  mutate(Spell_check = spellCheck(Word)) %>% # spellcheck according to US dictionary
  filter(Spell_check) %>%
  arrange(Word) # put in alphabetical order


uk.words <- uk.sub$Spelling
us.words <- us.sub$Word

whitelistWords <- data.frame(Word=union(us.words, uk.words))


write.csv(whitelistWords, file="whitelist_spade.csv")
