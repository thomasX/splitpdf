#!/bin/sh
#set -x
#pdf splitting script by t.margreiter
# used resources: pdftk, pdftoppm, exactimage
#########################################################################################
### subroutine display usage ### 
display_usage() {
     echo '###############################################################################'
     echo '# splitpdf is a pdf splitting tool                                            #'
     echo '# author: t.margreiter  2015-04-20                                            #'
     echo '# used libraries:  pdftk, pdftoppm, exactimage , zbar-tools                   #'
     echo '#                                                                             #'
     echo '# usage:                                                                      #'
     echo '# splitpdf inputfile.pdf outputdir barcodetype identifier maxlength           #'
     echo '#                                                                             #'
     echo '# allowed barcode typs: [code39,code128]                                      #'
     echo '# barcode definition: we use barcode of the following format:                 #'
     echo '#          identifier/barcodevalue/                                           #'
     echo '#   example: DMS/MEINBARCODE/                                                 #'
     echo '#            DMS=identifier     MEINBARCODE = value                           #' 
     echo '#            regex example: /^DMS\/[^\/]{1-30}\/$/                            #'
     echo '#                                                                             #'
     echo '#                                                                             #'
     echo '###############################################################################'
}
#########################################################################################

#########################################################################################
#function getTypeHeader returns the Bar-Code Typeheader 
#parameter: $1 barcode
getTypeHeader() {
  header='CODE-undefined'
  if [ "$1" = "code39" ]; then header="CODE-39:" ; fi 
  if [ "$1" = "code128" ]; then  header="CODE-128:" ; fi 
 # the following codes are untested ... so we don't know the code-header
 # if [ "$1" = "ean13" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "ean8" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "upca" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "upce" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "isbn13" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "isbn10" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "i25" ]; then header="CODE-128" ; fi 
 # if [ "$1" = "pdf417" ]; then header="CODE-128" ; fi 
  echo $header
}
#########################################################################################

#########################################################################################
#function ORGgetBarcodeFromPage returns teh first valid barcode on the page or an empty string 
#parameter: sourcepdf pagenumber splitpdffilename scancommand 
getORGBarcodeFromPage(){
   src=$1;
   pgnr=$2;
   splitf=$3;
   sc=$4;
   MYRES="";
   pdftk $1 cat $2 output $3
   pdftoppm -rx 300 -ry 300 -jpeg $3 split
   ##   ge is on split-1.jpg
   barResult=$(eval $4)
   if [ ! -z "$barResult" ] ; then 
        bnr=0;
        printf %s "$barResult" | while IFS= read -r line 
        do 
          bnr=$(expr $bnr + 1)
          if [ $bnr -eq 1 ] ; then 
             echo "$line";
          fi
	done	
   fi
   #echo $barResult
}
#########################################################################################
#########################################################################################
#function getBarcodeFromPage returns teh first valid barcode on the page or an empty string 
#parameter: sourcepdf pagenumber splitpdffilename scancommand 
getBarcodeFromPage(){
   src=$1;
   pgnr=$2;
   splitf=$3;
   sc=$4;
   pdftk $1 cat $2 output $3
   pdftoppm -rx 300 -ry 300 -jpeg $3 split
   ## seite liegt auf split-1.jpg
   barResult=$(eval $4)
   echo "$barResult" 
}
#########################################################################################

#########################################################################################
# function : exportSplitpdf "$srcpdf" "$startpage" "$lpage" "$currentOutputFilename" 
# parameter: "$srcpdf" "$startpage" "$lpage" "$currentOutputFilename" 
exportSplitpdf(){
  exportcommand=$(echo "pdftk $1 cat $2"-"$3 output $4")
  eval "$exportcommand";
}
#########################################################################################

#########################################################################################
# function:createOutputFilename
# parameter:  $curBarcode $identifier $outputdir 
# returns: outputfilename
createOutputFilename(){
        sedcommand=$(echo "echo -n $1 | sed -e 's/^$2\///' | sed -e 's/\///'")
	barValue=$(eval $sedcommand)
	regularFileName=$(echo -n $barValue | tr -c 'a-zA-Z0-9\-' '_')
	exportFile=$(echo -n "$3"/"$regularFileName".pdf)
	echo "$exportFile"
}
#########################################################################################

#########################################################################################
#########################################################################################
if [ ! $# -eq 5 ]; then 
    echo ' wrong number of parameters ! '
    display_usage
    exit 0
fi
inputfile=$1
outputdir=$2
barcodeType=$3
identifier=$4 
maxlength=$5 
barcodePattern=$(echo '^'"$4"'/[^/]{1,'"$5"}'/$')
barcodeTypeHeader=$(getTypeHeader $barcodeType)
tempdir=$(/bin/mktemp -d /scandata/tempDir/splitDir_XXXXXXXXXXXXXXXX)
cd $tempdir
srcpdf=$tempdir/srcpdf.pdf
currentOutputFilename=$(basename "$inputfile")
echo "splitting $inputfile" >> /var/log/syslog
/bin/mv $inputfile $srcpdf
totalpages=$(pdfinfo $srcpdf | grep Pages | awk '{print $2}')
startpage=1
currentPage=0
currentOutputFilename=$(echo "$outputdir"/"$currentOutputFilename")
scancommand=$(echo "zbarimg -q -Sdisable -S$barcodeType"."enable split-1.jpg | grep -E '^$barcodeTypeHeader' | sed -e 's/^$barcodeTypeHeader//' | grep -E -m 1 '$barcodePattern' " )
splitpdf=$tempdir/split.pdf
echo -n " $inputfile : $totalpages "
while [ $currentPage -lt $totalpages ]
do 
   currentPage=$(($currentPage+1))
   curBarcode='';
   curBarcode=$(getBarcodeFromPage "$srcpdf" "$currentPage" "$splitpdf" "$scancommand" )
   echo "page: $currentPage  barcode: $curBarcode" >> /var/log/syslog
   echo -n "."
   if [ -n "$curBarcode" ] ; then 
          lpage=$(($currentPage -1));
          if [ $lpage -gt 0 ] ; then 
            exportSplitpdf "$srcpdf" "$startpage" "$lpage" "$currentOutputFilename" 
          fi
          startpage=$currentPage;
          currentOutputFilename=$(createOutputFilename "$curBarcode" "$identifier" "$outputdir")
   fi
done
exportSplitpdf "$srcpdf" "$startpage" "$currentPage" "$currentOutputFilename" 
cd /home
/bin/rm -Rf $tempdir

