#!/bin/bash
# This script will generate shell scripts to schedule multiple job steps in multiple jobs.
# This script does the following.
# * Detect some settings in the SLURM config
# * Determine abslute paths to binaries and model specifications
# * Iterate over directories and generate job step scripts to run binaries
#   with multiple models and options. Each experiment will be run inside memtime.
# * Randomize the order in which experiments are run.
# * Generate job shell scripts in parallel
# the directory layout this script uses is as follows.

# ORIGINAL LAYOUT:
# +-- ~/
#      |-- .local/                                  // locally installed software
#      |    +-- bin/
#      |         |-- memtime/bin/memtime
#      |         |-- ltsmin/
#      |         |    +-- bin/
#      |         |         |-- lps2lts-sym
#      |         |         |-- prom2lts-sym
#      |         |         +-- dve2lts-sym
#      |         +-- mcrl2/mCRL2-201210/lib/mcrl2/
#      +-- experiments/
#           |-- in/                                 // the models to experiment with
#           |    |-- dve/
#           |    |    |-- a_dve_model.dve2C
#           |    |    +-- ...
#           |    |-- promela/
#           |    |    |-- a_promela_model.spins
#           |    |    +-- ...
#           |    +-- mcrl2/
#           |         |-- an_mcrl2_model.lps
#           |         +-- ...
#           |-- out/                                // root directory of experiment output
#           |    |-- 0/
#           |    |    |-- <experiment_output>.dve2C // results of a dve experiment
#           |    |    +-- ...
#           |    +-- 1/failed                       // file which contains failed experiments
#           +-- scripts/
#                |-- jobs/                          // contains job scripts (sbatch command with srun commands)
#                |    |-- 0
#                |    +-- ...
#                |-- steps/                         // contains job step scripts; shell scripts to do an experiment
#                |    |-- step_<uuid>.sh
#                |    +-- ...
#                |-- gen-experiments                // this file
#                |-- shuffle.txt                    // file to randomize the order of job steps
#                |-- slurm-out.log                  // SLURM std err and std out
#                +-- submit-jobs                    // script to submit all jobs

# MODIFIED LAYOUT
# +-- ~/
#      |-- bin/                                     // locally installed software
#      |    |-- memtime/bin/memtime
#      |    |-- ltsminPerf/
#      |    |    +-- bin/
#      |    |         |-- pnml2lts-mc
#      |    |         +-- pnml2lts-sym
#      |    +-- ltsminStat/
#      |         +-- bin/
#      |              |-- pnml2lts-mc
#      |              +-- pnml2lts-sym
#      +-- experiments/
#           |-- in/                                 // the models to experiment with
#           |    |-- ptAll/
#           |    |    |-- <a petri net definition>.pnml
#           |    |    +-- ...
#           |    +-- ptSelect/
#           |         |-- <a petri net definition>.pnml
#           |         +-- ...
#           |-- out/                                // root directory of experiment output
#           |    |-- 0/
#           |    |    |-- <experiment_output>.dve2C // results of a dve experiment
#           |    |    +-- ...
#           |    +-- 1/failed                       // file which contains failed experiments
#           +-- generated/
#           |    |-- jobs/                          // contains job scripts (sbatch command with srun commands)
#           |    |    |-- 0
#           |    |    +-- ...
#           |    |-- steps/                         // contains job step scripts; shell scripts to do an experiment
#           |    |    |-- step_<uuid>.sh
#           |    |    +-- ...
#           |    |-- shuffle.txt                    // file to randomize the order of job steps
#           |    +-- slurm-out.log                  // SLURM std err and std out
#           |-- gen_experiments.sh                  // this file
#           +-- submit_jobs.sh                      // script to submit all jobs

POPTS_VERBOSE=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bk,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bs,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vacm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vgps,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bk,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bs,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vacm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vgps,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bk,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bs,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vacm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vgps,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bk,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bs,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vcm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vacm,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vgps,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bk,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bs,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vacm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vgps,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bk,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bs,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vacm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vgps,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bk,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bs,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vacm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vgps,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bk,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bs,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vcm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vacm,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vgps,sw,mm,sr,mm,sc,mm,vf --peak-nodes --graph-metrics\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,cw,rs,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,cw,rs,hf,vf,sw,mm,sr,mm,sc,mm,vf --peak-nodes\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,cw,rs,sw,mm,sr,mm,sc,mm,vf --peak-nodes\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,cw,rs,sw,mm,sr,mm,sc,mm,vf --peak-nodes\n'
POPTS_VERBOSE+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,mm,sr,mm,sc,mm --peak-nodes'

