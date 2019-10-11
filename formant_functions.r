###########################################################################
# formant_functions.r                         revised Jun 29, 2015
# Jeff Mielke
# functions for working with formant measurements
###########################################################################

require(car)
require(gplots)
require(plyr)
require(dtt)

# CLASSES OF SOUNDS #######################################################
word_boundary           <- '#'

low_vowels              <- c('a','ɑ̃')
plain_mid_vowels        <- c('ə','œ','œ̃','ø','ɛ','e','ɔ','o','ɛ̃','ɔ̃')
diphthongal_mid_vowels  <- c('ɛʁ')
mid_vowels              <- c(plain_mid_vowels, diphthongal_mid_vowels)
tense_high_vowels       <- c('i','y','u')
lax_high_vowels         <- c('iC','yC','uC')
high_vowels             <- c(tense_high_vowels, lax_high_vowels)
vowels                  <- c(high_vowels, mid_vowels, low_vowels)
oral_vowels             <- c('i','iC','y','yC','e','ø','ɛ','ɛʁ','œ','ə','a','ɔ','o','uC','u')
nasal_vowels            <- c('ɛ̃','œ̃','ɑ̃','ɔ̃')
french_vowels_sorted    <- c('i','iC','y','yC','e','ø','ɛ','ɛ̃','ɛʁ','œ','œ̃','ə','a', 'ɑ̃','ɔ̃','ɔ','o','uC','u') #, 'ɑ'
french_approximants     <- c('i','iC','j','y','yC','ɥ','e','ø','ɛ','ɛ̃','ɛʁ','œ','œ̃','ə','a', 'ɑ', 'ɑ̃','ɔ̃','ɔ','o','uC','u','w')
nasals                  <- c('n','m')
approximants            <- c('l','j','w')
stops                   <- c('d','t','k','p','b','g')
voiceless_fricatives    <- c('s','f','ʃ')
voiced_fricatives_not_r <- c('ʒ','v','z')
voiced_fricatives       <- c(voiced_fricatives_not_r,'ʁ')
laxing_triggers         <- c(nasals, approximants, stops, voiceless_fricatives)
consonants              <- c(laxing_triggers, voiced_fricatives)
consonants_not_s_or_r   <- setdiff(consonants, c('s', 'ʁ'))
consonants_not_approx   <- setdiff(consonants, c(approximants, 'ʁ'))

p2fa_vowels <- c('IY1', 'IY2', 'IY0', 'IH1', 'IH2', 'IH0', 'IR1', 'IR2', 'IR0',
                 'EY1', 'EY2', 'EY0', 'EYR1', 'EYR2', 'EYR0',
                 'EH1', 'EH2', 'EH0', 'AH1', 'AH2', 'AH0', 
                 'AE1', 'AE2', 'AE0', 'AY1', 'AY2', 'AY0', 'AW1', 'AW2', 'AW0', 'AA1', 'AA2', 'AA0', 'AAR1', 'AAR2', 'AAR0',
                 'AO1', 'AO2', 'AO0', 'OW1', 'OW2', 'OW0', 'OY1', 'OY2', 'OY0', 'OR1', 'OR2', 'OR0', 'ER1', 'ER2', 'ER0',
                 'UH1', 'UH2', 'UH0', 'UW1', 'UW2', 'UW0', 'UR1', 'UR2', 'UR0')

p2fa_stressed_vowels <- c('IY1', 'IH1', 'EY1', 'EH1', 'AH1', 'AE1', 'AA1', 'AO1', 'OW1', 'ER1', 'UH1', 'UW1')


p2fa_stressed_vowels_plus <- c('IY1', 'IH1', 'EY1', 'EH1', 'AH1', 'AE1', 'AY1', 'AW1', 'AA1', 'AO1', 'OW1', 'OY1', 'ER1', 'UH1', 'UW1', 
                               'L', 'R', 'W', 'Y')


#p2fa_stressed_vowels_and_liquids <- c(p2fa_stressed_vowels, 'L', 'R')
p2fa_stressed_vowels_and_liquids <- c('IY1', 'IYN1', 'IYL1', 'IYR1', 'IH1', 'IHN1', 'IHL1', 'IHR1', 
                                      'EY1', 'EYN1', 'EYL1', 'EYR1', 'EH1', 'EHN1', 'EHL1', 'EHR1', 
                                      'AH1', 'AHN1', 'AHL1', 'AHR1', 'AE1', 'AEN1', 'AEL1', 'AER1', 
                                      'AA1', 'AAN1', 'AAL1', 'AAR1', 'AY1', 'AYN1', 'AYL1', 'AYR1', 
                                      'AW1', 'AWN1', 'AWL1', 'AWR1', 'AO1', 'AON1', 'AOL1', 'AOR1', 
                                      'OW1', 'OWN1', 'OWL1', 'OWR1', 'ER1', 'UH1', 'UHN1', 'UHL1', 'UHR1', 
                                      'UW1', 'UWN1', 'UWL1', 'UWR1', 'L', 'R')

buckeye_basic_vowels  <- c('iy', 'ih', 'ey', 'eh', 'ah', 'ae', 'aa', 'ao', 'ow', 'el', 'er', 'uh', 'uw')
buckeye_oral_vowels  <- c('iy', 'ih', 'ey', 'eh', 'ah', 'ae', 'ay', 'aw', 'aa', 'ao', 'ow', 'oy', 'el', 'er', 'uh', 'uw')
buckeye_nasal_vowels <- c('iyn','ihn','eyn','ehn','ahn','aen','ayn','awn','aan','aon','own','oyn','eln','ern','uhn','uwn')
buckeye_vowels  <- c(buckeye_oral_vowels)
all_vowels <- c(p2fa_vowels, oral_vowels, nasal_vowels, buckeye_vowels, buckeye_nasal_vowels)
p2fa_coronals <- c('S', 'SH', 'N', 'T', 'Z', 'D', 'TH', 'DH', 'CH', 'JH', 'ZH')
p2fa_consonants <- c('K', 'S', 'M', 'SH', 'N', 'P', 'T', 'Z', 'D', 'B', 'V', 'NG', 'G', 'TH', 'F', 'DH', 'HH', 'CH', 'JH', 'ZH')
p2fa_approximants <- c('L', 'W', 'R', 'Y')

p2fa_vplus <- c('Y', 'IY1', 'IY2', 'IY0', 'IH1', 'IH2', 'IH0', 
                     'EY1', 'EY2', 'EY0', 'EH1', 'EH2', 'EH0', 
                     'AE1', 'AE2', 'AE0',
                     'AH1', 'AH2', 'AH0', 'ER1', 'ER2', 'ER0', 'R',
                     'AY1', 'AY2', 'AY0', 'AW1', 'AW2', 'AW0', 
                     'AA1', 'AA2', 'AA0', 'AO1', 'AO2', 'AO0', 
                     'OY1', 'OY2', 'OY0', 'OW1', 'OW2', 'OW0', 
                     'UH1', 'UH2', 'UH0', 'UW1', 'UW2', 'UW0', 'W', 'L') 

p2fa_vl <- c('Y',
             'IY1', 'IY2', 'IY0', 'IY1R', 'IY2R', 'IY0R', 'IY1L', 'IY2L', 'IY0L',
             'IH1', 'IH2', 'IH0', 'IH1R', 'IH2R', 'IH0R', 'IH1L', 'IH2L', 'IH0L',
             'EY1', 'EY2', 'EY0', 'EY1R', 'EY2R', 'EY0R', 'EY1L', 'EY2L', 'EY0L',
             'EH1', 'EH2', 'EH0', 'EH1R', 'EH2R', 'EH0R', 'EH1L', 'EH2L', 'EH0L',
             'AE1', 'AE2', 'AE0', 'AE1R', 'AE2R', 'AE0R', 'AE1L', 'AE2L', 'AE0L',
             'AH1', 'AH2', 'AH0', 'AH1R', 'AH2R', 'AH0R', 'AH1L', 'AH2L', 'AH0L',
             'ER1', 'ER2', 'ER0', 'R',                    'ER1L', 'ER2L', 'ER0L', 
             'AY1', 'AY2', 'AY0', 'AY1R', 'AY2R', 'AY0R', 'AY1L', 'AY2L', 'AY0L',
             'AA1', 'AA2', 'AA0', 'AA1R', 'AA2R', 'AA0R', 'AA1L', 'AA2L', 'AA0L',
             'AW1', 'AW2', 'AW0', 'AW1R', 'AW2R', 'AW0R', 'AW1L', 'AW2L', 'AW0L',
             'AO1', 'AO2', 'AO0', 'AO1R', 'AO2R', 'AO0R', 'AO1L', 'AO2L', 'AO0L',
             'OY1', 'OY2', 'OY0', 'OY1R', 'OY2R', 'OY0R', 'OY1L', 'OY2L', 'OY0L',
             'OW1', 'OW2', 'OW0', 'OW1R', 'OW2R', 'OW0R', 'OW1L', 'OW2L', 'OW0L',
             'UH1', 'UH2', 'UH0', 'UH1R', 'UH2R', 'UH0R', 'UH1L', 'UH2L', 'UH0L',
             'UW1', 'UW2', 'UW0', 'UW1R', 'UW2R', 'UW0R', 'UW1L', 'UW2L', 'UW0L', 
             'W', 'L') 

p2fa_rl <- subset(p2fa_vplus, grepl('[RL]', p2fa_vplus))


##############################################################
# FUNCTIONS FOR PREPARING THE DATA
#   findSubjectParameters
#   findAllSubjectParameters
#   normalizeFormants
#   sortVowelFactor
#   applyRule
#   loadSegmentData
#   loadFormantData
#   loadSegmentFormantData
#   trimParameter
##############################################################

findSubjectParameters <- function(m, formants=c('F1','F2','F3','F4','F5'), one.set=FALSE, default_meas=0.325, 
                                  params=c('frequency', 'log_bandwidth'), collapse.maxformant=FALSE, verbose=FALSE){
    # Calculate means and standard devations for the purpose of normalizing vowel formants
    #
    # Args:
    #                  m : a data frame containing unnormalized formant measurements
    #           formants : the formants to include in the normalization 
    #
    # Returns a data frame containing formant means and standard devations for normalizing subjects' vowel spaces
    #
    if (!'subject'%in%names(m)){
        m$subject <- 'subject'
    }
    if (!'measurement'%in%names(m)){
        m$measurement <- default_meas
    }
    if (collapse.maxformant){
        m$max_formant <- 0
    }
    fstart <- proc.time()
    input_name <- paste(formants[1], params[1], sep='_')
    Fmeans <- data.frame(subject = aggregate(m[,input_name] ~ m$subject * m$phone * m$measurement * m$max_formant, FUN=mean)[,1],  
                           phone = aggregate(m[,input_name] ~ m$subject * m$phone * m$measurement * m$max_formant, FUN=mean)[,2],  
                     measurement = aggregate(m[,input_name] ~ m$subject * m$phone * m$measurement * m$max_formant, FUN=mean)[,3],  
                     max_formant = aggregate(m[,input_name] ~ m$subject * m$phone * m$measurement * m$max_formant, FUN=mean)[,4])

    for (param in params){
        for (i in 1:length(formants)){
            input_names <- paste(formants, param, sep='_')
            Fmeans_i <- aggregate(m[,input_names[i]] ~ m$subject * m$phone * m$measurement * m$max_formant, FUN=mean)
            names(Fmeans_i) <- c('subject', 'phone', 'measurement', 'max_formant', paste(formants[i], param, sep='_'))
            Fmeans <- merge(Fmeans, Fmeans_i, by=c('subject', 'phone', 'measurement', 'max_formant'))
            }
        }
    Fnorm <- data.frame(subject = aggregate(Fmeans[,input_name] ~ Fmeans$subject*Fmeans$measurement*Fmeans$max_formant, FUN=mean)[,1],  
                    measurement = aggregate(Fmeans[,input_name] ~ Fmeans$subject*Fmeans$measurement*Fmeans$max_formant, FUN=mean)[,2],  
                    max_formant = aggregate(Fmeans[,input_name] ~ Fmeans$subject*Fmeans$measurement*Fmeans$max_formant, FUN=mean)[,3])

    output_names <- c()
    for (param in params){
        mean_names <- c(paste(formants, param, 'mean', sep='_'))
        sd_names <- c(paste(formants, param, 'sd', sep='_'))
        output_names <- c(output_names, mean_names, sd_names)
        input_names <- paste(formants, param, sep='_')
        for (i in 1:length(formants)){
            Fnorm[,mean_names[i]] = aggregate(Fmeans[,input_names[i]] ~ Fmeans$subject*Fmeans$measurement*Fmeans$max_formant, FUN=mean)[,4]
            }
        for (i in 1:length(formants)){
            Fnorm[, sd_names [i]] = aggregate(Fmeans[,input_names[i]] ~ Fmeans$subject*Fmeans$measurement*Fmeans$max_formant, FUN=sd)[,4]
            }
        }
    if (verbose){
        print(paste('calculating parameter matrices for', length(unique(m$subject)), 'subjects,', length(unique(m$max_formant)), 
                  'max formants, and', length(unique(m$measurement)), 'measurement points took', paste(round((proc.time()-fstart)[3],3)), 'seconds'))
    } 
    if (one.set){
        Fnorm[,output_names]
    }else{
        Fnorm
    }
}

findAllSubjectParameters <- function(m, speakers=unique(m$subject), formants=c('F1','F2','F3','F4','F5'), 
                                     params=c('frequency', 'log_bandwidth'), collapse.maxformant=FALSE){
    # Calculate means and standard devations for the purpose of normalizing vowel formants, for all speakers
    #
    # Args:
    #                   m : a data frame, including unnormalized formant measurements
    #            speakers : the speakers to include
    #            formants : the formants to include in the normalization 
    # collapse.maxformant : whether to combine measurments taken with different max formant values
    #
    # Returns the parameters for the speakers.
    parameters.by.speaker <- c()
    for (speaker in speakers){
        speaker.param <- findSubjectParameters(subset(m, subject==speaker), formants=formants, params=params,
                                               collapse.maxformant=collapse.maxformant)
        parameters.by.speaker <- rbind(parameters.by.speaker, speaker.param)
    }
    parameters.by.speaker
}

normalizeFormants <- function(m, pop_parameters, formant.param=NULL, formants=c('F1','F2','F3','F4','F5'), phones=levels(m$phone), best_maxformant=NULL, meas=7, collapse.maxformant=FALSE, params=c('frequency', 'log_bandwidth')){
    # Transform a subject's vowel measurements using Lobanov normalization and the population's parameters
    #
    # Args:
    #                  m : a data frame, including unnormalized formant measurements
    #     pop_parameters : formant means and standard deviations for the population
    #           formants : the formants to include in the normalization 
    #    best_maxformant : a max formant value to use for the measurments to be normalized
    #
    # Returns the same data frame with added columns for subject means, subject standard deviations, and normalized formant frequencies.
    #
    if (is.null(formant.param)){
        if (!'subject'%in%names(m)){
            m$subject <- 'subject'
            m$subject <- factor(m$subject)
        }
        if (is.null(best_maxformant)){
            formant.param <- findSubjectParameters(m, formants=formants, collapse.maxformant=collapse.maxformant, params=params)
        }else{
            formant.param <- findSubjectParameters(subset(m, max_formant==best_maxformant&phone%in%phones), params=params, formants=formants, 
                                                   collapse.maxformant=collapse.maxformant)
        }
    }
    if (!'measurement'%in%names(formant.param)){
        formant.param$measurement <- meas
    }
    for (param in params){
        #print(param)
        for (i in 1:length(formants)){
            formant <- formants[i]
            #print(formant)
            input_freq   <- m[,paste(formant, param, sep='_')]
            subject_mean <- formant.param[formant.param$measurement==meas,paste(formant, param, 'mean', sep='_')]
            subject_sd   <- formant.param[formant.param$measurement==meas,paste(formant, param, 'sd', sep='_')]
            pop_mean     <- pop_parameters[,paste(formant, param, 'mean', sep='_')]
            pop_sd       <- pop_parameters[,paste(formant, param, 'sd', sep='_')]
            #print (length(input_freq))
            #print (length(subject_mean))
            #print (subject_sd)
            #print (pop_sd)
            #print (pop_mean)
            m[,paste(formant, param, sep='n_')] <- ((input_freq - subject_mean) / subject_sd) * pop_sd + pop_mean
            }
        }
    m
    }

