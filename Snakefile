### SNAKEFILE ABERRANT EXPRESSION
import os
import drop
import pathlib

parser = drop.config(config)
config = parser.parse()
include: config['wBuildPath'] + "/wBuild.snakefile"

METHOD = 'AE'
SCRIPT_ROOT = drop.getMethodPath(METHOD, type_='workdir')

rule all:
    input: 
        rules.Index.output, config["htmlOutputPath"] + "/aberrant_expression_readme.html",
        expand(
            config["htmlOutputPath"] + "/AberrantExpression/Counting/{annotation}/Summary_{dataset}.html",
            annotation=list(config["geneAnnotation"].keys()),
            dataset=parser.outrider_ids
        ),
        expand(
            parser.getProcResultsDir() + "/aberrant_expression/{annotation}/outrider/{dataset}/OUTRIDER_results.tsv",
            annotation=list(config["geneAnnotation"].keys()),
            dataset=parser.outrider_ids
        )
    output: touch(drop.getMethodPath(METHOD, type_='final_file'))

rule read_count_qc:
    input:
        bam_files = lambda wildcards: parser.getFilePaths(group=wildcards.dataset, ids_by_group=config["outrider_ids"], file_type='RNA_BAM_FILE'),
        ucsc2ncbi = os.path.join(SCRIPT_ROOT, "resource", "chr_UCSC_NCBI.txt"),
        script = os.path.join(SCRIPT_ROOT, "Scripts", "Counting", "bamfile_coverage.sh")
    output:
        qc = parser.getProcDataDir() + "/aberrant_expression/{annotation}/outrider/{dataset}/bam_coverage.tsv"
    params:
        sample_ids = lambda wildcards: parser.outrider_ids[wildcards.dataset]
    shell:
        "{input.script} {input.ucsc2ncbi} {output.qc} {params.sample_ids} {input.bam_files}"


### RULEGRAPH
config_file = drop.getConfFile()
rulegraph_filename = f'{config["htmlOutputPath"]}/{METHOD}_rulegraph'

rule produce_rulegraph:
    input:
        expand(rulegraph_filename + ".{fmt}", fmt=["svg", "png"])

rule create_graph:
    output:
        rulegraph_filename + ".dot"
    shell:
        "snakemake --configfile {config_file} --rulegraph > {output}"

rule render_dot:
    input:
        "{prefix}.dot"
    output:
        "{prefix}.{fmt,(png|svg)}"
    shell:
        "dot -T{wildcards.fmt} < {input} > {output}"

