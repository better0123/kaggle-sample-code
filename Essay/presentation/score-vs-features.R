# score-vs-features.R
# 
# plots whisker plots of essay score vs features

library(ggplot2)
source("multiplot.R")

TRAINING_FILE <- "/home/chefele/kaggle/Essay/download/release_3/training_set_rel3.tsv"
FEATURES_FILE <- "/home/chefele/kaggle/Essay/rf/data/all_features_2012-04-03.csv"
PLOT_FILE     <- "score-vs-features.pdf"

pdf(file=PLOT_FILE)

features   <- read.csv(FEATURES_FILE)
training   <- read.delim(TRAINING_FILE, quote="")

essay_sets <- sort(unique(features$essay_set))

for(feature in names(features)) {
    
    plotlist <- list()

    for(essay_set in essay_sets) {

        essay.score  <- training[training$essay_set == essay_set, 'domain1_score']
        feat.value   <- features[features$essay_set == essay_set, feature]
        df <- data.frame(x=factor(essay.score), y=feat.value)

        plot.title       <- paste("Score vs", feature, "for Essay set", essay_set)
        plot.title.short <- paste("Essay Set", essay_set)
        cat(plot.title, "\n")

        plt <- ggplot(df, aes(x, y)) + 
               geom_boxplot() + 
               coord_flip() + 
               xlab("Essay Score") +
               ylab(feature) + 
               ggtitle(plot.title.short)

        plotlist[[essay_set]] <- plt
        # print(plt)

    }
    multiplot(plotlist=plotlist, cols=3)
}