sortVowelFactor <- function(phone_factor, add_missing=TRUE, vowels_sorted=NULL, language='French'){
    # Sort the factor levels to put vowels in order.
    #
    # Args:
    #       phone_factor : a factor whose levels are vowels
    #        add_missing : add levels for vowels that aren't present
    #      vowels_sorted : a list of vowel labels in the desired order
    #
    # Returns phone_factor with its levels in the same order as vowels_sorted
    #
    if (is.null(vowels_sorted)){
        if (language=='French'){
            vowels_sorted <- c('i','iC','y','yC','e','ø','ɛ','ɛ̃','ɛʁ','œ','œ̃','ə','a','ɑ̃','ɔ̃','ɔ','o','uC','u')
            print ('using French vowel transcriptions')
        }else if (language=='English'){
            #if ('ih'%in%levels(phone_factor)){
            #    vowels_sorted <- buckeye_vowels
            #    print ('using Buckeye Corpus vowel transcriptions')
            #}else{
            #    vowels_sorted <- p2fa_vowels
            #    print ('using P2FA vowel transcriptions')
            #}
            if (is.null(vowels_sorted)){
                vowels_sorted <- p2fa_vowels
            }
        }
    }
    extra_levels <- setdiff(levels(phone_factor), vowels_sorted)
    missing_levels <- setdiff(vowels_sorted, levels(phone_factor))
    if (length(missing_levels)){
        if (add_missing){
            levels(phone_factor) <- c(levels(phone_factor), missing_levels)
            print(paste('added levels not in the data:', paste(missing_levels, collapse=' ')))
            }else{
            print(paste('expected levels are missing:', paste(missing_levels, collapse=' ')))
            }
        }
    for (p in rev(vowels_sorted)){
        if (p%in%levels(phone_factor)){
            phone_factor <- relevel(phone_factor, p)
            }
        }
    phone_factor
    }

applyRule <- function(data, rule_id, language='French'){
    # Apply a phonological rule to derive phones not distinguished in the TextGrid
    #
    # Args:
    #               data : a data frame containing phones and their contexts
    #            rule_id : a string indicating which rule to apply
    #           language : the language in the recording
    #
    # Returns the same data frame with updated phone labels
    #
    print (paste('applying', rule_id, 'for', language))

    if (language=='French'){
        if (rule_id=='laxing'){
            # HIGH VOWEL LAXING 
            laxing <- c()
            for (i in 1:(length(data$phone)-2)){
                if (data$phone[i]%in%high_vowels){
                    if (data$phone[i+1]%in%laxing_triggers & data$phone[i+2]==word_boundary){
                        laxing <- c(laxing, paste(data$phone[i], 'C', sep=''))
                    }else if (data$phone[i+1]%in%consonants_not_s_or_r & data$phone[i+2]%in%consonants_not_approx){
                        laxing <- c(laxing, paste(data$phone[i], 'C', sep=''))
                    }else{
                        laxing <- c(laxing, paste(data$phone[i]))
                    }
                }else{
                    laxing <- c(laxing, paste(data$phone[i]))
                }
            }
            laxing <- c(laxing, paste(data$phone[length(data$phone)-c(1,0)]))
            data$phone <- factor(laxing)
        }

        if (rule_id=='diphthongization'){
            # DIPHTHONGIZATION OF PRE-RHOTIC /ɛ/
            diphthongizing <- c()
            for (i in 1:(length(data$phone)-1)){
                if (data$phone[i]=='ɛ' & data$phone[i+1]=='ʁ'){
                    diphthongizing <- c(diphthongizing, paste('ɛʁ'))
                }else{
                    diphthongizing <- c(diphthongizing, paste(data$phone[i]))
                }
            }
            diphthongizing <- c(diphthongizing, paste(data$phone[length(data$phone)]))
            data$phone <- factor(diphthongizing)
        }
        
    }

    if (language=='English'){
        if (rule_id=='u_fronting'){
            # FRONTING OF PRE-CORONAL /t/
            fronting <- c(paste(data$phone[1]))
            for (i in 2:(length(data$phone))){
                if (substr(data$phone[i],1,2)=='UW'){
                    if (data$phone[i+1]%in%p2fa_coronals){
                        fronting <- c(fronting, paste('cor',data$phone[i], sep=''))
                    }else{
                        fronting <- c(fronting, paste(data$phone[i]))
                    }
                }else{
                    fronting <- c(fronting, paste(data$phone[i]))
                }
            }
        data$phone <- factor(fronting)
        }
        if (rule_id=='prerhotic_vowels'){
            # QUALITY OF PRE-RHOTIC VOWELS
            prerhotic_vowels <- c()
            for (i in 1:(length(data$phone)-1)){
                if (data$phone[i+1]%in%c('R','r')){
                    #IY,IH --> IR / __R
                    if (substr(data$phone[i],1,1)=='I'){
                        prerhotic_vowels <- c(prerhotic_vowels, paste('IR',substr(data$phone[i],3,3), sep=''))
                    }else if (substr(data$phone[i],1,1)=='i'){
                        prerhotic_vowels <- c(prerhotic_vowels, 'ir')
                    #UH,UW --> UR / __R
                    }else if (substr(data$phone[i],1,1)=='U'){
                        prerhotic_vowels <- c(prerhotic_vowels, paste('UR',substr(data$phone[i],3,3), sep=''))
                    }else if (substr(data$phone[i],1,1)=='u'){
                        prerhotic_vowels <- c(prerhotic_vowels, 'ur')
                    #EY --> EYR / __R
                    #}else if (substr(data$phone[i],1,2)=='EY'){
                    #    prerhotic_vowels <- c(prerhotic_vowels, paste('EYR',substr(data$phone[i],3,3), sep=''))
                    #AA --> AAR / __R
                    #}else if (substr(data$phone[i],1,2)=='AA'){
                    #    prerhotic_vowels <- c(prerhotic_vowels, paste('AAR',substr(data$phone[i],3,3), sep=''))
                    #AO,OW --> OR / __R
                    }else if (substr(data$phone[i],1,2)%in%c('AO','OW')){
                        prerhotic_vowels <- c(prerhotic_vowels, paste('OR',substr(data$phone[i],3,3), sep=''))
                    }else if (substr(data$phone[i],1,1)%in%c('ao','ow')){
                        prerhotic_vowels <- c(prerhotic_vowels, 'or')
                    }else if (data$phone[i]%in%buckeye_vowels){
                        prerhotic_vowels <- c(prerhotic_vowels, paste(substr(data$phone[i],1,2), 'r', sep=''))
                    }else{
                        prerhotic_vowels <- c(prerhotic_vowels, paste(substr(data$phone[i],1,2), 'R',substr(data$phone[i],3,3), sep=''))
                    }
                }else{
                    prerhotic_vowels <- c(prerhotic_vowels, paste(data$phone[i]))
                }
            }
        prerhotic_vowels <- c(prerhotic_vowels, paste(data$phone[length(data$phone)]))
        data$phone <- factor(prerhotic_vowels)
        }

        if (rule_id=='prelateral_vowels'){
            # QUALITY OF PRE-LATERAL VOWELS
            prelateral_vowels <- c()
            for (i in 1:(length(data$phone)-1)){
                #V --> VL / __L
                if (data$phone[i+1]=='L'){
                    prelateral_vowels <- c(prelateral_vowels, paste(substr(data$phone[i],1,2), 'L',substr(data$phone[i],3,3), sep=''))
                }else if (data$phone[i+1]=='l'){
                    prelateral_vowels <- c(prelateral_vowels, paste(substr(data$phone[i],1,2), 'l', sep=''))
                }else{
                    prelateral_vowels <- c(prelateral_vowels, paste(data$phone[i]))
                }
            }
        prelateral_vowels <- c(prelateral_vowels, paste(data$phone[length(data$phone)]))
        data$phone <- factor(prelateral_vowels)
        }

        if (rule_id=='prenasal_vowels'){
            # QUALITY OF PRE-NASAL VOWELS
            prenasal_vowels <- c()
            for (i in 1:(length(data$phone)-1)){
                #V --> VN / __N
                if (data$phone[i+1]%in%c('M','N','NG')){
                    prenasal_vowels <- c(prenasal_vowels, paste(substr(data$phone[i],1,2), 'N',substr(data$phone[i],3,3), sep=''))
                }else if (data$phone[i+1]=='l'){
                    prenasal_vowels <- c(prenasal_vowels, paste(substr(data$phone[i],1,2), 'n', sep=''))
                }else{
                    prenasal_vowels <- c(prenasal_vowels, paste(data$phone[i]))
                }
            }
        prenasal_vowels <- c(prenasal_vowels, paste(data$phone[length(data$phone)]))
        data$phone <- factor(prenasal_vowels)
        }
    }
    data
}

loadSegmentData <- function(filename, language='French', min_duration=0.05, exclude_nonvowels=TRUE, applyrules=TRUE, target_phones=NULL, merge_vl=FALSE){
    # Load the vowel segment information output by formants_first_pass.praat
    #
    # Args:
    #                  s : the data
    #           language : the language in the recording
    #       min_duration : the minimum duration for a segment
    # Returns a data frame containing the data from the file and some new columns
    #
    data <- read.table(filename, h=T, sep='\t', comment.char='', na.strings='--undefined--')

    if (language=='French'){
        #THIS IS NOT THE BEST PLACE TO DO THESE...
        #o_words <- c('aucun', 'auteur', 'chaud', 'chauffeur', 'château', 'dos', 'faux', 'lot', 'métaux', 'mot', 'taux')
        #if (!'o'%in%levels(data$phone)){
        #    levels(data$phone) <- c(levels(data$phone), 'o')
        #}
        #data[data$word%in%o_words&data$phone=='ɔ',]$phone <- 'o'
        #wrong_spelling <- c('delit','depanneur','la','pecheurs','spêcheurs','vipere')
        #right_spelling <- c('délit','dépanneur','là','pêcheurs','pêcheurs','vipère')
        #for (i in 1:length(wrong_spelling)){
        #    levels(data$word)[which(levels(data$word)==wrong_spelling[i])] <- right_spelling[i]
	    #}

        #APPLY PHONOLOGICAL RULES
        if (applyrules){
            data <- applyRule(data, 'laxing', language=language)
            data <- applyRule(data, 'diphthongization', language=language)
        }

        #SORT THE VOWELS AND ADD MISSING LEVELS
        data$phone <- sortVowelFactor(data$phone, add_missing=TRUE, target_phones, language)
    }else if (language=='English'){
        
        #APPLY PHONOLOGICAL RULES
        if (applyrules){
            data <- applyRule(data, 'prerhotic_vowels', language=language)
            data <- applyRule(data, 'prelateral_vowels', language=language)
            data <- applyRule(data, 'prenasal_vowels', language=language)
        }

        #SORT THE VOWELS AND ADD MISSING LEVELS
        data$phone <- sortVowelFactor(data$phone, add_missing=TRUE, target_phones, language)
    }

    measured.data <- subset(data, measured==1)
    if (sum(measured.data$duration<min_duration)>0){
        print(paste(round(100*sum(measured.data$duration<min_duration)/length(measured.data$duration), 2), '% of tokens will be excluded (under duration threshold).', sep=''))
    }

    data <- add.contexts(data)

    #MERGE VOWEL-LIQUID SEQUENCES, IF ASKED TO
    if (merge_vl){
        print ('merging vowel-liquid sequences')
        data <- mergeVL(data)
    }
    
    #EXCLUDE OVERLY SHORT TOKENS
    data$duration <- data$phoneend - data$phonestart
    data$exclude <- as.numeric(data$duration<min_duration)
    # print ('data$exclude...')
    # print (summary(data))

    #EXCLUDE TAGS IN THE WORDS TIER
    if (sum(substr(data$word,1,1)=='<')>0){
        data[substr(data$word,1,1)=='<',]$exclude <- 1
    }

    #EXCLUDE NON-VOWELS
    if (exclude_nonvowels){
        #print(setdiff(unique(data$phone),all_vowels))
        if (length(setdiff(unique(data$phone),all_vowels))){
            #print(summary(data[!data$phone%in%all_vowels,]))
            data[!data$phone%in%all_vowels,]$exclude <- 1
        }
    }

    data
}

loadFormantData <- function(filename, segment.data=c(), nasal_formant='no', language=NULL, formants=c('F1','F2','F3','F4','F5'), default_meas=NA,meas_override=TRUE){
    # Load the formant measurements output by formants_first_pass.praat
    #
    # Args:
    #                  s : the data
    #      nasal_formant : 'yes' to use nasal vowel measurements taking into account nasal F1, 
    #                      'no' to use normal measurements for nasal vowels, or 'exclude' to exclude nasal vowels
    #           language : the language in the recording
    #
    # Returns a data frame containing the data from the file and some new columns
    #

    data <- read.table(filename, h=T, sep='\t', comment.char='', na.strings='--undefined--')

    #print (summary(segment.data))
    if (meas_override | (nrow(data)==length(default_meas)*nrow(unique(data[,c('token_id','max_formant','nasal_formant')])))){
        data$measurement <- default_meas
    }else{
        data$measurement <- NA
    }    
    #EXCLUDE OVERLY SHORT TOKENS
    if (sum(data$token_id%in%subset(segment.data, exclude==1)$token_id) > 0){
        print(paste('excluding ', round(100*sum(data$token_id%in%subset(segment.data, exclude==1)$token_id)/length(data$token_id), 2), '% of tokens.', sep=''))
    }
    data <- data[data$token_id%in%subset(segment.data, exclude==0)$token_id,]

    #DEAL WITH NASALIZED VOWELS
    nasal_tokens <- intersect(unique(subset(data, nasal_formant==0)$token_id), unique(subset(data, nasal_formant==1)$token_id))
    if (nasal_formant=='no'){
        data <- subset(data, nasal_formant==0|!token_id%in%nasal_tokens)
    } else if (nasal_formant=='yes'){
        data <- subset(data, nasal_formant==1|!token_id%in%nasal_tokens)
    } else if (nasal_formant=='exclude'){
        data <- subset(data, !token_id%in%nasal_tokens)
    }

    #CALCULATE LOG BANDWITHS
    for (formant in formants){
        data[,paste(formant,'log_bandwidth',sep='_')] <- log(data[,paste(formant,'bandwidth',sep='_')], base=10)
        }
    data
    }

loadSegmentFormantData <- function(datafiles, s, language='English', contours=FALSE, default_meas=NA, exclude_nonvowels=TRUE, applyrules=TRUE, min_duration=0.05, target_phones=NULL, merge_vl=FALSE){
    segment.data <- c()
    formant.data <- c()
    for (datafile in subset(datafiles, speaker==s & exclude==0)$filepath){
        #LOAD THE SEGMENT AND FORMANT FILES PRODUCED BY THE PRAAT SCRIPT
        print (paste('loading',datafile))
        segment.part <- loadSegmentData(paste(datapath,datafile,'_segments.csv',sep=''), language=language, exclude_nonvowels=exclude_nonvowels, applyrules=applyrules, min_duration=min_duration, target_phones=target_phones, merge_vl=merge_vl)
        segment.part$textgrid <- datafile

        if (contours){
            formant.part <- loadFormantData(paste(datapath,datafile,'_formant_contours.csv',sep=''), 
                                            segment.data=segment.part, language=language, default_meas=default_meas)
            instruct.part <- read.table(paste(datapath,datafile,'_contour_instructions.csv',sep=''), h=T, sep='\t')
            segment.part <- merge(segment.part[,setdiff(names(segment.part),c('phonestart','phoneend','duration'))], 
                                  instruct.part[,c('token_id','mdist','phonestart','phoneend')], by='token_id')
            segment.part$duration <- with(segment.part, phoneend-phonestart)
        }else{
            segment.part <- subset(segment.part, measured==1)
            formant.part <- loadFormantData(paste(readpath,datafile,'_formant_nuclei.csv',sep=''), 
                                            segment.data=segment.part, language=language, default_meas=default_meas)
        }
        #THIS IS TO OMIT DUPLICATES CAUSED BY OVERLAPPING TEXTGRIDS (FIRST APPEARANCE IN LIST SHOULD BE DEFINITIVE VERSION).
        unique_ids <- length(unique(formant.part$token_id))
        segment.part <- subset(segment.part, !token_id%in%unique(segment.data$token_id))
        formant.part <- subset(formant.part, !token_id%in%unique(formant.data$token_id))
        if (unique_ids > length(unique(formant.part$token_id))){
            print (paste('excluding', unique_ids-length(unique(formant.part$token_id)), 'tokens whose IDs were already present.'))
        }
        segment.data <- rbind(segment.data, segment.part)
        formant.data <- rbind(formant.data, formant.part)

        #print ('SEGMENT ROWS')
        #print (nrow(segment.data))
    }

    list(segments=segment.data, formants=formant.data)
}

