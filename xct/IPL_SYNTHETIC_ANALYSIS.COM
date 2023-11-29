$! ---------
$! Constants
$! ---------
$ GRID_X = 200
$ GRID_Y = 200
$ GRID_Z = 100
$!
$! -----------------
$! Get the Arguments
$! -----------------
$!
$ FILENAME = F$PARSE("''P1'",,,"NAME")
$ DEV      = F$PARSE("''P1'",,,"DEVICE")
$ DIR      = F$PARSE("''P1'",,,"DIRECTORY")
$!
$ TRAB_RADIUS = P2
$ GRID_SPACING = P3
$!
$ SEG_AIM := 'DEV''DIR''FILENAME'_'P2'_'P3'.AIM
$ SEG_AIM_TH := 'DEV''DIR''FILENAME'_'P2'_'P3'_TH.AIM
$ SEG_AIM_SP := 'DEV''DIR''FILENAME'_'P2'_'P3'_SP.AIM
$ SEG_AIM_1N := 'DEV''DIR''FILENAME'_'P2'_'P3'_1N.AIM
$ SEG_AIM_TMP := 'DEV''DIR''FILENAME'_'P2'_'P3'_TMP.AIM
$!
$! -----------------------------
$! Output parameters to log file
$! -----------------------------
$!
$ WRITE SYS$OUTPUT "Trabeculae radius: "+TRAB_RADIUS
$ WRITE SYS$OUTPUT "Grid spacing: "+GRID_SPACING
$!
$ WRITE SYS$OUTPUT "SEG AIM filename: "+SEG_AIM
$ WRITE SYS$OUTPUT "Tb.Th AIM filename: "+SEG_AIM_TH
$ WRITE SYS$OUTPUT "Tb.Sp AIM filename: "+SEG_AIM_SP
$ WRITE SYS$OUTPUT "1 / Tb.N AIM filename: "+SEG_AIM_N
$ WRITE SYS$OUTPUT "SEG AIM temp filename: "+SEG_AIM_TMP
$!
$! -----------------
$! Create the canvas
$! -----------------
$!
$ IPL_BATCH

/db off

/create_canvas
  -output aim
  -dim "GRID_X "GRID_Y "GRID_Z
  -off 0 0 0
  -pos 0 0 0
  -el_size_mm 1 1 1
  -type char

/write
  -name aim
  -filename "SEG_AIM_TMP
  -compress_type bin
  -version_020 true

..
$!
$! --------------
$! Add trabeculae
$! --------------
$!
$ i = GRID_SPACING / 2
$ loop_i:
$ j = GRID_SPACING / 2
$ loop_j:
$ IPL_BATCH

/db off

/read aim "SEG_AIM_TMP

/cr_cylinder
  -input_output aim
  -center "i "j 0
  -radius "TRAB_RADIUS
  -length "GRID_Z
  -value 127
  -mode 0

/write
  -name aim
  -filename "SEG_AIM_TMP
  -compress_type bin
  -version_020 true

..
$ j = j + GRID_SPACING
$ if j .LT. GRID_Y then goto loop_j
$ i = i + GRID_SPACING
$ if i .LT. GRID_X then goto loop_i
$!
$! ----------------------------------------------
$! Rename the final version and delete temp files
$! ----------------------------------------------
$!
$!
$ RENAME 'SEG_AIM_TMP' 'SEG_AIM'
$ DEL 'SEG_AIM_TMP';*
$!
$! --------
$! Analyze
$! --------
$!
$ WRITE SYS$OUTPUT "Calculating Tb.Th, Tb.Sp, Tb.N, Tb.BV/TV"
$!
$ IPL_BATCH

/db off

/read aim "SEG_AIM

/dt_thickness
  -input aim
  -output tb_th
  -peel_iter -1
  -ridge_epsilon 0.9
  -assign_epsilon 0.5
  -histofile_or_screen none
  -suppress_boundary 2
  -version 3

/write
  -name tb_th
  -filename "SEG_AIM_TH
  -compress_type bin
  -version_020 true

/dt_spacing
  -input aim
  -output tb_sp
  -peel_iter -1
  -ridge_epsilon 0.9
  -assign_epsilon 0.5
  -histofile_or_screen none
  -suppress_boundary 2
  -version 3

/write
  -name tb_sp
  -filename "SEG_AIM_SP
  -compress_type bin
  -version_020 true

/dt_number
  -input aim
  -output tb_1n
  -peel_iter -1
  -ridge_epsilon 0.9
  -assign_epsilon 0.5
  -histofile_or_screen none
  -suppress_boundary 2
  -version 3

/write
  -name tb_1n
  -filename "SEG_AIM_1N
  -compress_type bin
  -version_020 true

/vox_scanco_param
  -input aim

..
$!
$ EXIT
$!