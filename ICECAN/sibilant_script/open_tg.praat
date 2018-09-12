form Open a tgwav
	sentence tg_path /Volumes/data/corpora/Raleigh/ral368/ral3680d.TextGrid
	sentence wav_path /Volumes/data/corpora/Raleigh/ral368/ral3680d.wav
	positive start 1494.81
	positive end 1494.91
endform
tg = Read from file: tg_path$
wav = Read from file: wav_path$
selectObject: wav
plusObject: tg

View & Edit
Insert interval tier... '5' 'sib_ann'
editor: tg
	
	#Insert boundary... '5' start 
	#Insert boundary... '5' end 
	Zoom: start, end
endeditor