trimParameter <- function(m, params, bywhat='subject', sds=2, tails=c(-1,1)){
    # Trim values that are more than some number of standard deviations from the mean
    #
    # Args:
    #                  m : the data
    #             params : the parameters to use for trimming
    #             bywhat : the grouping variable to use to find standard deviations
    #                sds : the number of standard deviations to use as the cutoff
    #               tail : which side(s) to trim (c(1), c(-1), or c(-1,1))
    #
    # Returns the same data table without the extreme values
    #
    for (param in params){
        for (tail in tails){
            if (length(bywhat)==1){
                cutoffs <- data.frame(bywhat=aggregate(m[,param]~m[,bywhat[1]], FUN=mean)[,1],
                                      cutoff=aggregate(m[,param]~m[,bywhat[1]], FUN=mean)[,2]
                                       + tail*sds*aggregate(m[,param]~m[,bywhat[1]], FUN=sd)[,2])
                }else{
                cutoffs <- data.frame(bywhat1=aggregate(m[,param]~m[,bywhat[1]]*m[,bywhat[2]], FUN=mean)[,1],
                                      bywhat2=aggregate(m[,param]~m[,bywhat[1]]*m[,bywhat[2]], FUN=mean)[,2],
                                      cutoff=aggregate(m[,param]~m[,bywhat[1]]*m[,bywhat[2]], FUN=mean)[,3]
                                       + tail*sds*aggregate(m[,param]~m[,bywhat[1]]*m[,bywhat[2]], FUN=sd)[,3])
                }
            names(cutoffs)[1:length(bywhat)] <- bywhat
            mc <- merge(m, cutoffs, by=intersect(names(m), names(cutoffs)))
            if (tail > 0){
                mc <- mc[mc[,param]<mc$cutoff,]
                }else{
                mc <- mc[mc[,param]>mc$cutoff,]
                }
            m <- mc[,1:length(names(mc))-1]
            }
        }
    m
    }

##############################################################
#  PLOTTING FUNCTIONS
#   plot.vowels
#   plotVowelBands
##############################################################

plot.vowels <- function(m, param1, param2, group.by='phone', meas=NULL, mf=NULL, limits='global', size_param=FALSE, inches=FALSE, manual.xlim=FALSE, manual.ylim=FALSE, xlab=NULL, ylab=NULL, do.ellipses=TRUE, fill=FALSE, do.text=TRUE, noplot=FALSE, subject=NULL, main='', draw.zero=TRUE, replace.underscores=TRUE, rename.axes=TRUE, levels.to.highlight=NULL, label.big.circles=NULL, pch=19, col.override=NULL, overplot=FALSE, rainbow_multiplier=1.2, plot_points=TRUE){
    # Plot vowel tokens on a single plot
    #
    # Args:
    #                  m : the data
    #               meas : the measurement point
    #             param1 : the parameter to plot on the x-axis
    #             param2 : the parameter to plot on the y-axis 
    #             limits : if 'global', use the  same axis limits for all speakers
    #         size_param : the parameter that will determine the size of the plot symbols. If FALSE, plot with points instead
    #             inches : controls the size of the symbols
    #        manual.xlim : manual x-axis limits
    #        manual.ylim : manual y-axis limits
    #        do.ellipses : whether to include vowel category ellipses in the plot
    #             noplot : don't plot
    #
    # Returns nothing
    #
    #
    # plot.vowels <- function(data, 'LD1', 'LD2', group.by='phone')
    #
    if (is.null(meas)&is.null(mf)){
        afsub <- m
        xlim <- rev(range(afsub[,param1])) 
        ylim <- rev(range(afsub[,param2]))
    }else{
        if (!'measurement'%in%names(m)){
            m$measurement <- meas[1]
        }
        if (meas=='all'){
            meas <- unique(m$measurement)
        }
        if (mf[1]=='all'){
            afsub <- subset(m, measurement%in%meas)
        }else{
            if (mf[1]=='best'){
                afsub <- subset(m, measurement%in%meas&max_formant==best_max)
            }else{
                afsub <- subset(m, measurement%in%meas&max_formant%in%mf)
            }
        }
        afsub <- subset(afsub, !is.na(afsub[,param1]))
        afsub <- subset(afsub, !is.na(afsub[,param2]))
        if (limits=='global'){
            xlim <- rev(range(na.omit(subset(m, measurement%in%meas)[,param1]))) 
            ylim <- rev(range(na.omit(subset(m, measurement%in%meas)[,param2])))
        }else{
            xlim <- rev(range(afsub[,param1])) 
            ylim <- rev(range(afsub[,param2]))
        }
        if (main==''){
            if (length(meas)>1){
                main <- subject
            }else{
                if (length(mf)==1){
                    main <- paste(subject, ', ', mf, ' Hz, ', meas, sep='')
                }else{
                    main <- paste(meas, sep='')
                }
            }
        }
    }
    if (manual.xlim[1]!=FALSE){
        xlim <- manual.xlim
    }
    if (manual.ylim[1]!=FALSE){
        ylim <- manual.ylim
    }
    if (is.null(subject) & !is.null(afsub$subject)){
        subject <- afsub$subject[1]
    }
    if(is.null(xlab)){
        xlab <- param1
        if (rename.axes){
            xlab <- gsub('F1n_', 'normalized F1 ', xlab)
            xlab <- gsub('F2n_', 'normalized F2 ', xlab)
            xlab <- gsub('F3n_', 'normalized F3 ', xlab)
            xlab <- gsub('F4n_', 'normalized F4 ', xlab)
            xlab <- gsub('F5n_', 'normalized F5 ', xlab)
            xlab <- gsub('frequency', 'frequency (Hz)', xlab)
        }
        if (replace.underscores){
            xlab <- gsub('_', ' ', xlab)
        }
    }
    if(is.null(ylab)){
        ylab <- param2
        if (rename.axes){
            ylab <- gsub('F1n_', 'normalized F1 ', ylab)
            ylab <- gsub('F2n_', 'normalized F2 ', ylab)
            ylab <- gsub('F3n_', 'normalized F3 ', ylab)
            ylab <- gsub('F4n_', 'normalized F4 ', ylab)
            ylab <- gsub('F5n_', 'normalized F5 ', ylab)
            ylab <- gsub('frequency', 'frequency (Hz)', ylab)
        }
        if (replace.underscores){
            ylab <- gsub('_', ' ', ylab)
        }
    }

    if (noplot){
        plot(0, 0, type='n', xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab, main=main)
    }else{
        if (size_param==FALSE){
            if (!overplot){
                plot(0, 0, xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab, type='n', main=main)
            }
            if (draw.zero){
                abline(h=0, col='gray')
                abline(v=0, col='gray')
            }
            if (is.null(levels.to.highlight)){
                if (is.null(col.override)){
                    colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), s=1, v=1)
                }else{
                    colors <- col.override
                }
                if (plot_points){
                    points(afsub[,param1], afsub[,param2], pch=pch, cex=0.6, col=colors[c(afsub[,group.by])])
                }
            }else{
                afsubsub <- afsub[afsub[,group.by]%in%levels.to.highlight,]
                afnotsub <- afsub[!afsub[,group.by]%in%levels.to.highlight,]
                if (is.null(col.override)){
                    colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), s=0.1, v=0.9)
                }else{
                    colors <- col.override
                }
                if (plot_points){
                    points(afnotsub[,param1], afnotsub[,param2], pch=pch, cex=0.6, col=colors[c(afnotsub[,group.by])])
                }
                if (is.null(col.override)){
                    colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), s=1, v=1)
                }else{
                    colors <- col.override
                }
                if (plot_points){
                    points(afsubsub[,param1], afsubsub[,param2], pch=pch, cex=0.6, col=colors[c(afsubsub[,group.by])])
                }
            }
        }else{
            symbols(afsub[,param1], afsub[,param2], circles=afsub[,size_param], inches=inches,
                xlim=xlim, ylim=ylim, 
                xlab=xlab, ylab=ylab, 
                bg=rainbow(rainbow_multiplier*length(levels(afsub[,group.by])))[c(afsub[,group.by])],
                main=main)
            if (!is.null(label.big.circles)){
                big.circles <- subset(afsub, afsub[,size_param]>label.big.circles)
                text(big.circles[,param1], big.circles[,param2], labels=round(big.circles[,size_param],0), cex=0.5)
            }
        }
    }
    if (is.null(levels.to.highlight)){
        colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), v=1, alpha=0.5)
    }else{
        colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), v=0.85, alpha=c(0,1)[1+as.numeric(levels(afsub[,group.by])%in%levels.to.highlight)])
    }
    for (i in 1:length(levels(afsub[,group.by]))){
        p <- levels(afsub[,group.by])[i]
        if (length(subset(afsub, afsub[,group.by]==p)[,1])>2 & do.ellipses){
            dataEllipse(c(subset(afsub, afsub[,group.by]==p)[,param1]), c(subset(afsub, afsub[,group.by]==p)[,param2]), 
            center.pch=F, plot.points=F, levels=.682, add=TRUE, segments=51, robust=FALSE, 
            col=colors[i], fill=fill)
        #}else{
        #    print(paste('no ellipse for',p))
        }
    }   
    if (do.text){
        if (is.null(levels.to.highlight)){
            colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), s=0.9, v=0)
        }else{
            colors <- rainbow(rainbow_multiplier*length(levels(afsub[,group.by])), 
                                 v=c(.6,0)[1+as.numeric(levels(afsub[,group.by])%in%levels.to.highlight)], 
                                 alpha=c(1,1)[1+as.numeric(levels(afsub[,group.by])%in%levels.to.highlight)],
                                 s=c(.4,1)[1+as.numeric(levels(afsub[,group.by])%in%levels.to.highlight)])
        }
        text(aggregate(afsub[,param1] ~ afsub[,group.by], FUN=mean)[,2],
             aggregate(afsub[,param2] ~ afsub[,group.by], FUN=mean)[,2],
             aggregate(afsub[,param1] ~ afsub[,group.by], FUN=mean)[,1], cex=1, col=colors)
    }
}

plotVowelBands <- function(data, plot.lines='n_frequency', plot.bands='_bandwidth', formants=c('F1','F2','F3','F4','F5'), 
                           main='', xlab='', ylab='', alpha=0.3, v=1, smoothing=1000, kHz=TRUE){
    # Plot vowel frequencies and bandwidths over time
    #
    # Args:
    #               data : the data
    #         plot.lines : a string to append to formant names in order to derive the column name for what to plot using lines
    #         plot.bands : a string to append to formant names in order to derive the column name for what to plot using bands
    #           formants : the formants to include in the plot
    #               main : the main title
    #               xlab : the x-axis label
    #               ylab : the y-axis label
    #              alpha : the alpha value for the band fill color
    #                  v : the value for the line color and band fill color
    #          smoothing : if FALSE, plot the actual values, if a number, smooth by interpolating to that many values
    #                kHz : if TRUE, label the y-axis in kHz instead of Hz
    #
    # Returns nothing
    #
    for (p in levels(data$phone)){
        pdata <- subset(data, phone==p)
        pct <- (pdata$measurement-0.5) / max(pdata$measurement) 
        topfreq <- data[,paste(formants[length(formants)], plot.lines, sep='')]
        topband <- data[,paste(formants[length(formants)], plot.bands, sep='')]
        if (kHz){
            topfreq <- topfreq / 1000
            topband <- topband / 1000
            }
        plot(0, 0, xlim=c(0,1), ylim=c(0, max(topfreq+topband)), type='n', xlab=xlab, ylab=ylab, main=paste('/',p,'/ ',main,sep=''))
        lf <- length(formants)
        if (smoothing){
            plot.x <- seq(min(pct), max(pct), length.out=smoothing)
            }else{
            plot.x <- pct
            }
        for (i in 1:lf){
            formant = formants[i]
            freq <- pdata[,paste(formant, plot.lines, sep='')]
            band <- pdata[,paste(formant, plot.bands, sep='')]/2
            if (kHz){
                freq <- freq / 1000
                band <- band / 1000
                }
            if (smoothing){
                f.freq <- approxfun(pct, freq)
                freq <- f.freq(plot.x)
                f.band <- approxfun(pct, band)
                band <- f.band(plot.x)
                }
            polygon(c(plot.x, rev(plot.x)), c(freq+band, rev(freq-band)), col=rainbow(rainbow_multiplier*lf, alpha=alpha, v=v)[i], border=F)
            lines(plot.x, freq, col=rainbow(rainbow_multiplier*lf, v=v)[i], lwd=2)
            }
        }
    }

##############################################################
#  FUNCTIONS FOR SELECTING FORMANT MEASUREMENTS
#   readCovarMatrices
#   readMeans
#   findPopParameters
#   findVowelMeans
#   findCovarianceMatrices
#   measurement.columns
#   findSpanMiddle
#   find.best.measurements
##############################################################

readCovarMatrices <- function(filename, language='French', phones=NULL){
    # Read the formant and log bandwidth covariance matrices from a table and put them in a list.
    #
    # Args:
    #           filename : the filename (for a file containing the table)
    #
    # Returns a list of covariance matrices (one matrix per vowel)
    #
    all.covar <- list()
    all.covar.table = read.table(filename, h=T, sep='\t')
    all.covar.table$phone <- sortVowelFactor(all.covar.table$phone, language=language)
    if (language=='English'){
        #all.covar.table <- subset(all.covar.table, phone%in%c(p2fa_vowels,buckeye_vowels))
        all.covar.table <- subset(all.covar.table, phone%in%c(target_phones))
        all.covar.table$phone <- factor(all.covar.table$phone)
    }else{
        all.covar.table <- subset(all.covar.table, phone%in%c(french_vowels_sorted))
        all.covar.table$phone <- factor(all.covar.table$phone)
    }
    covar.names <- names(all.covar.table)[2:length(all.covar.table[1,])]
    if (is.null(phones)){
        phones <- levels(all.covar.table$phone)
    }
    for (p in levels(all.covar.table$phone)){
        if (p%in%phones){ 
            all.covar[[p]] <- as.matrix(subset(all.covar.table, phone==p)[,covar.names], dimnames=list(covar.names, covar.names))
            rownames(all.covar[[p]]) <- colnames(all.covar[[p]])
        }
    }
    all.covar
}

readMeans <- function(filename, target_phones, language){
    all.means       <- read.table(filename, h=T, sep='\t')
    all.means       <- subset(all.means, phone%in%target_phones)
    all.means$phone <- factor(all.means$phone)
    all.means$phone <- sortVowelFactor(all.means$phone, language=language, vowels_sorted=target_phones)
    all.means       <- all.means[with(all.means, order(phone, measurement)),]
    all.means
}

findPopParameters <- function(data, formants=c('F1','F2','F3','F4','F5'), write.to.file=FALSE, filename, params=c('frequency', 'log_bandwidth'), old_parameters=NULL, pass_id=NULL){
    # Find the mean and standard deviation of the vowel category means for each formant,
    # in order to transform Lobanov normalized vowels back into Hertz.
    #
    # Args:
    #               data : a data table including unnormalized formant frequencies
    #           formants : the formants to include in the table
    #      write.to.file : whether to write the result to a file
    #           filename : the filename to use (if writing to a file)
    #
    # Returns a data frame with the means and standard deviations
    #
    population <- data.frame(group='all')
    for (param in params){
        col_names <- c(paste(formants, param, 'mean', sep='_'), paste(formants, param, 'sd', sep='_'))
        for (p in col_names){
            population[,p] <- mean(aggregate(data[,p] ~ data[,'subject'], FUN=mean)[,2])
        }
    }
    if (write.to.file==TRUE){
        write_fn <- paste(writepath,filename,'.csv',sep='')
        write.table(population, file=write_fn, row.names=FALSE, sep='\t')
        print(paste('wrote',write_fn))
        if (!is.null(pass_id)){
            write_fn <- paste(writepath,filename,'_',pass_id,'.csv',sep='')
            write.table(population, file=write_fn, row.names=FALSE, sep='\t')
            print(paste('wrote',write_fn))
        }
    }
    if (!is.null(old_parameters)){
        if (ncol(population) == ncol(old_parameters) & nrow(population) == nrow(old_parameters)){
            print('Change in population parameters:')
            print(cbind(population[,1],population[,2:ncol(population)]-old_parameters[,2:ncol(population)]))
        }else{
            print('(Not comparing with old population parameters because the data frames are not the same size)')
        }
        print('(Not comparing with old population parameters because there aren\'t any)')
    }
    population
}

