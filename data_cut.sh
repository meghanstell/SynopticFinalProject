#! /usr/bin/env bash

#####################################################################################################
# Global Bash Utility Functions (Logging)
#####################################################################################################

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
    ## Generic INFO logging function
    ## Inputs:
    ##   - context : functional/logical details
    ##   - msg : string to log
    ##
    ## Example:
    ##   _info "${region}" "Using Maskfile: ${maskFile}"
    ##
    ## Output:
    ##   2024-04-22T03:04:39-06:00 :: INFO    :: basincreek :: Using Maskfile: /glade/derecho/scratch/meghan/Montana/Montana_Masks/scripts/../masks/generators/generator_BasinCreek_avg.nc

    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${CYAN}INFO${RESET}    :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

function _warn(){
    ## Generic WARNING logging function
    ## Inputs:
    ##   - context : functional/logical details
    ##   - msg : string to log
    ##
    ## Example:
    ##   _warn "${region}.${year}.${month}" "${catfile} already exists. Checking masked output..."
    ##
    ## Output:
    ##   2024-04-22T03:17:20-06:00 :: WARNING :: basincreek.1987.01 :: /glade/derecho/scratch/meghan/Montana/masks/basincreek/../seedvars/seedvars_1987_01.nc already exists. Checking masked output...

    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${YELLOW}WARNING${RESET} :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

function _error(){
    ## Generic ERROR logging function
    ## Inputs:
    ##   - context : functional/logical details
    ##   - msg : string to log
    ##
    ## Example:
    ##   _error "${region}.${year}.${month}" "Failed to add mask"
    ##
    ## Output:
    ##   2024-04-22T03:22:09-06:00 :: ERROR   :: basincreek.1987.01 :: Failed to add mask

    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${RED}ERROR${RESET}   :: ${MAGENTA}${context}${RESET} :: ${msg}"
}

function _success(){
    ## Generic SUCCESS logging function
    ## Inputs:
    ##   - context : functional/logical details
    ##   - msg : string to log
    ##
    ## Example:
    ##   _error "${region}.${year}.${month}" "Failed to add mask"
    ##
    ## Output:
    ##   2024-04-22T03:23:50-06:00 :: SUCCESS :: basincreek :: Masked Site NC File located at /glade/derecho/scratch/meghan/Montana/masks/basincreek/../basincreek.nc

    context=$1
    msg=$2
    echo -e "${WHITE}$(date -Iseconds)${RESET} :: ${GREEN}SUCCESS${RESET} :: ${MAGENTA}${context}${RESET} :: ${msg}"
}


#####################################################################################################
# Functional Execution
#####################################################################################################

# Context Variables
model='PGW'
src_dir="/glade/campaign/ral/hap/cweeks/montana/data/model/${model}/SeedingCriteria"
out_dir="/glade/derecho/scratch/meghan/Montana/data/model/${model}/SeedingCriteria"
day_out_dir=${out_dir}/daily
month_out_dir=${out_dir}/monthly
season_out_dir=${out_dir}/season

mkdir -p -m 777 ${day_out_dir} ${month_out_dir} ${season_out_dir} 2>/dev/null

cmd="ncrcat --hst "

function combine_day_of_all_years(){    
    month=$1
    day=$2
    day_cat_file=${day_out_dir}/${model}_SV_${month}_${day}.nc
    if [ ! -f ${day_cat_file} ]; then
        _info    "combine_day_of_all_years.${month}.${day}" "${YELLOW}Processing Day ${MAGENTA}${month}-${day}${RESET}"
        ${cmd} ${src_dir}/Seeding_criteria_*-${month}-${day}_*.nc ${day_cat_file}
        _success "combine_day_of_all_years.${month}.${day}" "${GREEN}Done Processing Day ${MAGENTA}${month}-${day}${RESET}"
    else
        _warn "combine_day_of_all_years.${month}.${day}" "Output file ${YELLOW}${day_cat_file}${RESET} already exists!"
    fi
}

function combine_month_of_all_years(){
    month=$1
    _info    "combine_month_of_all_years.${month}" "${YELLOW}Processing Month ${MAGENTA}${month}${RESET}"
    month_cat_file=${month_out_dir}/${model}_SV_${month}.nc
    if [ ! -f ${month_cat_file} ]; then
        for day in `seq -f %02g 01 31`; do
            combine_day_of_all_years ${month} ${day} &
        done
        wait
        ${cmd} ${day_out_dir}/${model}_SV_${month}_*.nc ${month_cat_file}
        _success "combine_month_of_all_years.${month}" "${GREEN}Done Processing Month ${MAGENTA}${month}${RESET}"
    else
        _warn "combine_month_of_all_years.${month}" "Output file ${YELLOW}${month_cat_file}${RESET} already exists!"
    fi
}

function combine_seasonal_months(){
    season_cat_file=${season_out_dir}/${model}_SV_Season.nc
    if [ ! -f ${season_cat_file} ]; then
        _info    "combine_seasonal_months" "${YELLOW}Combining Seasonal Months${RESET}"
        ${cmd} \
            ${month_out_dir}/${model}_SV_11.nc \
            ${month_out_dir}/${model}_SV_12.nc \
            ${month_out_dir}/${model}_SV_01.nc \
            ${month_out_dir}/${model}_SV_02.nc \
            ${month_out_dir}/${model}_SV_03.nc \
            ${month_out_dir}/${model}_SV_04.nc \
            ${season_cat_file}
        _success "combine_seasonal_months" "${GREEN}Done!${RESET} Output located at ${MAGENTA}${season_cat_file}${RESET}"
    else
        _warn "combine_seasonal_months" "Output file ${YELLOW}${season_cat_file}${RESET} already exists!"
    fi
}

function handle_months(){
    months=("01" "02" "03" "04" "05" "11" "12")
    for month in ${months[@]}; do
        # _info "handle_months.${month}" "Launching combine_month_of_all_years for ${MAGENTA}${month}${RESET}"
        combine_month_of_all_years ${month} &
    done
    wait
    _success "handle_months" "Done!"
}

function run(){
    _info "run" "Combining source Seeding Criteria data\n\tSource: ${YELLOW}${src_dir}${RESET}\n\tOutput: ${YELLOW}${out_dir}${RESET}"
    handle_months
    combine_seasonal_months
    _success "run" "Done!"
}

run
