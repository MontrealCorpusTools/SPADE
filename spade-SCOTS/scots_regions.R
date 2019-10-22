#Subdialects first
scots$dialect <- NA

#Insular
scots[scots$birthplace=="Harray"|
      scots$birthplace=="Kirkwall"|
      scots$birthplace=="Lerwick" |
      scots$birthplace=="North Yell"|
      scots$birthplace=="Sanday",]$dialect = "Insular"

#Northern
scots[scots$birthplace=="Montrose"|
      scots$birthplace=="Stonehaven"| 
      scots$birthplace=="Auchenblae"|
      scots$birthplace=="Forfar"|
      scots$birthplace=="St Cyrus",]$dialect = "East Angus"

scots[scots$birthplace=="Aberdeen" |
      scots$birthplace=="Buckie"|
      scots$birthplace=="Elgin"|
      scots$birthplace=="Footdee"|
      scots$birthplace=="Fyvie"|
      scots$birthplace=="Insch"|
      scots$birthplace=="Inverurie"|
      scots$birthplace=="Torry",]$dialect = "North East"

scots[scots$birthplace=="Wick",]$dialect = "Caithness"

#Central
scots[scots$birthplace=="Ayr"|
    scots$birthplace=="Newton Stewart"|
    scots$birthplace=="Stranraer"|
    scots$birthplace=="New Cumnock"|
    scots$birthplace=="Auchinleck",]$dialect = "South Central"

scots[scots$birthplace=="Dunbar"|
      scots$birthplace=="Edinburgh"|
      scots$birthplace=="Leith"|
      scots$birthplace=="Loanhead"|
      scots$birthplace=="Musselburgh",]$dialect = "East Central South"

scots[scots$birthplace=="Alva"|
      scots$birthplace=="Alyth"|
      scots$birthplace=="Cardenden"|
      scots$birthplace=="Dundee"|
      scots$birthplace=="Perth"|
      scots$birthplace=="Scone"|
      scots$birthplace=="Stirling",]$dialect = "East Central North"

scots[scots$birthplace=="Cambuslang"|
      scots$birthplace=="Clydebank"|
      scots$birthplace=="Dalry"|
      scots$birthplace=="Glasgow"|
      scots$birthplace=="Gourock"|
      scots$birthplace=="Govan"|
      scots$birthplace=="Hamilton"|
      scots$birthplace=="Irvine"|
      scots$birthplace=="Paisley",]$dialect = "West Central"

#Southern
scots[scots$birthplace=="Galashiels",]$dialect = "Southern"

#Other
scots[scots$birthplace=="Bornish"|
      scots$birthplace=="North Uist"|
      scots$birthplace=="South Uist"|
      scots$birthplace=="Staffin"|
      scots$birthplace=="Uig",]$dialect = "Hebrides"

scots[scots$birthplace=="Inverness",]$dialect = "Inverness"

scots <- scots %>%
	filter(!(birthplace %in% c(
		"", "Hamburg", "Reading", "Hull", "Keighley", "Malta", "Norton", "Norwalk"
		)))

scots_corpora <- get_minimum_corpora(scots, quo(dialect))
scots <- scots %>%
	filter(dialect %in% scots_corpora$dialect)