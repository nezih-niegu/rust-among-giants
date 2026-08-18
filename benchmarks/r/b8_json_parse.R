# B8: JSON node counting matching cJSON (objects '{', arrays '[', string VALUES
# only — a string before ':' is a key — numbers, true/false, null). Scans bytes;
# slow tier on 100 MB but exact.
args <- commandArgs(trailingOnly=TRUE)
fname <- if (length(args) >= 1) args[1] else "../../data/json_input.json"
sz <- file.info(fname)$size
txt <- readChar(fname, sz, useBytes=TRUE)
b <- charToRaw(txt)
n <- length(b)
QUOTE<-as.raw(34); BSL<-as.raw(92); COLON<-as.raw(58)
OB<-as.raw(123); OA<-as.raw(91); SP<-as.raw(32); TAB<-as.raw(9); NL<-as.raw(10); CR<-as.raw(13)
obj<-0;arr<-0;strv<-0;num<-0;boo<-0;nul<-0
i <- 1L
isdig <- function(r) r >= as.raw(48) & r <= as.raw(57)
while (i <= n) {
  c <- b[i]
  if (c == OB) { obj<-obj+1; i<-i+1L }
  else if (c == OA) { arr<-arr+1; i<-i+1L }
  else if (c == QUOTE) {
    j <- i+1L
    while (j <= n) {
      if (b[j]==BSL) { j<-j+2L; next }
      if (b[j]==QUOTE) break
      j<-j+1L
    }
    k <- j+1L
    while (k <= n && (b[k]==SP||b[k]==TAB||b[k]==NL||b[k]==CR)) k<-k+1L
    if (k <= n && b[k]==COLON) {} else strv<-strv+1
    i <- j+1L
  }
  else if (c == as.raw(116)) { if (i+3L<=n && rawToChar(b[i:(i+3L)])=="true"){boo<-boo+1;i<-i+4L}else i<-i+1L }
  else if (c == as.raw(102)) { if (i+4L<=n && rawToChar(b[i:(i+4L)])=="false"){boo<-boo+1;i<-i+5L}else i<-i+1L }
  else if (c == as.raw(110)) { if (i+3L<=n && rawToChar(b[i:(i+3L)])=="null"){nul<-nul+1;i<-i+4L}else i<-i+1L }
  else if (c == as.raw(45) || isdig(c)) {
    j <- i+1L
    while (j <= n) {
      cc <- b[j]
      if (isdig(cc)||cc==as.raw(46)||cc==as.raw(101)||cc==as.raw(69)||cc==as.raw(43)||cc==as.raw(45)) j<-j+1L else break
    }
    num<-num+1; i<-j
  } else i<-i+1L
}
cat(sprintf("objects=%.0f arrays=%.0f strings=%.0f numbers=%.0f bools=%.0f nulls=%.0f\n",
            obj,arr,strv,num,boo,nul))
