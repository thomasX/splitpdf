# splitpdf
unix shell script   split a pdf by barcode with regex pattern 


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
     echo '###############################################################################'A
     
     
     tested with ubuntu 14.04 LTS
     