POPTS=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bk,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bs,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vacm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vgps,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bk,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bs,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vacm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vgps,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bk,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bs,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vacm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vgps,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bk,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bs,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vcm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vacm,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vgps,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bk,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,bs,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vacm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,bg,vgps,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bk,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,bs,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vacm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,tg,vgps,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bk,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,bs,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vacm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,bg,vgps,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bk,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,bs,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vcm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vacm,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,tg,vgps,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,cw,rs,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,cw,rs,hf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsw,cw,rs,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like --no-matrix -rsc,cw,rs,vf\n'
POPTS+=$'--order=chain --next-union --saturation=sat-like'

# absolute path to scontrol
sc=`which scontrol`

# if we are on a system with scontrol use the SLURM config,
# else use some arbitrary ones.
if [[ $! -ne 0 ]]; then
    STEPS_PER_JOB=600
    MAX_JOBS=1000
else
    STEPS_PER_JOB=`$sc show config | grep MaxStepCount | grep -Eo '[0-9]+'`
    MAX_JOBS=`$sc show config | grep MaxJobCount | grep -Eo '[0-9]+'`
fi

STEPS_PER_JOB=608

echo "Maximum number of steps per job is '$STEPS_PER_JOB'"
echo "Maximum number of jobs is '$MAX_JOBS'"

# a commandline option to generate job steps
OPT_GEN_STEPS="--gen-steps"

# memtime options
# max time
CMAX=1800
MMAX=4000000000

# slum max time (sometimes slurm does not detect that a job is done)
SLURM_CMAX=35

# get the absolute path to the home directory
HOME=$(eval echo ~)
USER="s1083392"

# general path to executables
BIN="$HOME/bin"

# path to performance and stats version of ltsMin
LTSMIN_PERF_DIR="$BIN/ltsminPerf/bin"
LTSMIN_STAT_DIR="$BIN/ltsminStat/bin"

# paths for LD_LIBRARY_PATH
# mCRL2 201409.1
MCRL2_2014091="$HOME/.local/lib/mcrl2" # TODO Is this needed?

# memtime
MEMTIME="$BIN/memtime"

# working directory
WDIR="$HOME/experiments"

# paths to experiments
EXP="$WDIR/in"

# echo to std err
echoerr() { echo "$@" 1>&2; }

# path to experiment results
# successful results
RES="$WDIR/out/0"
# failed results
FAILED="$WDIR/out/1"

# directory were the generated files are stored
G_DIR="$WDIR/generated"

# directory with shell scripts for jobs
BATCH_DIR=$G_DIR/jobs
# directory with shell scripts for job steps
STEP_DIR=$G_DIR/steps
# executable to submit jobs
RUN_JOBS=$WDIR/submit_jobs.sh
# a file which contains all job steps to execute,
# so that we can randomize the order of execution
SHUFFLE=$G_DIR/shuffle.txt
# a file to with std out and std err will be written to
OUT=$G_DIR/slurm_out.log

## generate job step
## 1: command to execute
## 2: file to write results to
## 3: unique id of this job step
gen_job_step() {

    # location to the shell script of this job
    script="$STEP_DIR/step_$3.sh"

    # writes some commands to the shell script.
    # the shell script will first look in a file named 'failed'
    # to see if the experiment has been executed before in a previous iteration
    # in another job step.
    echo "#!/bin/bash" > $script
    # echo "match=\$(cat \"$FAILED/failed\" | grep -o \"$1\")">> $script
    # echo "if [[ -z \$match ]]; then" >> $script
    cat "$STEP_DIR/env_$3" >> $script
    rm "$STEP_DIR/env_$3"
    echo "  $1 > $RES/$2 2>&1" >> $script
    echo "  if [ \$? -ne 0 ]; then"  >> $script
    echo "    echo \"$1\" >> $FAILED/failed" >> $script
    echo "  fi" >> $script
    # echo "fi" >> $script
    chmod u+x $script

    # add the job step the 'shuffle' file.
    echo "srun -N1 -n1 --time=$SLURM_CMAX:00 --partition=$PARTITION $script &" >> $SHUFFLE

}

