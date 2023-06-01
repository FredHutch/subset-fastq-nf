#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// Function which prints help message text
def helpMessage() {
    log.info"""
    Usage:

    nextflow run FredHutch/subset-fastq-nf <args>

    Required Arguments:
        --input        # Path of FASTQ file(s) to analyze
                         multiple files are separated by commas
        --nreads       # Number of reads to keep from each file
        --outdir       # Folder to place output files

    """.stripIndent()
}

process subset_fastq {
    container "ubuntu:21.04"
    publishDir params.outdir, mode: 'copy', overwrite: true
    input:
        path fastq

    output:
        file "${fastq}"

    script:
    nlines = params.nreads * 4
    """#!/bin/bash
set -eu

echo "Processing ${fastq}"
echo "Keeping ${params.nreads} - ${nlines} lines"

# Read a FASTQ file, whether or not it is gzip-compressed
read_fastq(){
    if [[ "${fastq}" == *.gz ]]; then
        gunzip -c "${fastq}"
    else
        cat "${fastq}"
    fi
}

# Read the FASTQ, take the first nlines, and write to TEMP
if [[ "${fastq}" == *.gz ]]; then
    read_fastq \
        | head -${nlines} \
        | gzip -c \
        > TEMP
else
    read_fastq \
        | head -${nlines} \
        > TEMP
fi

# Rename the output file
mv TEMP "${fastq}"

echo Done
"""
}


workflow {

    // Print the help message
    if (params.help){
        helpMessage();
        exit 0
    }

    if (!params.input){
        log.info"""Please specify --input."""
        exit 0
    }
    if (!params.outdir){
        log.info"""Please specify --outdir."""
        exit 0
    }

    Channel
        .fromPath(
            "${params.input}".split(",").toList(),
            checkIfExists: true
        )
        | subset_fastq

}
