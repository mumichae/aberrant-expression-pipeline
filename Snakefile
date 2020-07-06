### SNAKEFILE ABERRANT EXPRESSION
from pathlib import Path
import os
import drop

cfg = drop.config.DropConfig(config)
sa = cfg.sampleAnnotation
config = cfg.config # for legacy

METHOD = 'AE'
SCRIPT_ROOT = drop.getMethodPath(METHOD, type_='workdir', str_=False)
CONF_FILE = drop.getConfFile(METHOD)

include: drop.utils.getWBuildSnakefile()

rule all:
    input: 
        rules.Index.output, config["htmlOutputPath"] + "/aberrant_expression_readme.html",
        expand(
            config["htmlOutputPath"] + "/Scripts_Counting_Datasets.html",
            annotation=cfg.getGeneVersions()
        ),
        expand(
            cfg.getProcessedResultsDir() + "/aberrant_expression/{annotation}/outrider/{dataset}/OUTRIDER_results.tsv",
                annotation=cfg.getGeneVersions(), dataset=cfg.AE.groups
        )
    output: touch(drop.getMethodPath(METHOD, type_='final_file'))


rule bam_stats:
    input: 
        bam = lambda wildcards: sa.getFilePath(wildcards.sampleID, "RNA_BAM_FILE"),
        ucsc2ncbi = SCRIPT_ROOT / "resource" / "chr_UCSC_NCBI.txt"
    output:
        cfg.processedDataDir / "aberrant_expression" / "{annotation}" / "coverage" / "{sampleID}.tsv"
    params:
        samtools = config["tools"]["samtoolsCmd"]
    shell:
        """
        # identify chromosome format
        if {params.samtools} idxstats {input.bam} | grep -qP "^chr";
        then
            chrNames=$(cut -f1 {input.ucsc2ncbi} | tr '\n' '|')
        else
            chrNames=$(cut -f2 {input.ucsc2ncbi} | tr '\n' '|')
        fi

        # write coverage from idxstats into file
        count=$({params.samtools} idxstats {input.bam} | grep -E "^($chrNames)" | \
                cut -f3 | paste -sd+ - | bc)

        echo -e "{wildcards.sampleID}\t${{count}}" > {output}
        """

rule merge_bam_stats:
    input: 
        lambda w: expand(cfg.getProcessedDataDir() +
            "/aberrant_expression/{{annotation}}/coverage/{sampleID}.tsv",
            sampleID=sa.getIDsByGroup(w.dataset))
    output:
        cfg.getProcessedDataDir() + "/aberrant_expression/{annotation}/outrider/{dataset}/bam_coverage.tsv"
    params:
        ids = lambda w: sa.getIDsByGroup(w.dataset)
    run:
        with open(output[0], "w") as bam_stats:
            bam_stats.write("sampleID\trecord_count\n")
            for f in input:
                bam_stats.write(open(f, "r").read())

rulegraph_filename = f'{config["htmlOutputPath"]}/{METHOD}_rulegraph'

rule produce_rulegraph:
    input:
        expand(rulegraph_filename + ".{fmt}", fmt=["svg", "png"])

rule create_graph:
    output:
        svg = f"{rulegraph_filename}.svg",
        png = f"{rulegraph_filename}.png"
    shell:
        """
        snakemake --configfile {CONF_FILE} --rulegraph | dot -Tsvg > {output.svg}
        snakemake --configfile {CONF_FILE} --rulegraph | dot -Tpng > {output.png}
        """
rule unlock:
    output: touch(drop.getMethodPath(METHOD, type_="unlock"))
    shell: "snakemake --unlock --configfile {CONF_FILE}"