# generate job steps of specifications in a directory
# 1: array of models (a directory)
# 2: options
# 3: command
# 4: LD_LIBRARY_PATH
# 5: iteration #
gen_job_steps() {

    # loop over the directory
    for m in $(find -L "$FEXP" -type f); do

        while read -r p; do

            # since we generate job steps in parallel
            # we want to have a unique id with "uuidgen"
            uuid=`uuidgen`

            # we have installed everything locally in our home directory,
            # so we want to configure environment variables.
            envir="$STEP_DIR/env_$uuid"
            echo "  export LD_LIBRARY_PATH=$4" > $envir

            # fix the options for the experiment
            if [[ $3 == *lps2lts* ]]; then
                o="$p --mcrl2='--rewriter=jitty'"
            else
                o="$p"
            fi

            # the command the job step will execute
            c="$MEMTIME -m$MMAX -c$CMAX $3 --when --vset=lddmc --lace-workers=1 --lddmc-cachesize=26 --lddmc-tablesize=26 --lddmc-maxtablesize=26 --lddmc-maxcachesize=26 $o $m"

            # the basename of the command to execute
            n=$(basename "$3")

            # the basename of the model
            f=$(basename "$m")

            # # v contains different versions of our LTSmin executables
            # v=""
            # if [[ $3 == *stats* ]]; then
            #     v="stats"
            #     NEW_PATH=$NEXT:$ORIGINAL_PATH
            #     echo "  export PATH=$NEW_PATH" >> $envir
            # fi

            # make sure the options do not have characters invalid for a filename
            o=$(echo $p | tr " " "-")

            # the file to write results to
            r="$5""_""$v""_""$n""_""$o""_""$f"
            gen_job_step "$c" "$r" "$uuid"        
        done <<< "$2"
    done

}

# usage information
if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]]; then
    echoerr "Usage $0 repeat dir part bin nodes [$OPT_GEN_STEPS]"
    exit 1
fi

# full path to experiments
FEXP="$EXP/$2"

PARTITION="$3"

BINARY="$LTSMIN_PERF_DIR/$4"
BINARY_STATS="$LTSMIN_STAT_DIR/$4"
NODES="$5"

# delete old job scripts
rm -r "$BATCH_DIR"
mkdir "$BATCH_DIR"

# if --gen-steps is supplied we will generate job steps, else we will only generate the jobs.
if [[ -n "$6" && $6=="$OPT_GEN_STEPS" ]]; then

    if [ ! -d "$FEXP" ]; then
        >&2 echo "$FEXP is not a valid directory"
        exit 1
    fi
    
    sinfo -p $PARTITION | grep "up" > /dev/null
    if [[ $? == 1 ]]; then
        >&2 echo "Partition $PARTITION does not exist or is down"
        exit 1
    fi

    if [ ! -f "$BINARY" ]; then
        >&2 echo "Executable $BINARY is not available"
        exit 1
    fi

    if [ ! -f "$BINARY_STATS" ]; then
        >&2 echo "Executable $BINARY_STATS is not available"
        exit 1 
    fi

    echo "Number of instances per testcase is $1"
    echo "Input model directory is $FEXP"
    echo "Partition for the experiments is $PARTITION"
    echo "Nodes used for each job is $NODES"
    echo "Binaries are $BINARY and $BINARY_STATS"
    echo "Generating steps, please wait..."

    # delete old job step scripts
    rm -r "$STEP_DIR"
    mkdir "$STEP_DIR"
    rm "$SHUFFLE"

    # This for loop will repeate the same experiment $1 times.
    for i in `seq 1 $1`; do

        # Generating job steps can take a long time, so we will run each call to gen_job_steps in parallel.
	
        gen_job_steps "$PNML" "$POPTS" "$BINARY" '""' "$i" &

    done
    gen_job_steps "$PNML" "$POPTS_VERBOSE" "$BINARY_STATS" '""' "0" &
    wait

    # shuffle our job step scripts so that they will be executed in random order.
    count=`cat $SHUFFLE | wc -l`
    echo "shuffling steps"
    cat $SHUFFLE | shuf > $SHUFFLE.tmp
    mv $SHUFFLE.tmp $SHUFFLE
fi

if [ ! -f $SHUFFLE ]; then # make sure the shuffle file exists.
    echoerr "$SHUFFLE does not exist, generate this file first with the '$OPT_GEN_STEPS' option."
    exit 1
fi

