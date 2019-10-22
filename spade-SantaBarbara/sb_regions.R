## Organise speaker data
sb_speakers <- read.csv('../data/sb_erik.csv')
sb <- merge(sb, sb_speakers, by.x = 'speaker_name', by.y = 'speaker')

# make new speaker divisions based on JSS CSV
sb_WestNCS <- read.csv('../data/alldata.csv')
sb_uniqueSpeakers <- sb_WestNCS %>%
	select(speaker, corpus) %>%
	filter(corpus %in% c("SB_West", "NCS")) %>%
	ddply(.(corpus, speaker), nrow) %>%
	select(corpus, speaker) %>%
	mutate(corpus = fct_recode(corpus, "West" = "SB_West", "Northern Cities" = "NCS"))
sb_uniqueSpeakers <- sb_uniqueSpeakers %>% mutate(speaker = sprintf("%04d", speaker)) # convert speaker names to 4 digits
sb_NCS <- filter(sb_uniqueSpeakers, corpus == "Northern Cities")
sb_West <- filter(sb_uniqueSpeakers, corpus == "West")

sb$region[sb$speaker_name %in% sb_West$speaker] <- "West"
sb$region[sb$speaker_name %in% sb_NCS$speaker] <- "NCS"