findVowelMeans <- function(data, formants=c('F1','F2','F3','F4','F5'), write.to.file=FALSE, filename, language='French', default_meas=0.325, old_vowel_means=NULL, normalized=TRUE, pass_id=NULL, target_phones=NULL){
    # Find the mean formant frequency and log bandwidth for each vowel.
    #
    # Args:
    #               data : a data table including normalized formant frequencies and log bandwidths
    #           formants : the formants to include in the table
    #      write.to.file : whether to write the result to a file
    #           filename : the filename to use (if writing to a file)
    #
    # Returns a data frame with the mean frequencies and log bandwidths
    #
    if (!'measurement'%in%names(data)){
        data$measurement <- default_meas
    }
    if (normalized){
        sep <- 'n_'
    }else{
        sep <- '_'
    }
    vowel_means <- aggregate(data[,paste(formants[1], 'frequency', sep=sep)] ~ data[,'measurement'] * data[,'phone'], FUN=mean)
    Fcol <- paste(formants[1], 'frequency', sep=sep)
    
    names(vowel_means) <- c('measurement', 'phone', Fcol)
    vowel_means$phone <- sortVowelFactor(vowel_means$phone, language=language, vowels_sorted=target_phones)
    vowel_means <- vowel_means[with(vowel_means, order(phone, measurement)),]
    if (length(formants)>1){
        for (formant in formants[2:length(formants)]){
            Fcol <- paste(formant, 'frequency', sep=sep)
            new_column <- aggregate(data[,Fcol] ~ data[,'measurement'] * data[,'phone'], FUN=mean)
            names(new_column) <- c('measurement', 'phone', Fcol)
            vowel_means <- merge(vowel_means, new_column, by=c('measurement','phone'))
        }        
    }
    for (formant in formants){
        Fcol <- paste(formant, 'log_bandwidth', sep=sep)
        new_column <- aggregate(data[,Fcol] ~ data[,'measurement'] * data[,'phone'], FUN=mean)
        names(new_column) <- c('measurement', 'phone', Fcol)
        vowel_means <- merge(vowel_means, new_column, by=c('measurement','phone'))
    }  

    vowel_means <- vowel_means[order(vowel_means$phone),]
    if (!is.null(old_vowel_means)){
        old_vowel_means <- old_vowel_means[order(old_vowel_means$phone),]
    }
    if (write.to.file==TRUE){
        write_fn <- paste(writepath,filename,'.csv',sep='')
        write.table(vowel_means, file=write_fn, row.names=FALSE, sep='\t')
        print(paste('wrote',write_fn))
        if (!is.null(pass_id)){
            write_fn <- paste(writepath,filename,'_',pass_id,'.csv',sep='')
            write.table(vowel_means, file=write_fn, row.names=FALSE, sep='\t')
            print(paste('wrote',write_fn))
        }
    }
    if (!is.null(old_vowel_means)){
        if (ncol(vowel_means) == ncol(old_vowel_means) & nrow(vowel_means) == nrow(old_vowel_means)){
            print('Change in vowel means:')
            print(cbind(vowel_means[,1:2],vowel_means[,3:length(vowel_means[1,])]-old_vowel_means[,3:length(vowel_means[1,])]))
        }else{
            print('(Not comparing with old means because the data frames are not the same size)')
        }
        print('(Not comparing with old means because there aren\'t any)')
    }
    vowel_means
}

findCovarianceMatrices <- function(data, formants=c('F1','F2','F3','F4','F5'), parameters=NULL, measurements=c(0.325), write.to.file=FALSE, filename, language='French', vowel_means=all.means, normalized=TRUE, pass_id=NULL, target_phones=NULL){
    # Find the covariance matrices of the formant frequencies and log bandwidths for each vowel.
    #
    # Args:
    #               data : a data table including normalized formant frequencies and log bandwidths
    #           formants : the formants to include in the table
    #       measurements : which measurements (time points) to include
    #      write.to.file : whether to write the result to a file
    #           filename : the filename to use (if writing to a file)
    #
    # Returns a list containing a covariance matrix for each vowel.
    #
    if (!'measurement'%in%names(data)){
        data$measurement <- measurements[1]
        print('no measurement')
    }
    fstart <- proc.time()
    if (normalized){
        sep <- 'n_'
    }else{
        sep <- '_'
    }
    if (is.null(parameters)){
        column_names <- c(paste(formants, 'frequency', sep=sep), paste(formants, 'log_bandwidth', sep=sep))
    }else{
        column_names <- parameters
    }
    fdata <- data.frame(phone=factor(data[data$measurement==measurements[1],'phone']))
    for (measurement in measurements){
        for (i in 1:length(column_names)){
            fdata[,paste(column_names[i], measurement, sep='_')] <- data[data$measurement==measurement,column_names[i]]
        }
    }
    for (measurement in measurements){
        fdata <- fdata[!is.na(fdata[,paste(column_names[length(column_names)], measurement, sep='_')]),]
    }
    cov_matrices <- list()

    fdata$phone <- sortVowelFactor(fdata$phone, language=language, vowels_sorted=target_phones)
    #for (phone in levels(fdata$phone)){
    for (phone in unique(fdata$phone)){
        #print(phone)
        #print(sum(fdata$phone==phone))
        #if (sum(fdata$phone==phone)>0){
        cov_matrices[[phone]] <- cov(fdata[fdata$phone==phone,2:length(fdata[1,])])
        #}
    }
    print(paste('calculating covariance matrices for', length(unique(fdata$phone)), 'phones,', length(column_names), 'parameters, and', 
                length(measurements), 'measurement point(s) took', paste(round((proc.time()-fstart)[3],3)), 'seconds'))
    filenames <- c(filename)
    if (!is.null(pass_id)){
        filenames <- c(filenames, paste(filename,pass_id,sep='_'))
    }
    if (write.to.file==TRUE){
        for (fn in filenames){
            write_fn <- paste(writepath,fn,'.csv',sep='')
            write.table(data.frame(phone='', cov_matrices[[1]])[FALSE,], file=write_fn, sep='\t', row.names=F)
            for (i in 1:length(cov_matrices)){
                #print(names(cov_matrices)[i])
                write.table(data.frame(phone=names(cov_matrices)[i], cov_matrices[[i]]), file=write_fn, 
                            append=TRUE, col.names=FALSE, sep='\t', row.names=F)
            }
            print(paste('wrote',write_fn))
        }
    }
    cov_matrices
}

measurement.columns <- function(data, meas=as.numeric(levels(factor(data$measurement))), formants=c('F1','F2','F3','F4','F5'), 
                                columns=names(data)[1:(min(which(substr(names(data),1,2)=='F1'))-1)], params=c('frequency','log_bandwidth')){
    # Put the measurements for different time points into different columns.
    #
    # Args:
    #               data : a data table including normalized formant frequencies and log bandwidths
    #               meas : which measurements (time points) to include
    #           formants : the formants to make columns for
    #
    # Returns a data frame containing the same measurements arrayed horizontally.
    #
    if ('F1n_frequency'%in%columns){
        sep <- 'n_'
    }else{
        sep <- '_'
    }
    data.horiz <- data.frame(subset(data, measurement==meas[1]))[,columns]
    if ('token_id'%in%names(data)){
        data.horiz$token_id <- data.frame(subset(data, measurement==meas[1]))$token_id
    }
    for (f in formants){
        for (param in params){
            input_parameter <- paste(f, param, sep=sep)
            for (m in meas){
                data.horiz[,paste(input_parameter, m, sep='_')] <- subset(data, measurement==m)[,input_parameter]
            }
        }
    }
    data.horiz[,which(names(data.horiz)!='measurement')]
}

findSpanMiddle <- function(mdists, span_threshold=1){
    # choose a max formant from the middle of the range of good values
    best <- min(mdists)
    too_far <- c(0, which(mdists-best > span_threshold), length(mdists)+1)
    middle <- mean(c(min(subset(too_far, too_far>max(which(mdists==best)))), max(subset(too_far, too_far<min(which(mdists==best))))))
    mdists==min(mdists[c(floor(middle), ceiling(middle))])
}

find.best.measurements <- function(bestmeas.input, target_phones, means.horiz, all.covar, formants=c('F1','F2','F3','F4','F5'), meas=0.325, columns=NULL, plot.the.vowels=FALSE, s='subject', verbose=FALSE, selection='best'){
    # Use a modification of Evanini's (2009) technique to choose the best max formant value for each token.
    #
    # Args:
    #          data.vert : a data frame with the formants arranged vertically (with different measurement points on different rows)
    #        means.horiz : the population's formant means, arranged horizontally
    #           all.covar : the population's covariance matrix 
    #           formants : the formants to consider
    #               meas : which measurements (time points) to include
    #
    # Returns the same data frame with columns for mahalanobis distance and best mahalanobis distance.
    #
    phone_summary <- aggregate(token_id==token_id ~ phone * max_formant * nasal_formant * measurement, FUN=sum, data=bestmeas.input)
    #phones_n_more_than_one <- unique(phone_summary[phone_summary[,5]>1,1])
    #data.vert <- subset(bestmeas.input, phone%in%intersect(target_phones, phones_n_more_than_one))
    #data.other <- subset(bestmeas.input, !phone%in%intersect(target_phones, phones_n_more_than_one))
    data.vert <- subset(bestmeas.input, phone%in%target_phones)
    data.other <- c()
    if (!'measurement'%in%names(data.vert)){
        data.vert$measurement <- meas
    }
    formant.column <- c()
    meas.column <- c()
    coltype.column <- c()
    p <- names(all.covar)[1]

    for (colname in colnames(all.covar[[p]])){
        namelist <- unlist(strsplit(colname, '_'))
        formant.column <- c(formant.column, substr(colname,1,2))
        meas.column <- c(meas.column, as.numeric(rev(namelist)[1]))
        coltype.column <- c(coltype.column, rev(namelist)[2])
    }
    covar.column.info <- data.frame(matrix.name=colnames(all.covar[[p]]), formant=formant.column, 
                                    measurement=meas.column, column.type=coltype.column)
    matrix.names <- paste(subset(covar.column.info, formant%in%formants&measurement%in%meas)$matrix.name)
    data.filter <- c()
    for (p in unique(data.other$phone)){
        print(p)
    }

    for (p in unique(data.vert$phone)){
        fstart <- proc.time()
        data.sub <- subset(data.vert, phone==p)
        print(paste(p, length(unique(data.sub$token_id))))
        data <- measurement.columns(data.sub, formants=formants, columns=columns)
        p.matrix <- all.covar[[p]][rownames(all.covar[[p]])%in%matrix.names,colnames(all.covar[[p]])%in%matrix.names]
        if (det(p.matrix)>10){
            data$mdist <-  mahalanobis(data[,matrix.names],
                                       c(as.matrix(means.horiz[means.horiz$phone==p,matrix.names])),
                                       p.matrix)
            data.filter <- rbind(data.filter, data)
        }else{
            data.other <- rbind(data.other, subset(bestmeas.input, phone==p))
            print (paste('not using matrix for',p, 'because the determinant is', det(p.matrix)))
        }
    }
    d.mdist <- aggregate(mdist~token_id*max_formant, data=data.filter, FUN=mean)
    d.best <- ddply(d.mdist, .(token_id), summarize, best_mdist=min(mdist))
    span_threshold <- sd(d.best$best_mdist)/2
    d.middle <- ddply(d.mdist, .(token_id), summarize, mid_freq=findSpanMiddle(mdist, 2), max_formant=max_formant)
    d.mdist <- merge(d.mdist, d.best, by='token_id', all=TRUE)
    d.mdist <- merge(d.mdist, d.middle, by=c('token_id', 'max_formant'))
    d.mdist$best <- d.mdist$mdist==d.mdist$best_mdist
    if (verbose){
        print(paste('evaluating', length(unique(data$token_id)), 'tokens of /', p, '/ with', length(matrix.names), 
                    'measurements per token took', paste(round((proc.time()-fstart)[3],3)), 'seconds'))
    }
    data.vert <- merge(data.vert, d.mdist, by=c('token_id', 'max_formant'))
    #data.vert$phone <- factor(data.vert$phone)
    if (selection=='span'){
        data.filtered <- subset(data.vert, mid_freq==TRUE)
    }else{
        data.filtered <- subset(data.vert, best==TRUE)
    }

    if (plot.the.vowels){
        cairo_pdf(paste(writepath,s,'_best_measurements.pdf',sep=''), h=5, w=5, onefile=T)
        if ('F1n_frequency'%in%names(data.filtered)){
            plot.vowels(data.filtered, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=meas, mf=c('all'))
        }
        plot.vowels(data.filtered, param1='F2_frequency', param2='F1_frequency', subject=s, meas=meas, mf=c('all'))
        hist(data.filtered$max_formant, xlab='max formant', ylab='tokens', main=s, breaks=20)
        dev.off()
    }

    #USE DEFAULT MAX FORMANT FOR PHONES WITHOUT PRIORS
    median_mf <- median(data.vert[data.vert$best,]$max_formant, na.rm=T)
    median_mdist <- median(data.vert$mdist)
    if (length(data.other)){
        data.other$mdist <- 2*median_mdist
        data.other$best_mdist <- 0
        data.other$mid_freq <- data.other$max_formant==median_mf
        data.other$best <- data.other$max_formant==median_mf
        print (paste('USED DEFAULT MAX FORMANT OF', median_mf, 'FOR', paste(unique(data.other$phone),collapse=' ')))
        data.vert <- rbind(data.vert, data.other)
    }    
    data.vert$phone <- factor(data.vert$phone)
    data.vert
}

##############################################################
# MAIN LOOP FUNCTIONS
#   updateThreeParameters
#   fixed.maxformant.loop
#   mahalanobis.loop
#   normalizeAndPlot
#   makeContourInstructions <- function(corpus, speakers=unique(corpus$subject)){
#   loadContourData 
#   add.contexts
#   refineSegmentation
#   trim.corpus
##############################################################

updateThreeParameters <- function(corpus, language, file.prefix, default_meas=c(0.25), old_means=NULL, old_param=NULL,                  
                                  normalized=FALSE, collapse.maxformant=TRUE, pass_id=NULL, target_phones=NULL, formants=c('F1','F2','F3','F4','F5')){
    # Update the means, covariance matrices, and population parameters, based on the corpus
    all.means     <-     findVowelMeans(corpus, 
                                       language=language, 
                                       write.to.file=TRUE, 
                                       filename=paste(file.prefix, 'means', sep='_'), 
                                       default_meas=default_meas, 
                                       old_vowel_means=old_means, 
                                       normalized=normalized, pass_id=pass_id, target_phones=target_phones,
                                       formants=formants)
    
    all.covar <- findCovarianceMatrices(corpus, 
                                       formants=formants, 
                                       measurements=default_meas, 
                                       write.to.file=TRUE, 
                                       filename=paste(file.prefix, 'covmats', sep='_'), 
                                       language=language, 
                                       vowel_means=all.means, 
                                       normalized=FALSE, pass_id=pass_id, target_phones=target_phones)

    all.param    <-   findPopParameters(findAllSubjectParameters(corpus, collapse.maxformant=collapse.maxformant, formants=formants), 
                                       write.to.file=TRUE,
                                       filename=paste(file.prefix, 'parameters', sep='_'),  
                                       old_parameters=old_param, pass_id=pass_id,
                                       formants=formants)
}

fixed.maxformant.loop <- function(speakers, datafiles, demo, language='French', female=6100, male=5400, target_phones, default_meas=c(0.25), exclude_nonvowels=TRUE, applyrules=TRUE, min_duration=0.05, merge_vl=FALSE){
    #MAKE THE FIRST PASS USING FIXED MAX FORMANT VALUES
    raw_corpus <- c()
    cairo_pdf(paste(writepath,'vowels_pass1.pdf',sep=''), h=5, w=5, onefile=T)
    
    for (s in speakers){
        #READ THE DATA FILES
        alldata <- loadSegmentFormantData(datafiles, s, language, default_meas=default_meas, exclude_nonvowels=exclude_nonvowels, applyrules=applyrules, min_duration=min_duration, target_phones=target_phones, merge_vl=merge_vl)
        segment.data <- alldata$segments


        #print('A')
        #print(aggregate(phone==phone~phone, FUN=sum, data=segment.data))

        formant.data <- alldata$formants
        if (subset(demo, subject==s)$sex %in% c('female', 'Female', 'F', 'f')){
            best_maxformant <- female
        }else{
            best_maxformant <- male
        }
        if(!is.null(segment.data)){
            bestmax.unnormalized <- merge(subset(segment.data, exclude==0), subset(formant.data, max_formant==best_maxformant), by='token_id')
            bestmax.unnormalized$subject <- s
            #print('B')
            #print(aggregate(phone==phone~phone, FUN=sum, data=bestmax.unnormalized))
            #print (target_phones)
            s.data <- subset(bestmax.unnormalized, exclude==0 & phone%in%target_phones)

            #print (subset(bestmax.unnormalized, !phone%in%target_phones)$phone)
            #print(target_phones)
            raw_corpus <- rbind(raw_corpus, s.data)
            #print('C')
            print(aggregate(phone==phone~phone, FUN=sum, data=s.data))
            s.data$phone <- factor(s.data$phone)
            #print('D')
            #print(aggregate(phone==phone~phone, FUN=sum, data=s.data))

            s.data$phone <- sortVowelFactor(s.data$phone, language=language, vowels_sorted=target_phones)
            plot.data <- s.data

            #print(summary(plot.data))
            plot.vowels(plot.data, param1='F2_frequency', param2='F1_frequency', subject=s, meas=default_meas[1], mf=('all'), main=paste(s,'F1 and F2'))
        }

        #print(levels(plot.data$phone))
        #print(aggregate(phone==phone~phone, FUN=sum, data=plot.data))

    }
    dev.off()
    raw_corpus$phone <- factor(raw_corpus$phone)
    write.table(raw_corpus, file=paste(writepath,'corpus_bestmax.csv', sep=''), row.names=FALSE, sep='\t')
    raw_corpus
}

