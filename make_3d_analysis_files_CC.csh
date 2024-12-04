#!/bin/csh
#
## Project : Colorado Snowstorm 2003
#
## Purpose : Make subset of CONUS404 output files. Resulting files contain only a set of select
#           variables.
#
# Usage : ./make_3d_analysis_files.csh YYYY MM
# 
#
# Last modified : Meghan Stell 2024
#
#
#module load nco
#module load netcdf
#module load ncl
#
#-----------------------------------------------------------------------------------------------
# Arguments
#-----------------------------------------------------------------------------------------------
#set  YYYY = ${argv[1]}
#set  MM   = ${argv[2]}
#if (($MM>5) && ($MM<10)) then
#    goto DONE
#endif
#              
#-----------------------------------------------------------------------------------------------
# Format YYYY and MM
#-----------------------------------------------------------------------------------------------
#set MM = `echo ${MM} | bc`
#set MM = `printf %02d ${MM}`
#set YYYY = `echo ${YYYY} | bc`
#set YYYY = `printf %04d ${YYYY}`
                   
#set INDIR3D = "/glade/campaign/collections/rda/data/d559000/wy${YYYY}/*${MM}/"
set INDIR3D = "/glade/derecho/scratch/meghan/Colorado/data"
set outdir  = "/glade/derecho/scratch/meghan/Colorado/data/CONUS404/Colorado"
set CONST   = "/glade/campaign/ncar/USGS_Water/CONUS404/wrfconstants_d01_1979-10-01_00:00:00.nc4"
#-----------------------------------------------------------------------------------------------
# List of variables to save
#-----------------------------------------------------------------------------------------------
#
set var3d = "Time,P,TK,W,Z,U,V,XTIME,QVAPOR,REFL_10CM"
set varConst  = "XLAT,XLONG,HGT,SINALPHA,COSALPHA"
set var2d     = "MLCAPE,MLCINH,MLLCL,MUCAPE,PREC_ACC_NC,PSFC,PWAT,QVAPOR,REFL_10CM,REFL_COM,SNOW,SNOW_ACC_NC,SRH03,T2,TD2,TH2,U10,USHR1,V10,VSHR1,XTIME,Z,Time"

#----- bounds -------#
#(430,452) (604,575)
set ilonLL = 430
set ilonUR = 604
set ilonUR_stag = 605
set jlatLL = 452
set jlatUR = 575
set jlatUR_stag = 576
#
#-----------------------------------------------------------------------------------------------
# Save variables :
#-----------------------------------------------------------------------------------------------
#
#----- 3D Hourly Files --------#
set INPUT_FILE_MASTER = `/bin/ls -1 ${INDIR3D}/wrf3d*`
foreach infile ( ${INPUT_FILE_MASTER} )
#set outfile = `echo ${infile} | awk -F'/' '{print $NF}'`
set outfile = `basename ${infile}`
set outfile = "${outdir}/3D/${outfile}"

if ( -e ${outfile} ) then
echo " ... output already exists. Moving on to the next file."
goto NEXT3D
endif

echo " .... 3D input file : ${infile}"
echo " .... output file   : ${outfile}"

ncks -h -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -v${var3d} ${infile} ${outfile}
ncks -h -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east_stag,${ilonLL},${ilonUR_stag} -vU ${infile} ${outfile}
ncks -h -A -dsouth_north_stag,${jlatLL},${jlatUR_stag} -dwest_east,${ilonLL},${ilonUR} -vV ${infile} ${outfile}

# remove global atts
ncatted -O -a,global,d,, ${outfile} ${outfile}
#----------------- Compress file -----------------------#
ncks -O -4 -L 1 ${outfile} ${outfile}
NEXT3D:
end

#----- 2D Hourly Files --------#
set INPUT_FILE_MASTER = `/bin/ls -1 ${INDIR3D}/wrf2d*`
foreach infile ( ${INPUT_FILE_MASTER} )
#set outfile = `echo ${infile} | awk -F'/' '{print $NF}'`
set outfile = `basename ${infile}`
set outfile = "${outdir}/2D/${outfile}"

if ( -e ${outfile} ) then
echo " ... output already exists. Moving on to the next file."
goto NEXT2D
endif

echo " .... 2D input file : ${infile}"
echo " .... output file   : ${outfile}"

ncks -h -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -v${var2d} ${infile} ${outfile}

# remove global atts
ncatted -O -a,global,d,, ${outfile} ${outfile}
#----------------- Compress file -----------------------#
ncks -O -4 -L 1 ${outfile} ${outfile}
NEXT2D:
end

#-----------------------------------------------------------------------------------------------
DONE:
echo "----------------------------- END ------------------------------"
exit 0     

ERROR: 
exit 1
