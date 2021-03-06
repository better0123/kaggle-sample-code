
# --- configurable constants

PLOTFILE <- "pca_100_training.pdf"

#load(file="/home/chefele/AlgoTrading/data/probe.Rsave")
#dat.all <- probe
load(file="/home/chefele/AlgoTrading/data/training.Rsave")
dat.all <- training

pre.tperiods  <- 1:50
post.tperiods <- 51:100
all.tperiods  <- 1:100
event.tperiod <- 49
nearevent.tperiods <- 40:59

# --- internal constants 

mkNames   <- function(ask.or.bid, periods) { paste(ask.or.bid, as.character(periods),sep="") }
pre.bids  <- mkNames("bid", pre.tperiods)
pre.asks  <- mkNames("ask", pre.tperiods)
post.bids <- mkNames("bid", post.tperiods)
post.asks <- mkNames("ask", post.tperiods)
all.bids  <- mkNames("bid", all.tperiods)
all.asks  <- mkNames("ask", all.tperiods)

security_ids <- sort(unique(dat.all$security_id))
initiators   <- sort(unique(dat.all$initiator))

# --- plotting functions

# Create plots of bids, asks, midspread & spread vs time period
plotNormAvgsVsTime <- function(in.dat, in.tag, twindow) { 

    asks      <- (colMeans( cbind(in.dat[all.asks]) ))[twindow] # (instances) x (100 timeperiods )
    bids      <- (colMeans( cbind(in.dat[all.bids]) ))[twindow] 
    midspread <- ((asks+bids)/2.0)
    spread    <- (asks - bids)
    mean.vwap <- (mean(in.dat$trade_vwap))
    
    # plot bids, asks, mid-spread vs time
    plot(twindow, asks, main=in.tag, type="b", 
         xlab="Time Period", ylab="Average Price", 
         ylim=c(min(asks,bids), max(asks,bids))
    )
    lines(twindow, bids,      type="b", lty="dashed")
    lines(twindow, midspread, type="l", lty="solid" ) 
    abline(v=event.tperiod, lty="dotted")
    abline(h=mean.vwap,     lty="dotted")

    # plot spread vs time
    plot(twindow, spread, main=in.tag, type="b", 
         xlab="Time Period", ylab="Avg Spread", 
         ylim=c(min(spread), max(spread))
    )
    abline(v=event.tperiod, lty="dotted")
}


# Take a PCA of the concatenated bid/ask prices vs time & 
# then plot the first 3 principal componenets vs time plus the scree
plotPrCompVsTime <- function(in.dat, in.tag) { 
    N_PCS <- 99 # number of principal components to plot
    asks1 <- cbind(in.dat[post.asks])  # 1 row/event, cols are time periods
    bids1 <- cbind(in.dat[post.bids])  
    asks.bids <- t(as.matrix(cbind(asks1, bids1)))  # now rows=time, cols=events  

    prcomp.asks.bids <- prcomp(asks.bids, center=TRUE, scale=TRUE)
    print(summary(prcomp.asks.bids))
    plot(prcomp.asks.bids, main="Asks&Bids Principal Components Scree")

    pcs <- prcomp.asks.bids$x
    asks.pcs <- pcs[1 : ncol(asks1), ]
    bids.pcs <- pcs[ (ncol(asks1)+1) : (ncol(asks1)+ncol(bids1)) , ]  

    for(col_name in colnames(pcs)[1:N_PCS]) {
        plot(post.tperiods,  asks.pcs[,col_name], 
             main= paste(col_name, in.tag), 
             type="l", 
             xlab="Time Period", ylab="PC Magnitude", 
             ylim=c(min(asks.pcs,bids.pcs), max(asks.pcs,bids.pcs))
        )
        lines(post.tperiods, bids.pcs[,col_name], type="l", lty="solid")
    }
    abline(v=event.tperiod, lty="dotted")
}


# --- main()

print("Now plotting bid/ask/spread time series & PCA components")
pdf(file=PLOTFILE)
par(mfrow=c(4,4)) # 2x2 matrix of plots 

#first do processing on ALL data, broken down by buys/sells
for(initiator in initiators) {
    print("Subsetting data")
    initiator.mask <- dat.all$initiator == initiator
    dat <-  dat.all[ initiator.mask ,] 
    tag <-  paste("security_id: ALL", "initiator:", initiator)
    print(paste("PROCESSING ", tag, "rows:", as.character(nrow(dat)) ))

    #print("Starting overall plots")
    #plotNormAvgsVsTime(dat, tag, all.tperiods)
    #plotNormAvgsVsTime(dat, tag, nearevent.tperiods) # close-up around event

    print("Starting overall PCA")
    plotPrCompVsTime(dat, tag) 
}

stop()

# now do processing on each stock individually, broken down by buys/sells
for(initiator in initiators) {
    initiator.mask <- dat.all$initiator == initiator
    for(security_id in security_ids) {
        security_id.mask <- dat.all$security_id == security_id
        dat <-  dat.all[ initiator.mask & security_id.mask ,] 
        tag <-  paste("security_id:", security_id, "initiator:", initiator)
        print(paste("PROCESSING ", tag, "rows:", as.character(nrow(dat)) ))

        plotNormAvgsVsTime(dat, tag, all.tperiods)
        plotNormAvgsVsTime(dat, tag, nearevent.tperiods) # close-up around event
        plotPrCompVsTime(  dat, tag) 
    }
}


# TODO / Future work: 
# plot for t51-t100, x= %tradeSize, y=avg of asks/vwap, avg of bids/vwap, avg of midpts/vwap, avg of spreads/vwap
# plot mean t1-50 / mean t51-100 vs normalized trade size

