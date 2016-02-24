oddcount <- function(x) {
	xOdd <- x[x%%2==1]
	return(list(odds=xOdd, numOdds=length(xOdd)))
}