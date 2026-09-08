# Run with Rscript against an installed ffanalytics build. No provider requests.
Sys.setenv(R_USER_CACHE_DIR = tempfile('ffanalytics-cache-test-'))
suppressPackageStartupMessages(library(ffanalytics))
ns <- asNamespace('ffanalytics')
original_clear <- get('clear_ffanalytics_cache', ns)
sources <- c(CBS='cbs', NFL='nfl', FantasySharks='fantasysharks',
             NumberFire='numberfire', WalterFootball='walterfootball', FleaFlicker='fleaflicker')
for (src in names(sources)) {
  fixture <- list(TE=data.frame(id='17699',player='Dallen Bentley',pos='TE',
                               data_src=src,rec_yds=104,rec=12,rec_tds=1))
  attr(fixture,'season') <- 2026L
  attr(fixture,'week') <- 0L
  for (scenario in c('same','week','season','missing','provider','position')) {
    original_clear()
    candidate <- fixture
    requested_week <- 0L
    requested_season <- 2026L
    if (scenario=='week') requested_week <- 1L
    if (scenario=='season') requested_season <- 2027L
    if (scenario=='missing') attr(candidate,'week') <- NULL
    if (scenario=='provider') candidate$TE$data_src <- 'wrong-source'
    if (scenario=='position') names(candidate) <- 'RB'
    ffanalytics:::cache_object(candidate,paste0(sources[[src]],'_scrape.rds'))
    missed <- FALSE
    assignInNamespace('clear_ffanalytics_cache',function(...) {
      missed <<- TRUE
      original_clear(...)
      stop('test stops before provider request')
    },ns='ffanalytics')
    # Exercise the normal orchestration (NumberFire alias and season-only
    # sources require their own adapter entry point).
    if (src %in% c('NumberFire','WalterFootball') ||
        (src=='FleaFlicker' && requested_week==0L)) {
      result <- try(do.call(get(paste0('scrape_',sources[[src]]),ns),
                           list(pos='TE',season=requested_season,week=requested_week)),silent=TRUE)
    } else {
      result <- scrape_data(src=src,pos='TE',season=requested_season,week=requested_week)
    }
    assignInNamespace('clear_ffanalytics_cache',original_clear,ns='ffanalytics')
    stopifnot(identical(missed, scenario!='same'))
    if(scenario=='same') stopifnot(result$TE$rec_yds==104)
    if(scenario!='same') {
      file_name <- paste0(sources[[src]],'_scrape.rds')
      stopifnot(!file.exists(file.path(tools::R_user_dir('ffanalytics','cache'),file_name)))
      ffanalytics:::cache_object(fixture,file_name)
      stopifnot(identical(ffanalytics:::get_cached_object(file_name),fixture))
    }
  }
}
# Week-to-week and ROS identity cannot alias one another.
f <- fixture
attr(f,'week') <- 1L
stopifnot(ffanalytics:::projection_cache_matches(f,2026,1,'FleaFlicker'))
stopifnot(!ffanalytics:::projection_cache_matches(f,2026,2,'FleaFlicker'))
stopifnot(!ffanalytics:::projection_cache_matches(f,2026,'ros','FleaFlicker'))
cat('PASS: 36 adapter cache scenarios plus week/ROS checks\n')
