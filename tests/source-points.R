suppressPackageStartupMessages(library(ffanalytics))
x <- list(TE=data.frame(pos='TE',data_src='CBS',id='17699',rec_yds=c(10,20),rec=c(1,2)),
          DST=data.frame(pos='DST',data_src='CBS',id=c('0800','0900'),dst_pts_allowed=c(10,20),dst_sacks=c(1,2)))
attr(x,'season') <- 2026L
attr(x,'week') <- 1L
stopifnot(identical(source_points(x),source_points(x,scoring_rules=scoring)))
stopifnot(identical(source_points(x,NULL),source_points(x,scoring_rules=scoring)))
cat('PASS: omitted and explicit NULL scoring rules match default scoring\n')
