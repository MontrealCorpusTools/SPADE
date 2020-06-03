
library(plyr)
source('formant_functions.r')

# LOAD THE VOWEL MEASUREMENTS
all_formant_data <- list()

all_formant_data[['PEBL']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-PEBL_formants.csv')
#all_formant_data[['dapp-Scotland']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-dapp-Scotland_formants.csv')
#all_formant_data[['dapp-Ireland']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-dapp-Ireland_formants.csv')
#all_formant_data[['dapp-EnglandLDS']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-dapp-EnglandLDS_formants.csv')
#all_formant_data[['dapp-EnglandRP']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-dapp-EnglandRP_formants.csv')
#all_formant_data[['Irish']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-Irish_formants.csv')
#all_formant_data[['HacHav']] <- read.csv('/projects/spade/datasets/datasets_static_formants/spade-HacHav_formants.csv')


measurement_point <- 0.33

for (corpus_name in names(all_formant_data)){
	print (corpus_name)
	formant_data <- all_formant_data[[corpus_name]]

	# NAME THE OUTPUT FILES
	prototypes_filename <- paste0('spade-',corpus_name,'/spade-',corpus_name,'_prototypes.csv')
	plot_filename <- paste0('spade-',corpus_name,'/corpus_means_for_prototypes_',corpus_name,'.pdf')

	# ADD AND RENAME DATA COLUMNS AS NEEDED
	formant_data$measurement <- measurement_point
	names(formant_data) <- gsub('phone_label', 'phone', names(formant_data))
	names(formant_data) <- gsub('phone_', '', names(formant_data))
	formant_data$A1A2diff <- with(formant_data, A1-A2) 
	formant_data$A2A3diff <- with(formant_data, A2-A3) 

	# THE PARAMETERS FOR THE PROTOTYPES
	proto_parameters <- c('F1','F2','F3','B1','B2','B3','A1A2diff','A2A3diff')

	# REMOVE ROWS WITH NA FOR COLUMNS WE NEED FOR PROTOTYPES AND OMIT PHONES WITH FEWER THAN 6 REMAINING TOKENS
	formant_data <- formant_data[complete.cases(formant_data[,proto_parameters]),]
	lofreq_phones <- names(table(formant_data$phone))[table(formant_data$phone)<6]
	if (length(lofreq_phones)){
		formant_data <- subset(formant_data, !phone%in%lofreq_phones)
		print (paste('omitting low-frequency phone', lofreq_phones))
	}

	# CALCULATE THE MEANS AND COVARIANCE MATRICES
	corpus_means_for_phones <- ddply(formant_data[,c('phone', proto_parameters)], .(phone), numcolwise(mean, na.rm=T))
	names(corpus_means_for_phones)[names(corpus_means_for_phones)%in%proto_parameters] <- paste(names(corpus_means_for_phones)[names(corpus_means_for_phones)%in%proto_parameters], measurement_point, sep='_')
	corpus_covmats_list <- findCovarianceMatrices(formant_data, parameters=proto_parameters, measurements=c(measurement_point), 
	                                   write.to.file=FALSE, filename=NULL, data.frame(vowel_means=corpus_means_for_phones, measurement=measurement_point), 
	                                   normalized=FALSE, pass_id='mixed', target_phones=unique(formant_data$phone))

	# FORMAT THE COVARIANCE MATRICES FOR THE OUTPUT AND COMBINE THEM WITH THE MEANS
	corpus_covmats <- c()
	for(p in names(corpus_covmats_list)){
	  	phone_matrix <- corpus_covmats_list[[p]]
	  	corpus_covmats <- rbind(corpus_covmats, data.frame(phone=p, phone_matrix))
	}
	phones_for_polyglot <- rbind(data.frame(type='means', corpus_means_for_phones), data.frame(type='matrix',corpus_covmats))

	# MAKE THE PROTOTYPE FILE
	write.table(phones_for_polyglot, file=prototypes_filename, row.names=F, sep=',', quote=FALSE)

	# PLOT THE MEANS
	cairo_pdf(plot_filename, h=6, w=6, onefile=T)
	for (i in 1:(length(proto_parameters)-1)){
		param1 <- paste(proto_parameters[i+1],'0.33',sep='_')
		param2 <- paste(proto_parameters[i],'0.33',sep='_')
		plot(corpus_means_for_phones[,param1], corpus_means_for_phones[,param2], main=paste(corpus_name, param1, 'vs.', param2), type='n', xlab=param1, ylab=param2,
		    xlim=rev(range(corpus_means_for_phones[,param1])), ylim=rev(range(corpus_means_for_phones[,param2])))
		text(corpus_means_for_phones[,param1], corpus_means_for_phones[,param2], labels=corpus_means_for_phones$phone)
	}
	dev.off()
}