mahalanobis.loop <- function(speakers, datafiles, demo=NULL, language='', all.means, all.covar, target_phones, 
                             formants=c('F1','F2','F3','F4','F5'), default_meas=c(0.25), selection='span', applyrules=TRUE, min_duration=0.05, 
                             exclude_nonvowels=TRUE, pass=1, merge_vl=FALSE){
    # Make subsequent passes using Mahalanobis distance to select measurements
    corpus <- c()
    cairo_pdf(paste(writepath,'vowels_bestmeas_pass',pass,'.pdf',sep=''), h=5, w=5, onefile=T)

    for (s in speakers){
        print(s)
        #READ THE DATA FILES
        alldata <- loadSegmentFormantData(datafiles, s, language, default_meas=default_meas, exclude_nonvowels=exclude_nonvowels, applyrules=applyrules, min_duration=min_duration, merge_vl=merge_vl, target_phones=target_phones)
        segment.data <- alldata$segments
        formant.data <- alldata$formants

        # print('### SEGMENT ###')
        # print(summary(segment.data))
        # print('### FORMANT ###')
        # print(summary(formant.data))
        #print(aggregate(phone==phone ~ phone, data=segment.data, FUN=sum))
        #print(unique(segment.data$phone))
        #FIND THE BEST MAX FORMANT VALUE FOR EACH TOKEN, BASED ON MAHALANOBIS DISTANCE
        if (!is.null(segment.data)){
            #print('y0')
            formant.data <- merge(formant.data, segment.data[,c('token_id', 'phone')], by='token_id') 
            #print(names(formant.data))
            #print(aggregate(token_id==token_id ~ phone, data=formant.data, FUN=sum))
            formant.mdist <- find.best.measurements(formant.data, target_phones, measurement.columns(all.means, columns=c('measurement', 'phone')), all.covar, formants=formants, meas=default_meas, columns=c('max_formant', 'token_id', 'phone'), plot.the.vowels=FALSE, s=s, selection=selection)
            formant.bestmeas <- subset(formant.mdist, mid_freq==TRUE)
            s.data <- merge(subset(segment.data, exclude==0), formant.bestmeas, by=c('token_id', 'phone'))
            s.data$subject <- s
            s.data <- subset(s.data, phone%in%target_phones)
            #print(unique(s.data$phone))
            s.data$phone <- factor(s.data$phone)
            #print('x')
            s.data$phone <- sortVowelFactor(s.data$phone, vowels_sorted=target_phones)
            #print('y')
            #print(unique(formant.data$phone))
            s.data$subject <- s
            corpus <- rbind(corpus, s.data)
            
            #PLOT THE VOWELS
            plot.data <- s.data
            plot.vowels(plot.data, param1='F2_frequency', param2='F1_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                        main=paste(s,'F1 and F2'))
            plot.vowels(plot.data, param1='F2_frequency', param2='F1_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                        size_param='mdist', inches=median(plot.data$mdist)/25, main=paste(s,'F1 and F2'))
            hist(plot.data$max_formant, xlab='max formant', ylab='tokens', main=paste(s, 'best max formant'), breaks=20)
        }
    }
    hist(corpus$max_formant, xlab='Max formant', ylab='tokens', main=paste('pass', pass, 'summary 1'), breaks=20)
    hist(corpus$mdist, xlab='Mahalanobis distance', ylab='tokens', main=paste('pass', pass, 'summary 2'), breaks=100)
    dev.off()
    write.table(corpus, file=paste(writepath,'corpus_bestmeas_pass',pass,'.csv', sep=''), row.names=FALSE, sep='\t')
    corpus
}

normalizeAndPlot <- function(speakers, corpus, default_meas=c(0.25), formants=c('F1','F2','F3','F4','F5')){
    cairo_pdf(paste(writepath,'vowels_normalized.pdf',sep=''), h=5, w=5, onefile=T)
    normalized_corpus <- c()
    for (s in speakers){
        print(s)
        s.data <- subset(corpus, subject==s)
        if(nrow(s.data)>0){
            
            formant.param <- findSubjectParameters(s.data, default_meas=default_meas[1], collapse.maxformant=TRUE, formants=formants)
            s.data <- normalizeFormants(s.data, all.param, formant.param, formants=formants, meas=default_meas[1], collapse.maxformant=TRUE)
            normalized_corpus <- rbind(normalized_corpus, s.data)

            #PLOT THE VOWELS
            plot.data <- s.data
            plot.vowels(plot.data, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                        main=paste(s,'normalized F1 and F2'))
            plot.vowels(plot.data, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                        size_param='mdist', inches=median(plot.data$mdist)/25, main=paste(s,'normalized F1 and F2'))

            mdist.cutoff <- exp(mean(log(corpus$mdist))+sd(log(corpus$mdist)))
            plot.data <- subset(s.data, mdist<mdist.cutoff)
            plot.vowels(plot.data, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                        main=paste(s,'normalized and selected F1 and F2'))
            plot.vowels(plot.data, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                        size_param='mdist', inches=median(plot.data$mdist)/25, main=paste(s,'normalized and selected F1 and F2'))
            if ('F3'%in%formants){
                plot.vowels(plot.data, param1='F2n_frequency', param2='F3n_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                            main=paste(s,'normalized and selected F2 and F3'))
                plot.vowels(plot.data, param1='F2n_frequency', param2='F3n_frequency', subject=s, meas=default_meas[1], mf=('all'), 
                            size_param='mdist', inches=median(plot.data$mdist)/25, main=paste(s,'normalized and selected F2 and F3'))
            }
            if (length(default_meas)>1){
                plot.vowels(plot.data, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=default_meas[2], mf=('all'), 
                            main=paste(s,'(2nd) norm/sel F1 and F2'))
                plot.vowels(plot.data, param1='F2n_frequency', param2='F1n_frequency', subject=s, meas=default_meas[2], mf=('all'), 
                            size_param='mdist', inches=median(plot.data$mdist)/25, main=paste(s,'(2nd) norm/sel F1 and F2'))

                if ('F3'%in%formants){
                    plot.vowels(plot.data, param1='F2n_frequency', param2='F3n_frequency', subject=s, meas=default_meas[2], mf=('all'), 
                                main=paste(s,'(2nd) norm/sel F2 and F3'))
                    plot.vowels(plot.data, param1='F2n_frequency', param2='F3n_frequency', subject=s, meas=default_meas[2], mf=('all'), 
                                size_param='mdist', inches=median(plot.data$mdist)/25, main=paste(s,'(2nd) norm/sel F2 and F3'))
                }
            }
        }
    }
    dev.off()
    write.table(normalized_corpus, file=paste(writepath,'corpus_normalized.csv', sep=''), row.names=FALSE, sep='\t')
    normalized_corpus
}
        
makeContourInstructions <- function(corpus, speakers=unique(corpus$subject)){
    for (s in speakers){
        for (t in unique(subset(corpus, subject==s)$textgrid)){
            s.data <- subset(corpus, subject==s & textgrid==t & word != 'jedis' & measurement==min(unique(corpus$measurement)))
            s.data <- s.data[,c('token_id', 'phonestart', 'phoneend', 'max_formant', 'nasal_formant', 'mdist')]
            write.table(s.data, file=paste(writepath, t, '_contour_instructions.csv', sep=''), row.names=FALSE, sep='\t')
        }
    }
}

refineSegmentation <- function(all.d, method='bandwidth', choice='conservative', normalized_bandwidth=FALSE, formants=c('F1','F2','F3','F4','F5')){
    print('refining segmentation...')
    all.data.b <- c()

    if (grep('mdist', method)){
        phone_summary0 <- aggregate(word==word ~ token_id * phone, FUN=sum, data=all.d)
        phone_summary1 <- aggregate(rep(1,nrow(phone_summary0)) ~ phone_summary0[,2], FUN=sum)
        phones_enough_tokens <- unique(phone_summary1[phone_summary1[,2]>=3,1])
        print (paste('USING BANDWIDTH TECHNIQUE FOR', paste(setdiff(unique(all.d$phone),phones_enough_tokens),collapse=' ')))
    }
    #print('refineSegmentation')
    #print(subset(all.d, token_id=='nov17_BANG_178_2')$time)
    for (p in unique(all.d$phone)){
        d <- subset(all.d, phone==p)
        d$original <- with(d, time>phonestart & time<phoneend)
        if (grep('mdist', method)){
            if (p%in%phones_enough_tokens){

                print (p)

                matrix.names <- c(paste(formants[1:(length(formants)-1)], 'frequency', sep='_'), 
                                  paste(formants[1:(length(formants)-1)], 'log_bandwidth', sep='_'))
                if (method=='mdist2'){
                    delta.names <- c()
                    for (mn in matrix.names){
                        mn_d1 <- paste(mn,'d1',sep='_')
                        mn_d2 <- paste(mn,'d2',sep='_')
                        d[,mn_d1] <- c(0, diff(d[,mn]))
                        d[,mn_d2] <- c(diff(d[,mn]), 0)
                        delta.names <- c(delta.names, mn_d1, mn_d2)
                    }
                    matrix.names <- c(matrix.names, delta.names)
                }
                
                means.phone <- c()
                for (mn in matrix.names){
                    #means.phone <- c(means.phone, mean(d[,mn], na.rm=T))
                    means.phone <- c(means.phone, mean(d[d$original,mn], na.rm=T))
                }
                #cov.phone <- cov(na.omit(d[,matrix.names]))
                cov.phone <- cov(na.omit(d[d$original,matrix.names]))
                #d$contour.mdist <- mahalanobis(d[,matrix.names], as.numeric(means.phone), cov.phone)
                d$contour.mdist <- mahalanobis(d[,matrix.names], as.numeric(means.phone), cov.phone)
                d$mean_bandwidth <- NA
                #mdist.cutoff1 <- exp(mean(log(na.omit(d$contour.mdist)))+sd(log(na.omit(d$contour.mdist))))
                #mdist.cutoff2 <- exp(mean(log(na.omit(d$contour.mdist)))+2*sd(log(na.omit(d$contour.mdist))))
                #mdist.cutoff1 <- exp(mean(log(na.omit(d$contour.mdist)))+2*sd(log(na.omit(d$contour.mdist))))
                mdist.cutoff1 <- quantile(d$contour.mdist, probs=0.75, na.rm=T)
                mdist.cutoff2 <- 1.5*median(d$contour.mdist, na.rm=T)
                #mdist.cutoff2 <- quantile(d$contour.mdist, probs=0.75, na.rm=T)

                print(c(mean(d[d$original,]$contour.mdist), mean(d[!d$original,]$contour.mdist)))

                print(paste('mdist.cutoff is', mdist.cutoff2,'or',mdist.cutoff1,'for',p))
                d$good <- with(d, contour.mdist<mdist.cutoff2)
                d$verygood <- with(d, contour.mdist<mdist.cutoff1)
                print(paste('data retained:', mean(d[d$original,'good'], na.rm=T)))
            }else{
                d$contour.mdist <- NA
                d$mean_bandwidth <- rowMeans(d[,paste(formants, 'log_bandwidth', sep='_')],na.rm=T)
                bw.cutoff1 <- mean(d$mean_bandwidth, na.rm=T) + sd(d$mean_bandwidth, na.rm=T)
                bw.cutoff2 <- mean(d$mean_bandwidth, na.rm=T) + 2*sd(d$mean_bandwidth, na.rm=T)
                d$good <- with(d, mean_bandwidth<bw.cutoff2)
                d$verygood <- with(d, mean_bandwidth<bw.cutoff1)
            }
            d$phonestart.original <- d$phonestart
            d$phoneend.original <- d$phoneend
            d$phonestart.conservative <- d$phonestart
            d$phoneend.conservative <- d$phoneend
            d$phonestart.greedy <- d$phonestart
            d$phoneend.greedy <- d$phoneend
            for (t in unique(d$token_id)){
                #print (t)
                token <- subset(d, token_id==t)
                first.original.good <- min(subset(token, good&original)$time)
                last.original.good <- max(subset(token, good&original)$time)
                #early.bad.times <- subset(token, time<phonestart & !good)$time
                #late.bad.times <- subset(token, time>phoneend & !good)$time
                early.bad.times <- subset(token, time<phonestart & !verygood)$time
                late.bad.times <- subset(token, time>phoneend & !verygood)$time
                #print(early.bad.times)
                #print(late.bad.times)
                d[d$token==t,]$phonestart.conservative <- first.original.good
                d[d$token==t,]$phoneend.conservative <- last.original.good
                if (length(early.bad.times)){
                    last.early.bad <- max(early.bad.times)
                    d[d$token==t,]$phonestart.greedy <- min(subset(token, time>last.early.bad & good)$time)
                }
                if (length(late.bad.times)){
                    first.late.bad <- min(late.bad.times)
                    d[d$token==t,]$phoneend.greedy <- max(subset(token, time<first.late.bad & good)$time)
                }
                #if (t=='nov17_BANG_178_2'){
                if (FALSE){
                    print (token[,c('time','good','contour.mdist','mean_bandwidth')])
                    print(c(first.original.good, last.original.good))
                    print(unique(token$phonestart))
                    print(unique(token$phonestart.original))
                    print(unique(token$phonestart.conservative))
                    print(unique(token$phonestart.greedy))
                    print(unique(token$phoneend))
                    print(unique(token$phoneend.original))
                    print(unique(token$phoneend.conservative))
                    print(unique(token$phoneend.greedy))
                }
            }
        }else{
            if (normalized_bandwidth){
                param1 <- 'F1n_log_bandwidth'
                param2 <- 'F2n_log_bandwidth'
                param3 <- 'F3n_log_bandwidth'
            }else{
                param1 <- 'F1_log_bandwidth'
                param2 <- 'F2_log_bandwidth'
                param3 <- 'F3_log_bandwidth'
            }
            d$mean_bandwidth <- (d[,param1] + d[,param2] + d[,param3])/3
            d$geom_mean_bandwidth <- (d[,param1]*d[,param2]^2*d[,param3])^(1/3)
            d$quad_mean_bandwidth <- sqrt((d[,param1]^2 + d[,param2]^2 + d[,param3]^2)/3)

            d$dev_bandwidth <- sqrt(((d[,param1]-mean(d[,param1]))/sd(d[,param1]))^2 +
                                    ((d[,param2]-mean(d[,param2]))/sd(d[,param2]))^2 +
                                    ((d[,param3]-mean(d[,param3]))/sd(d[,param3]))^2)
        }
        for (dname in print(setdiff(names(all.data.b), names(d)))){
            d[,dname] <- NA
        }
        all.data.b <- rbind(all.data.b, d)
    }
    if (choice=='greedy'){
        all.data.b$phonestart <- all.data.b$phonestart.greedy
        all.data.b$phoneend <- all.data.b$phoneend.greedy
    }else if (choice=='conservative'){
        all.data.b$phonestart <- all.data.b$phonestart.conservative
        all.data.b$phoneend <- all.data.b$phoneend.conservative
    }
    all.data.b$probable <- with(all.data.b, good & time>=phonestart & time<=phoneend)
    all.data.b$cduration <- with(all.data.b, phoneend-phonestart)
    all.data.b$normtime <- with(all.data.b, (time-(phonestart+phoneend)/2)/duration)
    all.data.b
}


loadContourData <- function(contour_datafiles, subjects, language='French', crop.segment=TRUE, refine.segmentation=TRUE, phone_subset=c(), applyrules=TRUE, 
                            min_duration=0.05, exclude_nonvowels=TRUE, to.exclude=list(word=c(),phone=c()), method='mdist', refine.choice='conservative', exclude_tokens=NULL){
    contour.data <- c()
    for (s in subjects){
        alldata <- loadSegmentFormantData(contour_datafiles, s, language=language, contours=TRUE, exclude_nonvowels=exclude_nonvowels, applyrules=applyrules, min_duration=min_duration)
        print(s)
        segment.data <- alldata$segments
        if (!is.null(segment.data)){

            if (!is.null(exclude_tokens)){
                print(paste('excluding', length(intersect(exclude_tokens, unique(segment.data$token_id))), 'tokens'))
                segment.data <- subset(segment.data, !token_id%in%exclude_tokens)
            }

            if (length(phone_subset)){
                segment.data <- subset(segment.data, phone%in%phone_subset)
            }
            formant.data <- alldata$formants
            formant.param <- findSubjectParameters(subset(normalized_corpus, subject==s), default_meas=meas_points, collapse.maxformant=TRUE)
            formant.param <- formant.param[formant.param$measurement==meas_points[1],]
            formant.data <- normalizeFormants(formant.data, all.param, formant.param, formants=formants, meas=meas_points[1], collapse.maxformant=TRUE)
            s.data <- merge(segment.data, formant.data, by='token_id')
            s.data$subject <- s
            s.data <- subset(s.data, !word%in%to.exclude$word & !phone%in%to.exclude$phone)
            if (crop.segment){
                s.data <- subset(s.data, time>phonestart & time<phoneend)
            }            
            s.data$phone <- factor(s.data$phone)
            if (refine.segmentation){
                s.data <- refineSegmentation(s.data, method=method, choice=refine.choice)
            }
            contour.data <- rbind(contour.data, s.data)
        }
    }
    
    if (refine.segmentation){
        mdist.mean <- mean(log(contour.data$contour.mdist),na.rm=T)
        mdist.sd <- sd(log(contour.data$contour.mdist),na.rm=T)
        bandwidth.mean <- mean(contour.data$mean_bandwidth,na.rm=T)
        bandwidth.sd <- sd(contour.data$mean_bandwidth,na.rm=T)
        contour.data$mdist.weight <- 1-pmin(1,pmax(0,(log(contour.data$contour.mdist)-mdist.mean)/(2*mdist.sd)))
        contour.data[!is.na(contour.data$mean_bandwidth),]$mdist.weight <- 1-pmin(1,pmax(0,(contour.data[!is.na(contour.data$mean_bandwidth),]$mean_bandwidth-bandwidth.mean)/(2*bandwidth.sd)))

    }else{
        contour.data$probable <- with(contour.data, time>=phonestart & time<=phoneend)
        contour.data$duration <- with(contour.data, phoneend-phonestart)
        contour.data$normtime <- with(contour.data, (time-(phonestart+phoneend)/2)/duration)
        contour.data$mdist.weight <- as.numeric(contour.data$probable)
    }

    contour.data[is.na(contour.data$mdist.weight),'mdist.weight'] <- 0
    contour.data
}


add.contexts <- function(segment.data){
    n_segments <- length(segment.data$phone)
    segment.data$left0 <- c("#", paste(segment.data$phone[1:(n_segments-1)]))
    segment.data$left1 <- c("#", "#", paste(segment.data$phone[1:(n_segments-2)]))
    segment.data$right0 <- c(paste(segment.data$phone[2:(n_segments)]), "#")
    segment.data$right1 <- c(paste(segment.data$phone[3:(n_segments)]), "#", "#")
    segment.data
}


trim.corpus <- function(d, max_values, meas=0.25, param='F1_frequency'){
    good_tokens <- c()
    for (p in levels(d$phone)){
        max_value <- as.numeric(max_values[max_values$phone==p,param])
        d.p <- subset(d, phone==p & measurement==meas)
        d.p.trimmed <- d.p[d.p[,param] <= max_value,]
        good_tokens <- c(good_tokens, paste(unique(d.p.trimmed$token_id)))
        n_removed <- length(unique(d.p$token_id)) - length(unique(d.p.trimmed$token_id))
        if (n_removed>0){
            print (paste('removed', n_removed, 'tokens of', paste(p), 'with',param, 'above', max_value))
        }
    }
    subset(d, token_id%in%good_tokens)
}

##############################################################
# CONTOUR FUNCTIONS
#   F.coefs
#   sum.of.squares
#   sum.of.squares.with.parameter.penalty
#   logistic
#   plotFunctionsForOneToken
#   getRsquared
#   fitPolynomial
#   fitLogistic
#   findFunctionsForOneToken
#   findFunctions
#   plotParameters
#   summarizeParameters
#   get.p.means
#   get.p.sweep
#   get.ci
##############################################################

F.coefs <- function(x, y, method='lm', weights=NULL){
    #return the coefficients of a cubic polynomial, based on the data in a column of a data frame
    if (is.null(weights)){
        wts <- rep(1, length(x))
    }else{
        wts <- d[,weights]
    }
    #print (wts)
    if (method=='lm'){
        as.numeric(coef(lm(y ~ x + I(x^2) + I(x^3), weights=wts)))
    }else if (method=='poly_plus'){
        polynomials <- poly(x, 4)
        middle_time <- ceiling(length(polynomials[,1])/2)
        polynomials[1:middle_time,2] <- polynomials[middle_time,2]
        polynomials[,2] <- polynomials[,2] - polynomials[middle_time,2]
        polynomials[,4] <- rev(polynomials[,2])
        as.numeric(coef(lm(y ~ polynomials, weights=wts)))
    }else if (method=='poly'){
        as.numeric(coef(lm(y ~ poly(x, 3), weights=wts)))
    }else{
        as.numeric(coef(lm(y ~ poly(x, 3, raw=TRUE), weights=wts)))
    }
}

penalize.out.of.bounds <- function(x, bounds=c(-0.5,0.5)){
    if (length(bounds)==1){
        out.of.bounds <- pmax(0, x-bounds)/bounds
    }else{
        upper.bound <- max(bounds)
        lower.bound <- min(bounds)
        out.of.bounds <- pmax(0, lower.bound-x, x-upper.bound)/(upper.bound-lower.bound)
    }
    out.of.bounds
}

sum.of.squares <- function(data, parameters, fun=logistic, weights=NULL){
    #return a goodness of fit measure
    difference <- data[,2] - fun(data[,1], parameters)
    sum(weights * difference * difference)
}

sum.of.squares.with.parameter.penalty <- function(data, parameters, fun=logistic, weights=NULL){
    #return a goodness of fit measure, biasing against certain parameter values
    data.range <- range(data)
    baseline <- parameters[1] 
    peak <- parameters[2]
    crossover <- parameters[3]
    slope <- parameters[4]
    sos <- sum.of.squares(data, parameters, fun, weights) 
    #sos <- sos * (1+crossover^2)     #penalize crossover points far from 0
    sos <- sos * (1+4*crossover^2)   #penalize crossover points far from 0 (more harshly)
    sos <- sos * (1+4*(slope/10000)^2)   #penalize extreme slopes 
    #sos <- sos * (1+penalize.out.of.bounds(abs(peak-baseline), diff(data.range))) #penalize peak-baseline exceeding the data range.
    #sos <- sos * (1+sum(penalize.out.of.bounds(c(peak, baseline), data.range))) #penalize peak-baseline exceeding the data range.
    sos <- sos * (1+4*(abs(baseline-mean(data.range))/diff(data.range))^2) 
    sos <- sos * (1+4*(abs(peak-mean(data.range))/diff(data.range))^2) 
    sos
}

logistic <- function(time, par){
    #return the y values corresponding to a set of times and a set of logistic function parameters
    baseline <- par[1]
    peak <- par[2]
    crossover <- par[3]
    slope <- par[4]
    if (slope==0){
        warning(paste('logistic function parameters are', paste(par)))
        values <- rep(baseline, length(time))
    }else{
        values <- (peak-baseline) / ( 1 + exp( 4 * slope / (peak-baseline) * (crossover-time) ) ) + baseline
        values[is.na(values)] <- mean(values, na.rm=T)
    }
    values
}


fun.from.poly <- function(coefs, x.interp){ 

    polynomials <- poly(x.interp, 3)
    alpha <- attributes(polynomials)$coefs$alpha
    norm2 <- attributes(polynomials)$coefs$norm2

    F_1 <- function(x) (x - alpha[1]) / sqrt(norm2[3])
    F_2 <- function(x) ((x - alpha[2]) * (x - alpha[1]) - (norm2[3]/norm2[2]) * 1) / sqrt(norm2[4])
    F_3 <- function(x) ((x - alpha[3]) * ((x - alpha[2]) * (x - alpha[1]) - (norm2[3]/norm2[2]) * 1) - (norm2[4]/norm2[3]) * (x - alpha[1])) / sqrt(norm2[5])

    function(x) coefs[1] + coefs[2]*F_1(x) + coefs[3]*F_2(x) + coefs[4]*F_3(x)
}

plotFunctionsForOneToken <- function(token, newrow, probable, formants, f.suffix, ylim=c(0,7000), main='', weights=NULL, x_range=c(-1000,1000), interp_range=c(-0.3, 0.3), interp_points=13){
    coef.names <- c('constant','linear','quadratic','cubic')
    log.names <- c('baseline','peak','crossover','slope')
    dct.names <- c('DCT0','DCT1','DCT2','DCT3')

    if(sum(token$probable)>1){
        plot(0, 0, xlim=range(token$normtime), ylim=ylim, type='n', main=main, xlab='normalized time', ylab='frequency')
        n_formants <- length(formants)
        for (i in 1:n_formants){
            Fi <- formants[i]
            F.col <- paste(Fi,f.suffix,sep='')
            points(token$normtime, token[,F.col], col=rainbow(n_formants, v=0.6)[i], pch=c(1,4)[2-as.numeric(probable)])

            coefs <- as.numeric(newrow[,paste0(Fi,'_',coef.names)])            
            x.interp <- seq(interp_range[1], interp_range[2], length.out=interp_points)
            #print(coefs)
            #print(x.interp)
            F.poly <- fun.from.poly(coefs, x.interp)
            #print(F.poly(x.interp))
            F.poly.y <- F.poly(x.interp)
            F.logistic <- function(x) logistic(x, as.numeric(newrow[,paste0(Fi,'_',log.names)]))

            coefs <- as.numeric(newrow[,paste0(Fi,'_',dct.names)])
            dct.invert <- invertDCT(coefs, n=length(x.interp))
            F.dct <- approxfun(x.interp, dct.invert, rule=2)
           
            curve(F.poly, add=T, col=rainbow(n_formants, v=0.6)[i],lty=2, lwd=2, xlim=x_range)
            curve(F.logistic, add=T, col=rainbow(n_formants, v=0.6)[i], lwd=2, xlim=x_range)
            curve(F.dct, add=T, col=rainbow(n_formants, v=0.6)[i],lty=3, lwd=2, xlim=x_range)

            C_slopes <- as.numeric(newrow[,paste0(Fi,'_C',1:2,'_slope')])
            if(!(is.na(C_slopes[1])&is.na(C_slopes[2]))){

                #v_range <- interp_range - c(0.5)

                V1 <- token[token$normtime==paste(x_range[1]),F.col]
                V2 <- token[token$normtime==paste(x_range[2]),F.col]

                curve(V1 + (C_slopes[1]*(0-x_range[1])) + C_slopes[1]*x, xlim=c(min(token$normtime), x_range[1]), add=T, lwd=2, col=rainbow(n_formants, a=0.5, v=0.6)[i]) 
                curve(V2 - (C_slopes[2]*x_range[2]) + C_slopes[2]*x, xlim=c(x_range[2], max(token$normtime)), add=T, lwd=2, col=rainbow(n_formants, a=0.5, v=0.6)[i]) 
            }                
        }
    }else{
        plot(0, 0, type='n', main=main)
    }
}


getRsquared <- function(x, y, FUN, weights=seq(1,length(x))){
    y.predicted <- FUN(x)
    SS_tot <- sum(weights*(y-mean(y))^2)
    #SS_reg <- sum((y.predicted-mean(y))^2)
    SS_res <- sum(weights*(y-y.predicted)^2)
    R.squared <- 1-(SS_res/SS_tot)
    R.squared
}

fitPolynomial <- function(x, y, weights=NULL){
    polynomial.fit <- list()
    polynomial.fit$orth <- F.coefs(x, y, method='poly', weights=weights)
    polynomial.fit$raw  <- F.coefs(x, y, method='raw', weights=weights)
    Fc.raw <- polynomial.fit$raw
    #GET THE EXTREMA AND INFLECTION POINT FROM THE FIRST AND SECOND DERIVATIVES
    options(warn=-1)
    #extrema    <- as.real(polyroot(c(Fc.raw[2], 2*Fc.raw[3], 3*Fc.raw[4])), NoWarning=TRUE)
    #polynomial.fit$inflection <- as.real(polyroot(c(2*Fc.raw[3], 6*Fc.raw[4])), NoWarning=TRUE)
    #print(c(Fc.raw[2], 2*Fc.raw[3], 3*Fc.raw[4]))
    #print(polyroot(c(Fc.raw[2], 2*Fc.raw[3], 3*Fc.raw[4])))
    extrema    <- as.numeric(polyroot(c(Fc.raw[2], 2*Fc.raw[3], 3*Fc.raw[4])))
    polynomial.fit$inflection <- as.numeric(polyroot(c(2*Fc.raw[3], 6*Fc.raw[4])))
    options(warn=1)
    extrema <- extrema[order(extrema)]
    extrema <- c(max(min(x), extrema[1]), max(min(x), extrema[2]))
    extrema <- c(min(max(x), extrema[1]), min(max(x), extrema[2]))
    polynomial.fit$extrema <- extrema

    # polynomial.fit$FUN <- function(x){
    #     coefs <- as.numeric(Fc.raw)
    #     coefs[1] + coefs[2]*x + coefs[3]*x^2 + coefs[4]*x^3
    # }
    polynomial.fit$FUN <- fun.from.poly(polynomial.fit$orth, x)
    degree <- length(polynomial.fit$orth) - 1
    for (i in 0:degree){
        coefs.i <- c(polynomial.fit$orth[1:(i+1)], rep(0,degree-i))
        poly.fit.i <- fun.from.poly(coefs.i, x)
        polynomial.fit[[paste0('R2_d',i)]] <- getRsquared(x, y, poly.fit.i)
    }
    polynomial.fit$R.squared <- getRsquared(x, y, polynomial.fit$FUN)
    polynomial.fit
}

fitLogistic <- function(x, y, verbose=FALSE, weights=NULL){
    if (is.null(weights)){
        wts <- rep(1, length(x))
    }else{
        wts <- weights
    }
    logistic.fit <- list()
    crossover.init <- mean(range(x))
    base.init <- mean(subset(y, x<crossover.init))
    peak.init <- mean(subset(y, x>crossover.init))
    slope.init <- (peak.init-base.init)/diff(range(x))
    par.init <- c(base.init, peak.init, crossover.init, slope.init)
    if (verbose){
        print(par.init) 
    }
    logistic.fit <- optim(par=par.init, data=cbind(x,y), fn=sum.of.squares.with.parameter.penalty, method='BFGS', weights=wts)
    #logistic.fit <- optim(par=par.init, data=cbind(x,y), fn=sum.of.squares, method='BFGS', weights=wts)
    if (verbose){
        print(logistic.fit)
    }
    #summarprint(logistic.fit$par)
    logistic.fit$FUN <- function(xx) logistic(xx, logistic.fit$par)
    logistic.fit$R.squared <- getRsquared(x, y, logistic.fit$FUN)
    logistic.fit
}

fitLogistic0 <- function(x, y, verbose=FALSE, weights=NULL){
    if (is.null(weights)){
        wts <- rep(1, length(x))
    }else{
        wts <- weights
    }
    logistic.fit <- list()
    crossover.init <- mean(range(x))
    base.init <- mean(subset(y, x<crossover.init))
    peak.init <- mean(subset(y, x>crossover.init))
    slope.init <- (peak.init-base.init)/diff(range(x))
    par.init <- c(base.init, peak.init, crossover.init, slope.init)
    if (verbose){
        print(par.init) 
    }
    logistic.fit <- optim(par=par.init, data=cbind(x,y), fn=sum.of.squares, method='BFGS', weights=wts)
    #logistic.fit <- optim(par=par.init, data=cbind(x,y), fn=sum.of.squares, method='BFGS', weights=wts)
    if (verbose){
        print(logistic.fit)
    }
    #summarprint(logistic.fit$par)
    logistic.fit$FUN <- function(xx) logistic(xx, logistic.fit$par)
    logistic.fit$R.squared <- getRsquared(x, y, logistic.fit$FUN)
    logistic.fit
}

invertDCT <- function(x, n=length(x), degree=length(x)-1){
    #res <- x
    res <- rep(NA, n)
    for (k in 0:(n - 1)) {
      res[k + 1] <- 0.5 * x[1] + sum(x[2:(degree+1)] * cos(pi/n * (1:degree) * (k + 0.5)))
    }
    res <- res * (2/n)
    res
}

fitDCT <- function(x, y, verbose=FALSE, weights=NULL, degree=3, interp_points=40, interp_min=min(d[,x]), interp_max=max(d[,x])){
    if (is.null(weights)){
        wts <- rep(1, length(x))
    }else{
        wts <- weights
    }
    dct.fit <- list()

    if (interp_points == length(x)){
        x.interp <- x
        y.interp <- y
    }else{
        y.original <- y
        y.fun <- approxfun(x, y, rule=2)
        x.interp <- seq(interp_min, interp_max, length.out=interp_points)
        y.interp <- y.fun(x.interp)
    }

    dct.fit$coefs <- dct(y.interp)
    dct.invert <- invertDCT(dct.fit$coefs[1:(degree+1)], n=length(y.interp), degree=degree)
    dct.fit$FUN <- approxfun(x.interp, dct.invert, rule=2)

    for (i in 0:5){
        if (i==0){
            dct.fun.i <- function(x) rep(dct.fit$coefs[1]/(length(y.interp)), length(x))
        }else{
            dct.invert.i <- invertDCT(dct.fit$coefs[1:(i+1)], n=length(y.interp), degree=i)
            dct.fun.i <- approxfun(x.interp, dct.invert.i, rule=2)
        }
        dct.fit[[paste0('R2_d',i)]] <- getRsquared(x, y, dct.fun.i)
    }

    #dct.fit$R.squared <- getRsquared(x, y, dct.fit$FUN)

    dct.fit
}

fit.transitions <- function(token, exclude_transitions, F.col){
    transition1 <- data.frame(x=token[token$normtime <= exclude_transitions[1]-0.5,'normtime'],
                              y=token[token$normtime <= exclude_transitions[1]-0.5,F.col])

    transition2 <- data.frame(x=token[token$normtime >= exclude_transitions[2]-0.5,'normtime'],
                              y=token[token$normtime >= exclude_transitions[2]-0.5,F.col])

    v_range <- exclude_transitions - c(0.5)

    V1 <- token[token$normtime==paste(v_range[1]),F.col]
    V2 <- token[token$normtime==paste(v_range[2]),F.col]

    coefs <- c(as.numeric(coef(lm(I(y-V1)~0+I(x-v_range[1]), transition1))), 
               as.numeric(coef(lm(I(y-V2)~0+I(x-v_range[2]), transition2))))
    #print(transition2)
    #print(coefs)
    coefs
}



composite.fun <- function(x, y, fit, degree=2, C_slopes, exclude_transitions=c(0.2,0.8)){

    v_range <- exclude_transitions - 0.5
    
    V1 <- y[x==paste(v_range[1])]
    V2 <- y[x==paste(v_range[2])]

    x.interp <- x[x>=v_range[1] & x<=v_range[2]]
    y.interp <- y[x>=v_range[1] & x<=v_range[2]]

    dct.invert <- invertDCT(fit$coefs, n=length(x.interp), degree=degree)
    F.dct <- approxfun(x.interp, dct.invert, rule=2)
        
    function(x){
        res <- F.dct(x)
        res[x < v_range[1]] <- V1 + (C_slopes[1]*v_range[2]) + C_slopes[1]*x[x < v_range[1]]
        res[x > v_range[2]] <- V2 - (C_slopes[2]*v_range[2]) + C_slopes[2]*x[x > v_range[2]]
        res
    }
}

findFunctionsForOneToken <- function(token, verbose=FALSE, formants=c('F1','F2','F3'), f.suffix='n_frequency', ylim=c(0,7000), plot.contours=TRUE, weights=NULL, 
    interp_points=21, interp_for_bad=TRUE, exclude_transitions=c(0,1)){
    #FIT A LOGISTIC FUNCTION AND A CUBIC POLYNOMIAL TO EACH SET OF FORMANT MEASUREMENTS
    # 3-8-2015 adding discrete cosine transform
    #
    coef.names <- c('constant','linear','quadratic','cubic')
    log.names <- c('baseline','peak','crossover','slope')
    dct.names <- c('dct0','dct1','dct2','dct3')                     #NEW

    if (nrow(token)>5){

        #ORGANIZE THE DATA FRAME
        token <- token[order(token$time),]
        token[is.na(token$probable),'probable'] <- FALSE

        expected_columns <- c('token_id', 'subject', 'word', 'phone')
        for (c in expected_columns){
            if (!c%in%names(token)){
                token[,c] <- 'none'
            }
        }

        t <- unique(token$token_id)
        s <- unique(token$subject)
        w <- unique(token$word)
        p <- unique(token$phone)
        print(paste(t))
        highest_formant <- length(formants)
        if ('probable'%in%names(token)){
            probable <- token$probable
        }else{
            probable <- rep(TRUE, nrow(token))
        }

        #Fs.dct <- list()               #NEW


        #PROCESS THE TOKEN IF THERE ARE ENOUGH MEASUREMENTS
        if (sum(probable, na.rm=T)>5){

            newrow <- data.frame(token_id=t, subject=s, word=w, phone=p)
            
            #LOOP THROUGH FORMANTS
            for (i in 1:highest_formant){
                Fi <- formants[i]
                F.col <- paste(Fi,f.suffix,sep='')
                defined <- !is.na(token[,F.col])
                if (sum(probable&defined, na.rm=T)>5){

                    probable_token <- token[probable&defined,]
                    probable_token <- probable_token[,c('normtime',F.col)]

                    #MAKE POLYNOMIAL AND LOGISTIC FUNCTIONS FOR THIS FORMANT

                    if (interp_for_bad){
                        #x_to_fit <- token[abs(token$normtime)<=0.5,'normtime']
                        interp_range <- c(-0.5,0.5)
                        x_to_fit <- seq(interp_range[1], interp_range[2], length.out=interp_points)
                        x_to_interp <- token[probable&defined,]$normtime
                        y_to_interp <- token[probable&defined,F.col]
                        F.interpfun <- approxfun(x_to_interp, y_to_interp, rule=2)
                        y_to_fit <- F.interpfun(x_to_fit)
                    }else{
                        x_to_fit <- probable_token$normtime
                        y_to_fit <- probable_token[,F.col]
                    }

                    #print(x_to_fit)
                    #exclude transitions
                    x_range <- exclude_transitions-0.5

                    not_transitions <- x_to_fit>=x_range[1] & x_to_fit<=paste(x_range[2])
                    all_x <- x_to_fit
                    all_y <- y_to_fit
                    x_to_fit <- x_to_fit[not_transitions]
                    y_to_fit <- y_to_fit[not_transitions]

                    #print(x_to_fit)

                    #dct.fit <- fitDCT(x_to_fit, y_to_fit, verbose=verbose, weights=weights, interp_points=interp_points, interp_min=x_range[1], interp_max=x_range[2]) #NEW
                    dct.fit <- fitDCT(x_to_fit, y_to_fit, verbose=verbose, weights=weights, interp_points=length(x_to_fit), interp_min=x_range[1], interp_max=x_range[2]) #NEW
                    F.dct <- dct.fit$FUN                #NEW
                    #Fs.dct[[i]] <- F.dct                #NEW

                    #print (x_to_fit)
                    #print (y_to_fit)
                    polynomial.fit <- fitPolynomial(x_to_fit, y_to_fit, weights=weights)
                    logistic.fit <- fitLogistic(x_to_fit, y_to_fit, verbose=verbose, weights=weights)
                    
                    F.poly <- polynomial.fit$FUN
                    F.logistic <- logistic.fit$FUN



                    #fit transitions
                    # if (exclude_transitions[1] > 0 | exclude_transitions[2] < 1){

                    #     C_slopes <- fit.transitions(token, exclude_transitions, F.col)

                    # }else{
                    #     C_slopes <- c(0, 0)
                    # }

                    # dct1tran <- composite.fun(x_to_fit, y_to_fit, dct.fit, degree=1, C_slopes, exclude_transitions=c(0.2,0.8))
                    # dct3tran <- composite.fun(x_to_fit, y_to_fit, dct.fit, degree=3, C_slopes, exclude_transitions=c(0.2,0.8))

                    dct1tran <- function(x) x
                    dct3tran <- function(x) x
                    C_slopes <- c(0, 0)

                    dcttran <- list()
                    dcttran[['DCT1']] <- list()
                    dcttran[['DCT3']] <- list()
                    dcttran[['DCT1']]$fun <- dct1tran
                    dcttran[['DCT3']]$fun <- dct3tran
                    #print(x_to_fit)
                    #print(y_to_fit)
                    #print(dct2tran(x_to_fit))
                    dcttran[['DCT1']]$R.squared <- getRsquared(x_to_fit, y_to_fit, dcttran[['DCT1']]$fun)
                    dcttran[['DCT3']]$R.squared <- getRsquared(x_to_fit, y_to_fit, dcttran[['DCT3']]$fun)

                    #print(dcttran[['DCT2']]$R.squared)
                    #print(dcttran[['DCT4']]$R.squared)
                    #curve(dct4tran(x), col='green', xlim=c(-0.5,0.5), ylim=c(0,3500))
                    

                    #RECORD THE COEFFICIENTS
                    add.value <- function(newrow, formant, info_names, values){
                        newrow[,paste0(formant,'_',info_names)] <- values
                        newrow
                    }
                    newrow <- add.value(newrow, Fi, coef.names, polynomial.fit$orth)
                    newrow <- add.value(newrow, Fi, paste(coef.names,'raw',sep='_'), polynomial.fit$raw)
                    
                    newrow[,paste0(Fi,'_','inflection_time')] <- polynomial.fit$inflection
                    newrow[,paste0(Fi,'_','extreme',1:2,'_time')] <- polynomial.fit$extrema
                    newrow[,paste0(Fi,'_','extreme',1:2,'_freq')] <- F.poly(polynomial.fit$extrema)
                    newrow[,paste0(Fi,'_',log.names)] <- logistic.fit$par
                    newrow[,paste0(Fi,'_','delta')] <- logistic.fit$par[2] - logistic.fit$par[1]

                    newrow[,paste0(Fi,'_','DCT0')] <- dct.fit$coefs[1]
                    newrow[,paste0(Fi,'_','DCT1')] <- dct.fit$coefs[2]
                    newrow[,paste0(Fi,'_','DCT2')] <- dct.fit$coefs[3]
                    newrow[,paste0(Fi,'_','DCT3')] <- dct.fit$coefs[4]

                    newrow[,paste0(Fi,'_','logistic_energy')] <- logistic.fit$value
                    newrow[,paste0(Fi,'_','logistic_R.squared')] <- logistic.fit$R.squared
                    #newrow[,paste0(Fi,'_','poly_R.squared')] <- polynomial.fit$R.squared

                    newrow[,paste0(Fi,'_','poly_R.squared0')] <- polynomial.fit$R2_d0
                    newrow[,paste0(Fi,'_','poly_R.squared1')] <- polynomial.fit$R2_d1
                    newrow[,paste0(Fi,'_','poly_R.squared2')] <- polynomial.fit$R2_d2
                    newrow[,paste0(Fi,'_','poly_R.squared')] <- polynomial.fit$R.squared
                    
                    newrow[,paste0(Fi,'_','DCT_R.squared0')] <- dct.fit$R2_d0
                    newrow[,paste0(Fi,'_','DCT_R.squared1')] <- dct.fit$R2_d1
                    newrow[,paste0(Fi,'_','DCT_R.squared2')] <- dct.fit$R2_d2
                    newrow[,paste0(Fi,'_','DCT_R.squared3')] <- dct.fit$R2_d3
                    newrow[,paste0(Fi,'_','DCT_R.squared4')] <- dct.fit$R2_d4
                    newrow[,paste0(Fi,'_','DCT_R.squared5')] <- dct.fit$R2_d5
                    #newrow[,paste0(Fi,'_','DCT_R.squared')] <- dct.fit$R.squared

                    newrow[,paste0(Fi,'_','C',1:2,'_slope')] <- C_slopes

                    newrow[,paste0(Fi,'_','DCT1tran_R.squared')] <- dcttran[['DCT1']]$R.squared
                    newrow[,paste0(Fi,'_','DCT3tran_R.squared')] <- dcttran[['DCT3']]$R.squared

                    data.fun <- approxfun(all_x, all_y)
                    newrow <- add.value(newrow, Fi, c(20,70,80), data.fun(c(-0.3,0.2,0.3)))
                    newrow <- add.value(newrow, Fi, paste0('DCT',c(20,70,80)), F.dct(c(-0.3,0.2,0.3)))

                }else{
                    #FILL WITH NAS IF THERE ISN'T ENOUGH DATA
                    print(paste('not enough data for',t))
                    for (param in c(coef.names, paste(coef.names,'raw',sep='_'),
                                    'inflection_time','extreme1_time','extreme2_time','extreme1_freq','extreme2_freq',
                                    log.names,'delta','DCT0','DCT1','DCT2','DCT3',
                                    'logistic_energy','logistic_R.squared',
                                    'poly_R.squared0','poly_R.squared1','poly_R.squared2','poly_R.squared',
                                    'DCT_R.squared0','DCT_R.squared1','DCT_R.squared2','DCT_R.squared3','DCT_R.squared4','DCT_R.squared5',
                                    #'DCT_R.squared',
                                    'C1_slope','C2_slope',
                                    'DCT1tran_R.squared','DCT3tran_R.squared',
                                    '20','70','80','DCT20','DCT70','DCT80')){
                        newrow[,paste(Fi,'_',param,sep='')] <- NA
                    }
                }
            }
        }else{
            print(paste('skipping',t))
            newrow <- c()
        }
    }else{
        print(paste('skipping a token without enough rows'))
        t <- NA
        newrow <- c()
    }
    #print (summary(Fs.dct))
    if(plot.contours){
        plotFunctionsForOneToken(token, newrow, probable, formants, f.suffix, ylim, main=paste(t), weights=weights, x_range=x_range, interp_range=x_range, interp_points=length(x_to_fit))  
    }
    newrow
}

findFunctions <- function(d, verbose=FALSE, formants=c('F1','F2','F3'), f.suffix='n_frequency', plot.contours=TRUE, ylim=c(0,6500), weights=NULL, interp_points=21, interp_for_bad=FALSE, exclude_transitions=c(0,1)){
    d.coef <- c()
    ac.sub <- d
    if (!'probable'%in%names(ac.sub)){
        ac.sub$probable <- TRUE
    }

    for (t in unique(ac.sub$token_id)){
        if (!is.na(t) & t!="NA"){
            token <- subset(ac.sub, token_id==t)
            token <- subset(token, abs(normtime) <= 0.5)
            w <- unique(token$word)
            newrow <- findFunctionsForOneToken(token, verbose=verbose, formants=formants, f.suffix, ylim=ylim, plot.contours=plot.contours, weights=weights, 
                                               interp_points=interp_points, interp_for_bad=interp_for_bad, exclude_transitions=exclude_transitions)
            d.coef <- rbind(d.coef, newrow)
        }
    }
    d.coef
}

######

plotParameters <- function(formants=c('F1','F2','F3','F4','F5')){
    coef.names <- c('constant','linear','quadratic','cubic')
    log.names <- c('baseline','peak','crossover','slope','delta')
    plot_parameters <- rbind(data.frame(param1=paste('F1', log.names[c(1,3,1,2,1)], sep='_'), param2=paste('F1', log.names[c(2,4,3,4,5)], sep='_')),
                             data.frame(param1=paste('F2', log.names[c(1,3,1,2,1)], sep='_'), param2=paste('F2', log.names[c(2,4,3,4,5)], sep='_')),
                             data.frame(param1=paste('F3', log.names[c(1,3,1,2,1)], sep='_'), param2=paste('F3', log.names[c(2,4,3,4,5)], sep='_')))
    if ('F4'%in%formants){
        plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F4', log.names[c(1,3,1,2,1)], sep='_'), param2=paste('F4', log.names[c(2,4,3,4,5)], sep='_')))
                             #data.frame(param1=paste('F5', log.names[c(1,3,1,2,1)], sep='_'), param2=paste('F5', log.names[c(2,4,3,4,5)], sep='_')),
    }
    plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F2', log.names, sep='_'), param2=paste('F1', log.names, sep='_')),
                             data.frame(param1=paste('F2', log.names, sep='_'), param2=paste('F3', log.names, sep='_')))
    if ('F4'%in%formants){
        plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F2', log.names, sep='_'), param2=paste('F4', log.names, sep='_')),
                             #data.frame(param1=paste('F2', log.names, sep='_'), param2=paste('F5', log.names, sep='_')),
                             data.frame(param1=paste('F3', log.names, sep='_'), param2=paste('F4', log.names, sep='_')))
                             #data.frame(param1=paste('F3', log.names, sep='_'), param2=paste('F5', log.names, sep='_')),
    }
    plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F1', coef.names[c(1,3,1,2)], sep='_'), param2=paste('F1', coef.names[c(2,4,3,4)], sep='_')),
                             data.frame(param1=paste('F2', coef.names[c(1,3,1,2)], sep='_'), param2=paste('F2', coef.names[c(2,4,3,4)], sep='_')),
                             data.frame(param1=paste('F3', coef.names[c(1,3,1,2)], sep='_'), param2=paste('F3', coef.names[c(2,4,3,4)], sep='_')))
    if ('F4'%in%formants){
        plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F4', coef.names[c(1,3,1,2)], sep='_'), param2=paste('F4', coef.names[c(2,4,3,4)], sep='_')))
                             #data.frame(param1=paste('F5', coef.names[c(1,3,1,2)], sep='_'), param2=paste('F5', coef.names[c(2,4,3,4)], sep='_')),
    }
    plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F2', coef.names, sep='_'), param2=paste('F1', coef.names, sep='_')),
                             data.frame(param1=paste('F2', coef.names, sep='_'), param2=paste('F3', coef.names, sep='_')))
    if ('F4'%in%formants){
        plot_parameters <- rbind(plot_parameters,
                             data.frame(param1=paste('F2', coef.names, sep='_'), param2=paste('F4', coef.names, sep='_')),
                             #data.frame(param1=paste('F2', coef.names, sep='_'), param2=paste('F5', coef.names, sep='_')),
                             data.frame(param1=paste('F3', coef.names, sep='_'), param2=paste('F4', coef.names, sep='_')))#,
                             #data.frame(param1=paste('F3', coef.names, sep='_'), param2=paste('F5', coef.names, sep='_'))#,
                             #data.frame(param1=c('F3_extreme1_freq','F3_extreme1_freq','F3_extreme2_freq'),
                             #           param2=c('F3_extreme2_freq','F3_change','F3_change')),
                             #data.frame(param1=c('duration2','duration2','duration2','duration2','duration2'),
                             #           param2=c('F3_linear','F3_cubic','F3_quadratic','F3_cubic','F3_change'))
    }
                            
    plot_parameters
}