# count the number of job steps generated
let step_count=`cat $SHUFFLE | wc -l`
if [[ $step_count -ge $(($STEPS_PER_JOB * $MAX_JOBS)) ]]; then
    echoerr "To many job steps ($step_no; $(($STEPS_PER_JOB * $MAX_JOBS))); can only schedule '$MAX_JOBS' jobs and '$STEPS_PER_JOB' steps per job."
    exit 1
fi

# ceil the amount of jobs necessary
job_count=$(($step_count/$STEPS_PER_JOB))
job_count=$(( `echo $job_count|cut -f1 -d"."` + 1 ))

# generated the script which can schedule all jobs.
# the script will detect two things;
# * whether there is enough room in the queue to schedule all jobs.
# * whether we won't overwrite old experiments.
echo "#!/bin/bash" > $RUN_JOBS
echo -e "echoerr() { echo \"\$@\" 1>&2; }\n" >> $RUN_JOBS
echo "# make sure we can submit '$job_count' batch(es)" >> $RUN_JOBS
echo "queue_len=\$((\`squeue | wc -l\` -1))" >> $RUN_JOBS
echo "if [ \$((\$queue_len+$job_count)) -gt $MAX_JOBS ]; then" >> $RUN_JOBS
echo "    echoerr \"Can not submit jobs. Currently you can only submit '\$(($MAX_JOBS - \$queue_len))' jobs.\"" >> $RUN_JOBS
echo "    exit 1" >> $RUN_JOBS
echo -e "fi\n" >> $RUN_JOBS

echo "# make sure we do not overwrite older experiments" >> $RUN_JOBS
echo "if [ \"\$(ls -A $RES)\" ]; then" >> $RUN_JOBS
echo "    echoerr \"Directory $RES is not empty\"" >> $RUN_JOBS
echo "    exit 1" >> $RUN_JOBS
echo "fi" >> $RUN_JOBS
echo "/bin/rm $FAILED/failed" >> $RUN_JOBS
echo "touch $FAILED/failed" >> $RUN_JOBS
echo "/bin/rm $OUT" >> $RUN_JOBS

echo "'$step_count' steps to submit"
echo "'$job_count' job(s) needed"

# generate each job shell script
for i in `seq 0 $(($job_count-1))`; do

    current_job=$BATCH_DIR/$i

    #echo "read -n1 -r -p \"Press any key to submit next batch ($i)...\" key" >> $RUN_JOBS
    echo "${current_job}_jobs" >> $RUN_JOBS
    if [ $i -lt $(($job_count-1)) ]; then
        echo 'myjobs=1000' >> $RUN_JOBS
        echo 'otherjobs=10000' >> $RUN_JOBS
	    echo 'while [ $myjobs -gt 608 -o $otherjobs -gt 5000 ]; do' >> $RUN_JOBS
        echo '    myjobs=$(squeue -h -p'"$PARTITION"' -u'"$USER"'| wc -l)' >> $RUN_JOBS
        echo '    otherjobs=$(squeue -h | wc -l)' >> $RUN_JOBS
		echo '    sleep 10' >> $RUN_JOBS
	    echo 'done' >> $RUN_JOBS
	fi

    # we sleep one minute after scheduling each job
    # to relax the SLURM control daemon
    #if [ $i -lt $(($job_count-1)) ]; then
        #echo "sleep 10" >> $RUN_JOBS
    #fi

    # add options for the 'sbatch' command to the job
    # the --cpus-per-task option makes sure the job step will be executed
    # exclusively on one node.
    echo "#!/bin/bash" > ${current_job}_batch
    echo "#SBATCH --partition=$PARTITION -N$NODES --output=$OUT --open-mode=append" >> ${current_job}_batch
    echo "${current_job}_jobs" >> ${current_job}_batch

    # determine the lines to take from the randomized 'shuffle' file
    min=$(($i*$STEPS_PER_JOB+1))
    max=$(($(($i+1))*$STEPS_PER_JOB))
    if [ $max -gt $step_count ]; then
        let max=$step_count
    fi
    echo "#!/bin/bash" > ${current_job}_jobs
    echo "#steps $min - $(($max))" >> ${current_job}_jobs
    sedargs="${min},${max}p;${max}q"
    sed -n "$sedargs" $SHUFFLE >> ${current_job}_jobs

    #echo "wait" >> ${current_job}_jobs
    chmod +x ${current_job}_batch
    chmod +x ${current_job}_jobs

done
chmod +x $RUN_JOBS
echo "done generating"
echo "you can now run '$RUN_JOBS'"
