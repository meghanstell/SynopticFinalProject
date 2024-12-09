#!/bin/bash
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

## ANSI escape codes for colorful logging
RED="\x1b[;31m"
GREEN="\x1b[;32m"
YELLOW="\x1b[;33m"
BLUE="\x1b[;34m"
MAGENTA="\x1b[;35m"
CYAN="\x1b[;36m"
WHITE="\x1b[;37m"
RESET="\x1b[;0m"


function _info(){
    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${CYAN}INFO${RESET}    :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

function _warn(){
    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${YELLOW}WARNING${RESET} :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

function _error(){
    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${RED}ERROR${RESET}   :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

function _success(){
    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${GREEN}SUCCESS${RESET} :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

# INDIR3D="/glade/derecho/scratch/meghan/Colorado/data"
INDIR3D="/glade/derecho/scratch/meghan/Colorado/data/orig"
# outdir="/glade/derecho/scratch/meghan/Colorado/data/CONUS404/CONUS/stag"
outdir="/glade/derecho/scratch/meghan/Colorado/data/CONUS404/CONUS/sv"
# CONST="/glade/campaign/ncar/USGS_Water/CONUS404/wrfconstants_d01_1979-10-01_00:00:00.nc4"
CONST="/glade/campaign/collections/rda/data/d559000/INVARIANT/wrfconstants_usgs404.nc"
#-----------------------------------------------------------------------------------------------
# List of variables to save
#-----------------------------------------------------------------------------------------------
#
var3d="Time,P,TK,U,V,W,Z,XTIME,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,REFL_10CM"
var3d="P,TK,U,V,W,Z,XTIME,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,REFL_10CM"
varConst="XLAT,XLONG,HGT,SINALPHA,COSALPHA"
var2d="MLCAPE,MLCINH,MLLCL,MUCAPE,PREC_ACC_NC,PSFC,PWAT,QVAPOR,REFL_10CM,REFL_COM,SNOW,SNOW_ACC_NC,SRH03,T2,TD2,TH2,U10,USHR1,V10,VSHR1,XTIME,Z,Time"

#----- bounds -------#
#(13,218)(1255,884)
ilonLL=13
ilonUR=1255
ilonUR_stag=1256
jlatLL=218
jlatUR=884
jlatUR_stag=885

_info "root" "Input: ${YELLOW}${INDIR3D}${RESET} Output: ${YELLOW}${outdir}${RESET}"

function handle_3d_file(){
    infile=$1
    outdir_3d="${outdir}/3D"
    outfile=$(basename ${infile})
    outpath="${outdir_3d}/${outfile}"
    if [ ! -f ${outpath} ]; then
        _info "handle_3d" "3D input file: ${YELLOW}${infile}${RESET}"
        _info "handle_3d" "Output file: ${YELLOW}${outpath}${RESET}"
        
        ncks -A -x ${infile} ${outpath}
        
        ncks -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -v${var3d} ${infile} ${outpath}
        ncks -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east_stag,${ilonLL},${ilonUR_stag} -vU ${infile} ${outpath}
        ncks -A -dsouth_north_stag,${jlatLL},${jlatUR_stag} -dwest_east,${ilonLL},${ilonUR} -vV ${infile} ${outpath}
        # ncks -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -vHGT ${CONST} ${outpath}
        

        # remove global atts
        # ncatted -O -a,global,d,, ${outpath} ${outpath}
        #----------------- Compress file -----------------------#
        # ncks -O -4 -L 1 ${outpath} ${outpath}
    else
        _warn "handle_3d" "Output already exists: ${YELLOW}${outpath}${RESET}"
    fi
}

function handle_3d(){
    outdir_3d="${outdir}/3D"
    mkdir -p ${outdir_3d}
    for infile in `/bin/ls -1 ${INDIR3D}/wrf3d*`; do
        handle_3d_file ${infile} &
    done
    wait
    _success "handle_3d" "Done"
}

function handle_2d_file(){
    infile=$1
    outdir_2d="${outdir}/2D"
    outfile=$(basename ${infile})
    outpath="${outdir_2d}/${outfile}"
    if [ ! -f ${outfile} ]; then
        _info "handle_2d" "2D input file: ${YELLOW}${infile}${RESET}"
        _info "handle_2d" "Output file: ${YELLOW}${outpath}${RESET}"

        ncks -h -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -v${var2d} ${infile} ${outpath}
        # ncks -h -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -vHGT ${CONST} ${outpath}

        # # remove global atts
        # ncatted -O -a,global,d,, ${outpath} ${outpath}
        # #----------------- Compress file -----------------------#
        # ncks -O -4 -L 1 ${outpath} ${outpath}
    else
        _warn "handle_2d" "Output already exists: ${YELLOW}${outpath}${RESET}"
    fi
}

function handle_2d(){
    outdir_2d="${outdir}/2D"
    mkdir -p ${outdir_2d}
    for infile in `/bin/ls -1 ${INDIR3D}/wrf2d*`; do
        handle_2d_file ${infile} &
    done
    wait
    _success "handle_2d" "Done"
}

function handle_const(){
    infile=${CONST}
    outdir_const="${outdir}"
    outfile=$(basename ${infile})
    outpath="${outdir_const}/${outfile}"
    if [ ! -f ${outfile} ]; then
        _info "handle_const" "Constants input file: ${YELLOW}${infile}${RESET}"
        _info "handle_const" "Output file: ${YELLOW}${outpath}${RESET}"

        ncks -h -A -dsouth_north,${jlatLL},${jlatUR} -dwest_east,${ilonLL},${ilonUR} -v${varConst} ${infile} ${outpath}

        # ncatted -O -a,global,d,, ${outpath} ${outpath}
        #----------------- Compress file -----------------------#
        # ncks -O -4 -L 1 ${outpath} ${outpath}
    else
        _warn "handle_const" "Output already exists: ${YELLOW}${outpath}${RESET}"
    fi
}

handle_3d

handle_2d

handle_const

_success "root" "Done"