summarizeParameters <- function(d, fun='mean', by.what=''){
    if (by.what=='rhoticity'){
        if (fun=='median'){
            ddply(d, .(phone, rhoticity), summarize, rhoticity=rhoticity[1], phone=phone[1], duration=median(duration),
                  F1_baseline=median(F1_baseline, na.rm=T), F1_peak=median(F1_peak, na.rm=T), F1_crossover=median(F1_crossover, na.rm=T), F1_slope=median(F1_slope, na.rm=T), 
                  F2_baseline=median(F2_baseline, na.rm=T), F2_peak=median(F2_peak, na.rm=T), F2_crossover=median(F2_crossover, na.rm=T), F2_slope=median(F2_slope, na.rm=T), 
                  F3_baseline=median(F3_baseline, na.rm=T), F3_peak=median(F3_peak, na.rm=T), F3_crossover=median(F3_crossover, na.rm=T), F3_slope=median(F3_slope, na.rm=T), 
                  F4_baseline=median(F4_baseline, na.rm=T), F4_peak=median(F4_peak, na.rm=T), F4_crossover=median(F4_crossover, na.rm=T), F4_slope=median(F4_slope, na.rm=T), 
                  F5_baseline=median(F5_baseline, na.rm=T), F5_peak=median(F5_peak, na.rm=T), F5_crossover=median(F5_crossover, na.rm=T), F5_slope=median(F5_slope, na.rm=T))
        }else{
            ddply(d, .(phone, rhoticity), summarize, rhoticity=rhoticity[1], phone=phone[1], duration=mean(duration),
                  F1_baseline=mean(F1_baseline, na.rm=T), F1_peak=mean(F1_peak, na.rm=T), F1_crossover=mean(F1_crossover, na.rm=T), F1_slope=mean(F1_slope, na.rm=T), 
                  F2_baseline=mean(F2_baseline, na.rm=T), F2_peak=mean(F2_peak, na.rm=T), F2_crossover=mean(F2_crossover, na.rm=T), F2_slope=mean(F2_slope, na.rm=T), 
                  F3_baseline=mean(F3_baseline, na.rm=T), F3_peak=mean(F3_peak, na.rm=T), F3_crossover=mean(F3_crossover, na.rm=T), F3_slope=mean(F3_slope, na.rm=T), 
                  F4_baseline=mean(F4_baseline, na.rm=T), F4_peak=mean(F4_peak, na.rm=T), F4_crossover=mean(F4_crossover, na.rm=T), F4_slope=mean(F4_slope, na.rm=T), 
                  F5_baseline=mean(F5_baseline, na.rm=T), F5_peak=mean(F5_peak, na.rm=T), F5_crossover=mean(F5_crossover, na.rm=T), F5_slope=mean(F5_slope, na.rm=T))
        }
    }else if (by.what=='subject'){
        if (fun=='median'){
            ddply(d, .(phone, subject), summarize, #rhoticity=rhoticity[1], 
                                                                            subject=subject[1], phone=phone[1], duration=median(duration),
                  F1_baseline=median(F1_baseline, na.rm=T), F1_peak=median(F1_peak, na.rm=T), F1_crossover=median(F1_crossover, na.rm=T), F1_slope=median(F1_slope, na.rm=T), 
                  F2_baseline=median(F2_baseline, na.rm=T), F2_peak=median(F2_peak, na.rm=T), F2_crossover=median(F2_crossover, na.rm=T), F2_slope=median(F2_slope, na.rm=T), 
                  F3_baseline=median(F3_baseline, na.rm=T), F3_peak=median(F3_peak, na.rm=T), F3_crossover=median(F3_crossover, na.rm=T), F3_slope=median(F3_slope, na.rm=T), 
                  F4_baseline=median(F4_baseline, na.rm=T), F4_peak=median(F4_peak, na.rm=T), F4_crossover=median(F4_crossover, na.rm=T), F4_slope=median(F4_slope, na.rm=T), 
                  F5_baseline=median(F5_baseline, na.rm=T), F5_peak=median(F5_peak, na.rm=T), F5_crossover=median(F5_crossover, na.rm=T), F5_slope=median(F5_slope, na.rm=T))
        }else{
            ddply(d, .(phone, subject), summarize, #rhoticity=rhoticity[1], 
                                                                            subject=subject[1], phone=phone[1], duration=mean(duration),
                  F1_baseline=mean(F1_baseline, na.rm=T), F1_peak=mean(F1_peak, na.rm=T), F1_crossover=mean(F1_crossover, na.rm=T), F1_slope=mean(F1_slope, na.rm=T), 
                  F2_baseline=mean(F2_baseline, na.rm=T), F2_peak=mean(F2_peak, na.rm=T), F2_crossover=mean(F2_crossover, na.rm=T), F2_slope=mean(F2_slope, na.rm=T), 
                  F3_baseline=mean(F3_baseline, na.rm=T), F3_peak=mean(F3_peak, na.rm=T), F3_crossover=mean(F3_crossover, na.rm=T), F3_slope=mean(F3_slope, na.rm=T), 
                  F4_baseline=mean(F4_baseline, na.rm=T), F4_peak=mean(F4_peak, na.rm=T), F4_crossover=mean(F4_crossover, na.rm=T), F4_slope=mean(F4_slope, na.rm=T), 
                  F5_baseline=mean(F5_baseline, na.rm=T), F5_peak=mean(F5_peak, na.rm=T), F5_crossover=mean(F5_crossover, na.rm=T), F5_slope=mean(F5_slope, na.rm=T))
        }
    }else{
        if (fun=='median'){
            ddply(d, .(phone), summarize, phone=phone[1], duration=median(duration),
                  F1_baseline=median(F1_baseline, na.rm=T), F1_peak=median(F1_peak, na.rm=T), F1_crossover=median(F1_crossover, na.rm=T), F1_slope=median(F1_slope, na.rm=T), 
                  F2_baseline=median(F2_baseline, na.rm=T), F2_peak=median(F2_peak, na.rm=T), F2_crossover=median(F2_crossover, na.rm=T), F2_slope=median(F2_slope, na.rm=T), 
                  F3_baseline=median(F3_baseline, na.rm=T), F3_peak=median(F3_peak, na.rm=T), F3_crossover=median(F3_crossover, na.rm=T), F3_slope=median(F3_slope, na.rm=T), 
                  F4_baseline=median(F4_baseline, na.rm=T), F4_peak=median(F4_peak, na.rm=T), F4_crossover=median(F4_crossover, na.rm=T), F4_slope=median(F4_slope, na.rm=T), 
                  F5_baseline=median(F5_baseline, na.rm=T), F5_peak=median(F5_peak, na.rm=T), F5_crossover=median(F5_crossover, na.rm=T), F5_slope=median(F5_slope, na.rm=T))
        }else{
            ddply(d, .(phone), summarize, phone=phone[1], duration=mean(duration),
                  F1_baseline=mean(F1_baseline, na.rm=T), F1_peak=mean(F1_peak, na.rm=T), F1_crossover=mean(F1_crossover, na.rm=T), F1_slope=mean(F1_slope, na.rm=T), 
                  F2_baseline=mean(F2_baseline, na.rm=T), F2_peak=mean(F2_peak, na.rm=T), F2_crossover=mean(F2_crossover, na.rm=T), F2_slope=mean(F2_slope, na.rm=T), 
                  F3_baseline=mean(F3_baseline, na.rm=T), F3_peak=mean(F3_peak, na.rm=T), F3_crossover=mean(F3_crossover, na.rm=T), F3_slope=mean(F3_slope, na.rm=T), 
                  F4_baseline=mean(F4_baseline, na.rm=T), F4_peak=mean(F4_peak, na.rm=T), F4_crossover=mean(F4_crossover, na.rm=T), F4_slope=mean(F4_slope, na.rm=T), 
                  F5_baseline=mean(F5_baseline, na.rm=T), F5_peak=mean(F5_peak, na.rm=T), F5_crossover=mean(F5_crossover, na.rm=T), F5_slope=mean(F5_slope, na.rm=T))
        }
    }
}

