# read in file info
form Open a tgwav
	sentence Tg_path /Volumes/data/corpora/Raleigh/ral368/ral3680d.TextGrid
	sentence Wav_path /Volumes/data/corpora/Raleigh/ral368/ral3680d.wav
	positive Start 1494.81
	positive End 1494.91
	positive Cog 0.0
	positive Peak 0.0
	positive Slope 0.0
	positive Spread 0.0
endform

# load files 
tg = Read from file: tg_path$
wav = Read from file: wav_path$

# select objects
selectObject: wav
plusObject: tg
grid$ = selected$ ("TextGrid")
sound$ = selected$ ("Sound") 

# add annotation tier and boundaries
select TextGrid 'grid$'
numberOfTiers = Get number of tiers

Edit
editor TextGrid 'grid$'
	Add interval tier... numberOfTiers+1 sibann
	Close
endeditor

Insert boundary... numberOfTiers+1 start
Insert boundary... numberOfTiers+1 end

plus Sound 'sound$'
# zoom in on focused part
View & Edit
editor TextGrid 'grid$'
	Zoom: start, end
endeditor


select Sound 'sound$'
Edit
editor Sound 'sound$'
	Zoom: start, end
	Select: start, end
endeditor

writeInfoLine: "COG: ", cog
appendInfoLine: "Peak: ", peak
appendInfoLine: "Slope: ", slope
appendInfoLine: "Spread: ", spread



