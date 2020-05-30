#'---
#' title: Export counts in tsv format
#' author: Michaela Müller
#' wb:
#'  params:
#'    - tmpdir: '`sm drop.getMethodPath(METHOD, "tmp_dir")`'
#'  input: 
#'    - counts: '`sm parser.getProcDataDir() +
#'               "/aberrant_expression/{annotation}/outrider/{dataset}/total_counts.Rds"`'
#'  output:
#'    - export: '`sm parser.getProcResultsDir() + "/exported_counts/{dataset}/"
#'                + "geneCounts_{annotation}.tsv.gz"`'
#'  type: script
#'---

saveRDS(snakemake, file.path(snakemake@params$tmpdir, "merge_counts.snakemake"))
# snakemake <- readRDS(".drop/tmp/AE/merge_counts.snakemake")

suppressPackageStartupMessages({
    library(data.table)
    library(SummarizedExperiment)
})

total_counts <- readRDS(snakemake@input$counts)

# save in exportable format
fwrite(as.data.table(assay(total_counts), keep.rownames = 'geneID'),
       file = snakemake@output$export,
       quote = FALSE, row.names = FALSE, sep = '\t', compress = 'gzip')