get.p.means <- function(data, parameter_names){
    p.means <- c()
    for (pn in parameter_names){
        p.means <- c(p.means, mean(data[,pn], na.rm=T))
    }
    p.means
}

get.p.sweep <- function(data, parameter_names, length.out=10, sds=1){
    expand.grid(baseline =seq(mean(data[,parameter_names[1]],na.rm=T)-sds*sd(data[,parameter_names[1]]),
                              mean(data[,parameter_names[1]],na.rm=T)+sds*sd(data[,parameter_names[1]],na.rm=T),length.out=length.out), 
                 peak    =seq(mean(data[,parameter_names[2]],na.rm=T)-sds*sd(data[,parameter_names[2]],na.rm=T),
                              mean(data[,parameter_names[2]],na.rm=T)+sds*sd(data[,parameter_names[2]],na.rm=T),length.out=length.out), 
                crossover=seq(mean(data[,parameter_names[3]],na.rm=T)-sds*sd(data[,parameter_names[3]],na.rm=T),
                              mean(data[,parameter_names[3]],na.rm=T)+sds*sd(data[,parameter_names[3]],na.rm=T),length.out=length.out),
                 slope   =seq(mean(data[,parameter_names[4]],na.rm=T)-sds*sd(data[,parameter_names[4]],na.rm=T),
                              mean(data[,parameter_names[4]],na.rm=T)+sds*sd(data[,parameter_names[4]],na.rm=T),length.out=length.out))
}

get.ci <- function(p.sweep, mdist.threshold=0.1){
    closest <- p.sweep[with(p.sweep, mdist<mdist.threshold),]
    all.xs <- c()
    all.ys <- c()
    for (row in 1:nrow(closest)){
        F.logistic <- function(x){
            logistic(x, as.numeric(closest[row,1:4]))
        }
        xs <- seq(-0.5,0.5,length.out=50)
        all.xs <- c(all.xs, xs)
        all.ys <- c(all.ys, F.logistic(xs))
    }
    F.mins <- aggregate(all.ys ~ all.xs, FUN=min)
    F.maxs <- aggregate(all.ys ~ all.xs, FUN=max)
    F.envelope <- cbind(F.mins, F.maxs[,2])
    names(F.envelope) <- c('x', 'min', 'max')
    F.envelope
}

#NEW


wordIDfromTokenID <- function(token_id){
    paste(unlist(strsplit(paste(token_id), '_'))[1:3], collapse='_')
}


#
#
#
#
#

# improved list of objects
.ls.objects <- function (pos = 1, pattern, order.by,
                        decreasing=FALSE, head=FALSE, n=5) {
    napply <- function(names, fn) sapply(names, function(x)
                                         fn(get(x, pos = pos)))
    names <- ls(pos = pos, pattern = pattern)
    obj.class <- napply(names, function(x) as.character(class(x))[1])
    obj.mode <- napply(names, mode)
    obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
    obj.size <- napply(names, object.size)
    obj.dim <- t(napply(names, function(x)
                        as.numeric(dim(x))[1:2]))
    vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
    obj.dim[vec, 1] <- napply(names, length)[vec]
    out <- data.frame(obj.type, obj.size, obj.dim)
    names(out) <- c("Type", "Size", "Rows", "Columns")
    if (!missing(order.by))
        out <- out[order(out[[order.by]], decreasing=decreasing), ]
    if (head)
        out <- head(out, n)
    out
}
# shorthand
lsos <- function(..., n=10) {
    .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
}

fit.contour.functions <- function(contour.data){
    all.coef <- c()
    for (s in speakers){
        cairo_pdf(paste(writepath,'contours_for_',s,'.pdf',sep=''), h=5, w=5, onefile=T)
        #plot.data <- subset(contour.data, subject==s & mdist<mdist.cutoff)
        plot.data <- subset(contour.data, subject==s)
        plot.data <- plot.data[with(plot.data, order(phone, token_id, time)),] 
        for (p in unique(plot.data$phone)){
            subdata <- subset(plot.data, phone==p)
            subdata$right0 <- factor(subdata$right0)
            for (pp in rev(c('#','P','T','K','B','D','G','M','N','NG','CH','JH','TH','F','S','SH','V','Z','L','R',
                             'IY1','IY0','IH1','EY1','EH1','EH2','AE1','AH0','ER1','ER0','AA1','OW1','UW1'))){
                if (pp%in%levels(subdata$right0)){
                    subdata$right0 <- relevel(subdata$right0, pp)
                }
            }
            for (r0 in levels(subdata$right0)){
                subsubdata <- subset(subdata, right0==r0)
                data.coef <- findFunctions(subset(subsubdata, probable), formants=formants, plot.contours=TRUE, weights='mdist.weight')
                all.coef <- rbind(all.coef, data.coef)
            }
        }
        dev.off()
    }
    all.coef$phone <- sortVowelFactor(all.coef$phone, add_missing=FALSE, target_phones, language='English')
    all.coef
}

mergeVL <- function(s.data){
    s.data <- s.data[order(s.data$phonestart),]
    preliquid_vowels <- which(with(s.data, phone%in%p2fa_vowels & right0%in%c('R','L') & !right1%in%p2fa_vowels))
    postvocalic_liquids <- preliquid_vowels+1
    for (v in preliquid_vowels){
        old.v <- s.data[v,]
        old.l <- s.data[v+1,]
        new.vl <- old.v
        new.vl[,c('phoneend','right0','right1')] <- old.l[,c('phoneend','right0','right1')]
        new.vl$phone <- paste0(old.v$phone, old.l$phone)
        s.data[v,] <- new.vl
    }
    s.data <- s.data[-postvocalic_liquids,]
    s.data
}

mergeAllVL <- function(all.data){
    for (s in names(all.data$segments)){
        s.data <- all.data$segments[[s]]
        s.data <- mergeVL(s.data)
        all.data$segments[[s]] <- s.data
    }
    all.data
}


