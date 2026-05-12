```R
### Load libraries
library(qsea)
library("BSgenome")
library(dplyr)
#library(BSgenome.Hsapiens.UCSC.hg38)
library("gtools")
library(MEDIPS)
library(IRanges)
library(GenomicRanges)
#library(org.Hs.eg.db)
library(BiocParallel)
library(readxl)
library(tidyverse)
library(stringr)
```


```R
##set up directories
dataDir <- "/home/jupyterlab/data"
mainDir <- "/home/jupyterlab/data/ebv-kd_medip"
inDir <- "/home/jupyterlab/data/ebv-kd_medip/r_inputs"
outDir <- "/home/jupyterlab/data/ebv-kd_medip/r_outputs/"
```


```R
setwd(inDir)
sample_meta <- read_excel("MeDIP seq sample info for Shangying.xlsx")
```


```R
colnames(sample_meta) <- c("ID", "label", "samples", "sample_type", "cell_type")
```


```R
head(sample_meta)
```


<table class="dataframe">
<caption>A tibble: 6 × 5</caption>
<thead>
	<tr><th scope=col>ID</th><th scope=col>label</th><th scope=col>sample_name</th><th scope=col>sample_type</th><th scope=col>cell_type</th></tr>
	<tr><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th></tr>
</thead>
<tbody>
	<tr><td>NKYS SCR#2 set 1  </td><td>YS S2 1</td><td>YSS21</td><td>NKYS control   </td><td>NKYS</td></tr>
	<tr><td>NKYS EBNA1#1 set 1</td><td>YS E1 1</td><td>YSE11</td><td>NKYS EBNA1 KD 1</td><td>NKYS</td></tr>
	<tr><td>NKYS EBNA1#2 set 1</td><td>YS E2 1</td><td>YSE21</td><td>NKYS EBNA1 KD 2</td><td>NKYS</td></tr>
	<tr><td>NKYS LMP1#5 set 1 </td><td>YS L5 1</td><td>YSL51</td><td>NKYS LMP1 KD 1 </td><td>NKYS</td></tr>
	<tr><td>NKYS LMP1#6 set 1 </td><td>YS L6 1</td><td>YSL61</td><td>NKYS LMP1 KD 2 </td><td>NKYS</td></tr>
	<tr><td>NKYS SCR#2 set 2  </td><td>YS S2 2</td><td>YSS22</td><td>NKYS control   </td><td>NKYS</td></tr>
</tbody>
</table>




```R
sample_meta <- sample_meta %>% mutate(group = gsub(" 1$| 2$", "", sample_type))
unique(sample_meta$group)                                     
```


<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>'NKYS control'</li><li>'NKYS EBNA1 KD'</li><li>'NKYS LMP1 KD'</li><li>'NKS1 control'</li><li>'NKS1 EBNA1 KD'</li><li>'NKS1 LMP1 KD'</li><li>'SNK6 control'</li><li>'SNK6 EBNA1 KD'</li><li>'SNK6 LMP1 KD'</li><li>'primary NK cells'</li><li>'primary T cells'</li><li>'ENKTL cell line (EBV positive)'</li><li>'ENKTL cell line (EBV negative)'</li><li>'ENKTL case FFPE (as a control with previous batches)'</li><li><span style=white-space:pre-wrap>'Normal Tonsil FFPE  (as a control with previous batches)'</span></li></ol>




```R
setwd(dataDir)
#qsea object and check sample quality
files_batch1=list.files(path="./bam/ebv-kd_data/batch1/", pattern="bam$")
files_batch1_part=sub("_merged_sorted.bam","",files_batch1)
samples_batch1 <- sapply(files_batch1_part, function(x) {
  parts <- str_split(x, "_")[[1]]
 # paste(parts[1], parts[length(parts)], sep = "_")
})
samples_batch1 <- unlist(samples_batch1)
files_batch1=paste0("./bam/ebv-kd_data/batch1/",files_batch1)
files_batch1
samples_batch1
```


<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>'./bam/ebv-kd_data/batch1/HANK1_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/KAI3_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/KHYG_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/MD11_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/NK92_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/NKS1_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/NKYS_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1E11_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1E12_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1E13_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1E21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1E22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1E23_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1L51_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1L52_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1L53_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1L71_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1L72_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1L73_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1S21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1S22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S1S23_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6E11_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6E12_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6E21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6E22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6L51_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6L52_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6L61_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6L62_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6S21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/S6S22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/SNK1_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/SNK6_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/T1820_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/T2728_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/T4748_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/TON16_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/Undetermined_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSE11_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSE12_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSE13_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSE21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSE22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSE23_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSL51_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSL52_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSL53_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSL61_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSL62_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSL63_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSS21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSS22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YSS23_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch1/YT_merged_sorted.bam'</li></ol>




<style>
.dl-inline {width: auto; margin:0; padding: 0}
.dl-inline>dt, .dl-inline>dd {float: none; width: auto; display: inline-block}
.dl-inline>dt::after {content: ":\0020"; padding-right: .5ex}
.dl-inline>dt:not(:first-of-type) {padding-left: .5ex}
</style><dl class=dl-inline><dt>HANK1</dt><dd>'HANK1'</dd><dt>KAI3</dt><dd>'KAI3'</dd><dt>KHYG</dt><dd>'KHYG'</dd><dt>MD11</dt><dd>'MD11'</dd><dt>NK92</dt><dd>'NK92'</dd><dt>NKS1</dt><dd>'NKS1'</dd><dt>NKYS</dt><dd>'NKYS'</dd><dt>S1E11</dt><dd>'S1E11'</dd><dt>S1E12</dt><dd>'S1E12'</dd><dt>S1E13</dt><dd>'S1E13'</dd><dt>S1E21</dt><dd>'S1E21'</dd><dt>S1E22</dt><dd>'S1E22'</dd><dt>S1E23</dt><dd>'S1E23'</dd><dt>S1L51</dt><dd>'S1L51'</dd><dt>S1L52</dt><dd>'S1L52'</dd><dt>S1L53</dt><dd>'S1L53'</dd><dt>S1L71</dt><dd>'S1L71'</dd><dt>S1L72</dt><dd>'S1L72'</dd><dt>S1L73</dt><dd>'S1L73'</dd><dt>S1S21</dt><dd>'S1S21'</dd><dt>S1S22</dt><dd>'S1S22'</dd><dt>S1S23</dt><dd>'S1S23'</dd><dt>S6E11</dt><dd>'S6E11'</dd><dt>S6E12</dt><dd>'S6E12'</dd><dt>S6E21</dt><dd>'S6E21'</dd><dt>S6E22</dt><dd>'S6E22'</dd><dt>S6L51</dt><dd>'S6L51'</dd><dt>S6L52</dt><dd>'S6L52'</dd><dt>S6L61</dt><dd>'S6L61'</dd><dt>S6L62</dt><dd>'S6L62'</dd><dt>S6S21</dt><dd>'S6S21'</dd><dt>S6S22</dt><dd>'S6S22'</dd><dt>SNK1</dt><dd>'SNK1'</dd><dt>SNK6</dt><dd>'SNK6'</dd><dt>T1820</dt><dd>'T1820'</dd><dt>T2728</dt><dd>'T2728'</dd><dt>T4748</dt><dd>'T4748'</dd><dt>TON16</dt><dd>'TON16'</dd><dt>Undetermined</dt><dd>'Undetermined'</dd><dt>YSE11</dt><dd>'YSE11'</dd><dt>YSE12</dt><dd>'YSE12'</dd><dt>YSE13</dt><dd>'YSE13'</dd><dt>YSE21</dt><dd>'YSE21'</dd><dt>YSE22</dt><dd>'YSE22'</dd><dt>YSE23</dt><dd>'YSE23'</dd><dt>YSL51</dt><dd>'YSL51'</dd><dt>YSL52</dt><dd>'YSL52'</dd><dt>YSL53</dt><dd>'YSL53'</dd><dt>YSL61</dt><dd>'YSL61'</dd><dt>YSL62</dt><dd>'YSL62'</dd><dt>YSL63</dt><dd>'YSL63'</dd><dt>YSS21</dt><dd>'YSS21'</dd><dt>YSS22</dt><dd>'YSS22'</dd><dt>YSS23</dt><dd>'YSS23'</dd><dt>YT</dt><dd>'YT'</dd></dl>




```R
files_batch2=list.files(path="./bam/ebv-kd_data/batch2/", pattern="bam$")
files_batch2_part=sub("_merged_sorted.bam","",files_batch2)
samples_batch2 <- sapply(files_batch2_part, function(x) {
  parts <- str_split(x, "_")[[1]]
    
})
samples_batch2 <- unlist(samples_batch2)
files_batch2=paste0("./bam/ebv-kd_data/batch2/",files_batch2)
files_batch2
samples_batch2
```


<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>'./bam/ebv-kd_data/batch2/NK1617_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/NK4142_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/NK4748_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S1L53_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S1L73_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6E11_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6E13_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6E21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6E23_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6L51_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6L53_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6L61_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6L63_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6S21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6S22_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch2/S6S23_merged_sorted.bam'</li></ol>




<style>
.dl-inline {width: auto; margin:0; padding: 0}
.dl-inline>dt, .dl-inline>dd {float: none; width: auto; display: inline-block}
.dl-inline>dt::after {content: ":\0020"; padding-right: .5ex}
.dl-inline>dt:not(:first-of-type) {padding-left: .5ex}
</style><dl class=dl-inline><dt>NK1617</dt><dd>'NK1617'</dd><dt>NK4142</dt><dd>'NK4142'</dd><dt>NK4748</dt><dd>'NK4748'</dd><dt>S1L53</dt><dd>'S1L53'</dd><dt>S1L73</dt><dd>'S1L73'</dd><dt>S6E11</dt><dd>'S6E11'</dd><dt>S6E13</dt><dd>'S6E13'</dd><dt>S6E21</dt><dd>'S6E21'</dd><dt>S6E23</dt><dd>'S6E23'</dd><dt>S6L51</dt><dd>'S6L51'</dd><dt>S6L53</dt><dd>'S6L53'</dd><dt>S6L61</dt><dd>'S6L61'</dd><dt>S6L63</dt><dd>'S6L63'</dd><dt>S6S21</dt><dd>'S6S21'</dd><dt>S6S22</dt><dd>'S6S22'</dd><dt>S6S23</dt><dd>'S6S23'</dd></dl>




```R
files_batch3=list.files(path="./bam/ebv-kd_data/batch3/", pattern="bam$")
files_batch3_part=sub("_merged_sorted.bam","",files_batch3)
samples_batch3 <- sapply(files_batch3_part, function(x) {
  parts <- str_split(x, "_")[[1]]
    
})
samples_batch3 <- unlist(samples_batch3)
files_batch3=paste0("./bam/ebv-kd_data/batch3/",files_batch3)
files_batch3
samples_batch3
```


<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>'./bam/ebv-kd_data/batch3/S1L53_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S1L73_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S6E11_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S6E21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S6L51_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S6L61_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S6S21_merged_sorted.bam'</li><li>'./bam/ebv-kd_data/batch3/S6S22_merged_sorted.bam'</li></ol>




<style>
.dl-inline {width: auto; margin:0; padding: 0}
.dl-inline>dt, .dl-inline>dd {float: none; width: auto; display: inline-block}
.dl-inline>dt::after {content: ":\0020"; padding-right: .5ex}
.dl-inline>dt:not(:first-of-type) {padding-left: .5ex}
</style><dl class=dl-inline><dt>S1L53</dt><dd>'S1L53'</dd><dt>S1L73</dt><dd>'S1L73'</dd><dt>S6E11</dt><dd>'S6E11'</dd><dt>S6E21</dt><dd>'S6E21'</dd><dt>S6L51</dt><dd>'S6L51'</dd><dt>S6L61</dt><dd>'S6L61'</dd><dt>S6S21</dt><dd>'S6S21'</dd><dt>S6S22</dt><dd>'S6S22'</dd></dl>




```R
samples_list=data.frame(
    first_column=c(samples_batch1, samples_batch2, samples_batch3),
    second_column=c(files_batch1,files_batch2, files_batch3),
    third_column=factor(rep(c("batch1","batch2", "batch3"),c(length(files_batch1), length(files_batch2), length(files_batch3))))
                        )
colnames(samples_list)=c("samples", "file_name", "batch")
dim(samples_list)
head(samples_list)
```


<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>79</li><li>3</li></ol>




<table class="dataframe">
<caption>A data.frame: 6 × 3</caption>
<thead>
	<tr><th></th><th scope=col>samples</th><th scope=col>file_name</th><th scope=col>batch</th></tr>
	<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;fct&gt;</th></tr>
</thead>
<tbody>
	<tr><th scope=row>1</th><td>HANK1</td><td>./bam/ebv-kd_data/batch1/HANK1_merged_sorted.bam</td><td>batch1</td></tr>
	<tr><th scope=row>2</th><td>KAI3 </td><td>./bam/ebv-kd_data/batch1/KAI3_merged_sorted.bam </td><td>batch1</td></tr>
	<tr><th scope=row>3</th><td>KHYG </td><td>./bam/ebv-kd_data/batch1/KHYG_merged_sorted.bam </td><td>batch1</td></tr>
	<tr><th scope=row>4</th><td>MD11 </td><td>./bam/ebv-kd_data/batch1/MD11_merged_sorted.bam </td><td>batch1</td></tr>
	<tr><th scope=row>5</th><td>NK92 </td><td>./bam/ebv-kd_data/batch1/NK92_merged_sorted.bam </td><td>batch1</td></tr>
	<tr><th scope=row>6</th><td>NKS1 </td><td>./bam/ebv-kd_data/batch1/NKS1_merged_sorted.bam </td><td>batch1</td></tr>
</tbody>
</table>




```R
samples_list <- samples_list %>% mutate(sample_name = paste0(samples,"_", batch))
```


```R
samples_list <- samples_list %>% left_join(sample_meta, by = "samples")
head(samples_list)
dim(samples_list)
```


<table class="dataframe">
<caption>A data.frame: 6 × 9</caption>
<thead>
	<tr><th></th><th scope=col>samples</th><th scope=col>file_name</th><th scope=col>batch</th><th scope=col>sample_name</th><th scope=col>ID</th><th scope=col>label</th><th scope=col>sample_type</th><th scope=col>cell_type</th><th scope=col>group</th></tr>
	<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;fct&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th></tr>
</thead>
<tbody>
	<tr><th scope=row>1</th><td>HANK1</td><td>./bam/ebv-kd_data/batch1/HANK1_merged_sorted.bam</td><td>batch1</td><td>HANK1_batch1</td><td>HANK-1 (WT) cell DNA</td><td>HANK1</td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td><td>ENKTL cell line (EBV positive)                      </td></tr>
	<tr><th scope=row>2</th><td>KAI3 </td><td>./bam/ebv-kd_data/batch1/KAI3_merged_sorted.bam </td><td>batch1</td><td>KAI3_batch1 </td><td>KAI3 (WT) cell DNA  </td><td>KAI3 </td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td><td>ENKTL cell line (EBV positive)                      </td></tr>
	<tr><th scope=row>3</th><td>KHYG </td><td>./bam/ebv-kd_data/batch1/KHYG_merged_sorted.bam </td><td>batch1</td><td>KHYG_batch1 </td><td>KHYG-1 (WT) cell DNA</td><td>KHYG </td><td>ENKTL cell line (EBV negative)                      </td><td>ENKTL cell line (EBV negative)</td><td>ENKTL cell line (EBV negative)                      </td></tr>
	<tr><th scope=row>4</th><td>MD11 </td><td>./bam/ebv-kd_data/batch1/MD11_merged_sorted.bam </td><td>batch1</td><td>MD11_batch1 </td><td>MD11                </td><td>MD11 </td><td>ENKTL case FFPE (as a control with previous batches)</td><td>ENKTL FFPE                    </td><td>ENKTL case FFPE (as a control with previous batches)</td></tr>
	<tr><th scope=row>5</th><td>NK92 </td><td>./bam/ebv-kd_data/batch1/NK92_merged_sorted.bam </td><td>batch1</td><td>NK92_batch1 </td><td>NK92 (WT) cell DNA  </td><td>NK92 </td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td><td>ENKTL cell line (EBV positive)                      </td></tr>
	<tr><th scope=row>6</th><td>NKS1 </td><td>./bam/ebv-kd_data/batch1/NKS1_merged_sorted.bam </td><td>batch1</td><td>NKS1_batch1 </td><td>NK-S1 (WT) cell DNA </td><td>NKS1 </td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td><td>ENKTL cell line (EBV positive)                      </td></tr>
</tbody>
</table>




<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>79</li><li>9</li></ol>




```R
names = colnames(samples_list)
names
```


<style>
.list-inline {list-style: none; margin:0; padding: 0}
.list-inline>li {display: inline-block}
.list-inline>li:not(:last-child)::after {content: "\00b7"; padding: 0 .5ex}
</style>
<ol class=list-inline><li>'samples'</li><li>'file_name'</li><li>'batch'</li><li>'sample_name'</li><li>'ID'</li><li>'label'</li><li>'sample_type'</li><li>'cell_type'</li><li>'group'</li></ol>




```R
samples_list <- samples_list %>% 
    dplyr::select(sample_name, file_name, group, samples, batch, ID, label, sample_type, cell_type)
```


```R
head(samples_list)
```


<table class="dataframe">
<caption>A data.frame: 6 × 9</caption>
<thead>
	<tr><th></th><th scope=col>sample_name</th><th scope=col>file_name</th><th scope=col>group</th><th scope=col>samples</th><th scope=col>batch</th><th scope=col>ID</th><th scope=col>label</th><th scope=col>sample_type</th><th scope=col>cell_type</th></tr>
	<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;fct&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th></tr>
</thead>
<tbody>
	<tr><th scope=row>1</th><td>HANK1_batch1</td><td>./bam/ebv-kd_data/batch1/HANK1_merged_sorted.bam</td><td>ENKTL cell line (EBV positive)                      </td><td>HANK1</td><td>batch1</td><td>HANK-1 (WT) cell DNA</td><td>HANK1</td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td></tr>
	<tr><th scope=row>2</th><td>KAI3_batch1 </td><td>./bam/ebv-kd_data/batch1/KAI3_merged_sorted.bam </td><td>ENKTL cell line (EBV positive)                      </td><td>KAI3 </td><td>batch1</td><td>KAI3 (WT) cell DNA  </td><td>KAI3 </td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td></tr>
	<tr><th scope=row>3</th><td>KHYG_batch1 </td><td>./bam/ebv-kd_data/batch1/KHYG_merged_sorted.bam </td><td>ENKTL cell line (EBV negative)                      </td><td>KHYG </td><td>batch1</td><td>KHYG-1 (WT) cell DNA</td><td>KHYG </td><td>ENKTL cell line (EBV negative)                      </td><td>ENKTL cell line (EBV negative)</td></tr>
	<tr><th scope=row>4</th><td>MD11_batch1 </td><td>./bam/ebv-kd_data/batch1/MD11_merged_sorted.bam </td><td>ENKTL case FFPE (as a control with previous batches)</td><td>MD11 </td><td>batch1</td><td>MD11                </td><td>MD11 </td><td>ENKTL case FFPE (as a control with previous batches)</td><td>ENKTL FFPE                    </td></tr>
	<tr><th scope=row>5</th><td>NK92_batch1 </td><td>./bam/ebv-kd_data/batch1/NK92_merged_sorted.bam </td><td>ENKTL cell line (EBV positive)                      </td><td>NK92 </td><td>batch1</td><td>NK92 (WT) cell DNA  </td><td>NK92 </td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td></tr>
	<tr><th scope=row>6</th><td>NKS1_batch1 </td><td>./bam/ebv-kd_data/batch1/NKS1_merged_sorted.bam </td><td>ENKTL cell line (EBV positive)                      </td><td>NKS1 </td><td>batch1</td><td>NK-S1 (WT) cell DNA </td><td>NKS1 </td><td>ENKTL cell line (EBV positive)                      </td><td>ENKTL cell line (EBV positive)</td></tr>
</tbody>
</table>




```R
library("BiocParallel")
register(MulticoreParam(workers=12))
```


```R
setwd(dataDir)
qseaSet=createQseaSet(sampleTable=samples_list, 
                      BSgenome="BSgenome.Hsapiens.UCSC.hg38",
                      chr.select=paste0('chr',c(1:22, 'X', 'Y')),
                      window_size=500)
```

    ==== Creating qsea set ====
    
    restricting analysis on chr1, chr2, chr3, chr4, chr5, chr6, chr7, chr8, chr9, chr10, chr11, chr12, chr13, chr14, chr15, chr16, chr17, chr18, chr19, chr20, chr21, chr22, chrX, chrY
    
    Dividing selected chromosomes of BSgenome.Hsapiens.UCSC.hg38 in 500nt windows
    
    Warning message in createQseaSet(sampleTable = samples_list, BSgenome = "BSgenome.Hsapiens.UCSC.hg38", :
    “no column "sex" or "gender"found in sampleTable, assuming heterozygosity for all selected chromosomes”



```R
qseaSet=addCoverage(qseaSet, uniquePos=TRUE, paired=TRUE, parallel=TRUE)
qseaSet=addCNV(qseaSet, file_name="file_name",window_size=2e6, paired=TRUE, parallel=TRUE, MeDIP=TRUE)
```

    Scanning 12 files in parallel
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    == Analyzing Copy Number Alterations from MeDIP files ==
    
    using median of samples MD11_batch1, S1S21_batch1, S1S22_batch1, S1S23_batch1, S6S21_batch1, S6S22_batch1, TON16_batch1, YSS21_batch1, YSS22_batch1, YSS23_batch1, S6S21_batch2, S6S22_batch2, S6S23_batch2, S6S21_batch3, S6S22_batch3 as CNV free reference
    
    searching chr1 for "CG"...
    
    found 2375159 occurances of CG in chr1
    
    searching chr2 for "CG"...
    
    found 2192670 occurances of CG in chr2
    
    searching chr3 for "CG"...
    
    found 1673293 occurances of CG in chr3
    
    searching chr4 for "CG"...
    
    found 1503429 occurances of CG in chr4
    
    searching chr5 for "CG"...
    
    found 1566535 occurances of CG in chr5
    
    searching chr6 for "CG"...
    
    found 1511189 occurances of CG in chr6
    
    searching chr7 for "CG"...
    
    found 1622825 occurances of CG in chr7
    
    searching chr8 for "CG"...
    
    found 1338200 occurances of CG in chr8
    
    searching chr9 for "CG"...
    
    found 1255728 occurances of CG in chr9
    
    searching chr10 for "CG"...
    
    found 1388978 occurances of CG in chr10
    
    searching chr11 for "CG"...
    
    found 1333114 occurances of CG in chr11
    
    searching chr12 for "CG"...
    
    found 1315968 occurances of CG in chr12
    
    searching chr13 for "CG"...
    
    found 842469 occurances of CG in chr13
    
    searching chr14 for "CG"...
    
    found 895881 occurances of CG in chr14
    
    searching chr15 for "CG"...
    
    found 906026 occurances of CG in chr15
    
    searching chr16 for "CG"...
    
    found 1150891 occurances of CG in chr16
    
    searching chr17 for "CG"...
    
    found 1248328 occurances of CG in chr17
    
    searching chr18 for "CG"...
    
    found 756014 occurances of CG in chr18
    
    searching chr19 for "CG"...
    
    found 1105620 occurances of CG in chr19
    
    searching chr20 for "CG"...
    
    found 773477 occurances of CG in chr20
    
    searching chr21 for "CG"...
    
    found 462299 occurances of CG in chr21
    
    searching chr22 for "CG"...
    
    found 634646 occurances of CG in chr22
    
    searching chrX for "CG"...
    
    found 1322709 occurances of CG in chrX
    
    searching chrY for "CG"...
    
    found 225912 occurances of CG in chrY
    
    Scanning 12 files in parallel
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    R_zmq_msg_send errno: 4 strerror: Interrupted system call
    
    
    == searching for CNVs in HANK1_batch1 ==
    
    == searching for CNVs in KAI3_batch1 ==
    
    == searching for CNVs in KHYG_batch1 ==
    
    == searching for CNVs in MD11_batch1 ==
    
    == searching for CNVs in NK92_batch1 ==
    
    == searching for CNVs in NKS1_batch1 ==
    
    == searching for CNVs in NKYS_batch1 ==
    
    == searching for CNVs in S1E11_batch1 ==
    
    == searching for CNVs in S1E12_batch1 ==
    
    == searching for CNVs in S1E13_batch1 ==
    
    == searching for CNVs in S1E21_batch1 ==
    
    == searching for CNVs in S1E22_batch1 ==
    
    == searching for CNVs in S1E23_batch1 ==
    
    == searching for CNVs in S1L51_batch1 ==
    
    == searching for CNVs in S1L52_batch1 ==
    
    == searching for CNVs in S1L53_batch1 ==
    
    == searching for CNVs in S1L71_batch1 ==
    
    == searching for CNVs in S1L72_batch1 ==
    
    == searching for CNVs in S1L73_batch1 ==
    
    == searching for CNVs in S1S21_batch1 ==
    
    == searching for CNVs in S1S22_batch1 ==
    
    == searching for CNVs in S1S23_batch1 ==
    
    == searching for CNVs in S6E11_batch1 ==
    
    == searching for CNVs in S6E12_batch1 ==
    
    == searching for CNVs in S6E21_batch1 ==
    
    == searching for CNVs in S6E22_batch1 ==
    
    == searching for CNVs in S6L51_batch1 ==
    
    == searching for CNVs in S6L52_batch1 ==
    
    == searching for CNVs in S6L61_batch1 ==
    
    == searching for CNVs in S6L62_batch1 ==
    
    == searching for CNVs in S6S21_batch1 ==
    
    == searching for CNVs in S6S22_batch1 ==
    
    == searching for CNVs in SNK1_batch1 ==
    
    == searching for CNVs in SNK6_batch1 ==
    
    == searching for CNVs in T1820_batch1 ==
    
    == searching for CNVs in T2728_batch1 ==
    
    == searching for CNVs in T4748_batch1 ==
    
    == searching for CNVs in TON16_batch1 ==
    
    == searching for CNVs in Undetermined_batch1 ==
    
    == searching for CNVs in YSE11_batch1 ==
    
    == searching for CNVs in YSE12_batch1 ==
    
    == searching for CNVs in YSE13_batch1 ==
    
    == searching for CNVs in YSE21_batch1 ==
    
    == searching for CNVs in YSE22_batch1 ==
    
    == searching for CNVs in YSE23_batch1 ==
    
    == searching for CNVs in YSL51_batch1 ==
    
    == searching for CNVs in YSL52_batch1 ==
    
    == searching for CNVs in YSL53_batch1 ==
    
    == searching for CNVs in YSL61_batch1 ==
    
    == searching for CNVs in YSL62_batch1 ==
    
    == searching for CNVs in YSL63_batch1 ==
    
    == searching for CNVs in YSS21_batch1 ==
    
    == searching for CNVs in YSS22_batch1 ==
    
    == searching for CNVs in YSS23_batch1 ==
    
    == searching for CNVs in YT_batch1 ==
    
    == searching for CNVs in NK1617_batch2 ==
    
    == searching for CNVs in NK4142_batch2 ==
    
    == searching for CNVs in NK4748_batch2 ==
    
    == searching for CNVs in S1L53_batch2 ==
    
    == searching for CNVs in S1L73_batch2 ==
    
    == searching for CNVs in S6E11_batch2 ==
    
    == searching for CNVs in S6E13_batch2 ==
    
    == searching for CNVs in S6E21_batch2 ==
    
    == searching for CNVs in S6E23_batch2 ==
    
    == searching for CNVs in S6L51_batch2 ==
    
    == searching for CNVs in S6L53_batch2 ==
    
    == searching for CNVs in S6L61_batch2 ==
    
    == searching for CNVs in S6L63_batch2 ==
    
    == searching for CNVs in S6S21_batch2 ==
    
    == searching for CNVs in S6S22_batch2 ==
    
    == searching for CNVs in S6S23_batch2 ==
    
    == searching for CNVs in S1L53_batch3 ==
    
    == searching for CNVs in S1L73_batch3 ==
    
    == searching for CNVs in S6E11_batch3 ==
    
    == searching for CNVs in S6E21_batch3 ==
    
    == searching for CNVs in S6L51_batch3 ==
    
    == searching for CNVs in S6L61_batch3 ==
    
    == searching for CNVs in S6S21_batch3 ==
    
    == searching for CNVs in S6S22_batch3 ==
    



```R
#qseaSet@libraries
```


```R
qseaSet=addLibraryFactors(qseaSet)
qseaSet=addPatternDensity(qseaSet, "CG", name="CpG", fragment_length=200, fragment_sd=20)
qseaSet = addOffset(qseaSet, enrichmentPattern = "CpG")
```

    deriving TMM library factors for 79 samples
    
    Get genomic positions of "CG" ...
    
    Warning message in estimatePatternDensity(Regions = getRegions(qs), pattern = pattern, :
    “Masks selected but not found in BSGenome: AGAPS, AMB. 
    Consider using the .masked version of the package”
    searching chr1 for "CG"...
    
    found 2375159 occurances of CG in chr1
    
    estimating expected number of CGs per fragment for windows of chr1...
    
     ...done
    
    searching chr2 for "CG"...
    
    found 2192670 occurances of CG in chr2
    
    estimating expected number of CGs per fragment for windows of chr2...
    
     ...done
    
    searching chr3 for "CG"...
    
    found 1673293 occurances of CG in chr3
    
    estimating expected number of CGs per fragment for windows of chr3...
    
     ...done
    
    searching chr4 for "CG"...
    
    found 1503429 occurances of CG in chr4
    
    estimating expected number of CGs per fragment for windows of chr4...
    
     ...done
    
    searching chr5 for "CG"...
    
    found 1566535 occurances of CG in chr5
    
    estimating expected number of CGs per fragment for windows of chr5...
    
     ...done
    
    searching chr6 for "CG"...
    
    found 1511189 occurances of CG in chr6
    
    estimating expected number of CGs per fragment for windows of chr6...
    
     ...done
    
    searching chr7 for "CG"...
    
    found 1622825 occurances of CG in chr7
    
    estimating expected number of CGs per fragment for windows of chr7...
    
     ...done
    
    searching chr8 for "CG"...
    
    found 1338200 occurances of CG in chr8
    
    estimating expected number of CGs per fragment for windows of chr8...
    
     ...done
    
    searching chr9 for "CG"...
    
    found 1255728 occurances of CG in chr9
    
    estimating expected number of CGs per fragment for windows of chr9...
    
     ...done
    
    searching chr10 for "CG"...
    
    found 1388978 occurances of CG in chr10
    
    estimating expected number of CGs per fragment for windows of chr10...
    
     ...done
    
    searching chr11 for "CG"...
    
    found 1333114 occurances of CG in chr11
    
    estimating expected number of CGs per fragment for windows of chr11...
    
     ...done
    
    searching chr12 for "CG"...
    
    found 1315968 occurances of CG in chr12
    
    estimating expected number of CGs per fragment for windows of chr12...
    
     ...done
    
    searching chr13 for "CG"...
    
    found 842469 occurances of CG in chr13
    
    estimating expected number of CGs per fragment for windows of chr13...
    
     ...done
    
    searching chr14 for "CG"...
    
    found 895881 occurances of CG in chr14
    
    estimating expected number of CGs per fragment for windows of chr14...
    
     ...done
    
    searching chr15 for "CG"...
    
    found 906026 occurances of CG in chr15
    
    estimating expected number of CGs per fragment for windows of chr15...
    
     ...done
    
    searching chr16 for "CG"...
    
    found 1150891 occurances of CG in chr16
    
    estimating expected number of CGs per fragment for windows of chr16...
    
     ...done
    
    searching chr17 for "CG"...
    
    found 1248328 occurances of CG in chr17
    
    estimating expected number of CGs per fragment for windows of chr17...
    
     ...done
    
    searching chr18 for "CG"...
    
    found 756014 occurances of CG in chr18
    
    estimating expected number of CGs per fragment for windows of chr18...
    
     ...done
    
    searching chr19 for "CG"...
    
    found 1105620 occurances of CG in chr19
    
    estimating expected number of CGs per fragment for windows of chr19...
    
     ...done
    
    searching chr20 for "CG"...
    
    found 773477 occurances of CG in chr20
    
    estimating expected number of CGs per fragment for windows of chr20...
    
     ...done
    
    searching chr21 for "CG"...
    
    found 462299 occurances of CG in chr21
    
    estimating expected number of CGs per fragment for windows of chr21...
    
     ...done
    
    searching chr22 for "CG"...
    
    found 634646 occurances of CG in chr22
    
    estimating expected number of CGs per fragment for windows of chr22...
    
     ...done
    
    searching chrX for "CG"...
    
    found 1322709 occurances of CG in chrX
    
    estimating expected number of CGs per fragment for windows of chrX...
    
     ...done
    
    searching chrY for "CG"...
    
    found 225912 occurances of CG in chrY
    
    estimating expected number of CGs per fragment for windows of chrY...
    
     ...done
    
    selecting windows with low CpG density for background read estimation
    
    2.818% of the windows have enrichment pattern density of at most 0.01 per fragment 
    and are used for background reads estimation
    



```R
wd=which(getRegions(qseaSet)$CpG_density>1 &
           getRegions(qseaSet)$CpG_density<15)
signal=(15-getRegions(qseaSet)$CpG_density[wd])*.55/15+.25
```


```R
qseaSet_blind=addEnrichmentParameters(qseaSet, enrichmentPattern="CpG", 
                                      windowIdx=wd, signal=signal)

getOffset(qseaSet_blind, scale="fraction")
```


<style>
.dl-inline {width: auto; margin:0; padding: 0}
.dl-inline>dt, .dl-inline>dd {float: none; width: auto; display: inline-block}
.dl-inline>dt::after {content: ":\0020"; padding-right: .5ex}
.dl-inline>dt:not(:first-of-type) {padding-left: .5ex}
</style><dl class=dl-inline><dt>HANK1_batch1</dt><dd>0.260783639891674</dd><dt>KAI3_batch1</dt><dd>0.514904691500727</dd><dt>KHYG_batch1</dt><dd>0.386878703754868</dd><dt>MD11_batch1</dt><dd>0.445305501583311</dd><dt>NK92_batch1</dt><dd>0.483273518901607</dd><dt>NKS1_batch1</dt><dd>0.362209422336077</dd><dt>NKYS_batch1</dt><dd>0.324027566716733</dd><dt>S1E11_batch1</dt><dd>0.315605007469006</dd><dt>S1E12_batch1</dt><dd>0.278226327286938</dd><dt>S1E13_batch1</dt><dd>0.223160256290808</dd><dt>S1E21_batch1</dt><dd>0.325197359138661</dd><dt>S1E22_batch1</dt><dd>0.303283529206765</dd><dt>S1E23_batch1</dt><dd>0.418582373493428</dd><dt>S1L51_batch1</dt><dd>0.279385282366997</dd><dt>S1L52_batch1</dt><dd>0.344981566408407</dd><dt>S1L53_batch1</dt><dd>0.375215422912391</dd><dt>S1L71_batch1</dt><dd>0.294796377191592</dd><dt>S1L72_batch1</dt><dd>0.287527115959672</dd><dt>S1L73_batch1</dt><dd>0.431258960543637</dd><dt>S1S21_batch1</dt><dd>0.345635195613197</dd><dt>S1S22_batch1</dt><dd>0.362259170182586</dd><dt>S1S23_batch1</dt><dd>0.317772537222117</dd><dt>S6E11_batch1</dt><dd>0.402331151085339</dd><dt>S6E12_batch1</dt><dd>0.306781457399649</dd><dt>S6E21_batch1</dt><dd>0.469145817482668</dd><dt>S6E22_batch1</dt><dd>0.398245875123419</dd><dt>S6L51_batch1</dt><dd>0.366955535273054</dd><dt>S6L52_batch1</dt><dd>0.366170634283131</dd><dt>S6L61_batch1</dt><dd>0.513177172916534</dd><dt>S6L62_batch1</dt><dd>0.216668561277001</dd><dt>S6S21_batch1</dt><dd>0.388352069057339</dd><dt>S6S22_batch1</dt><dd>0.285495957439653</dd><dt>SNK1_batch1</dt><dd>0.419989585626827</dd><dt>SNK6_batch1</dt><dd>0.54441209324286</dd><dt>T1820_batch1</dt><dd>0.560892103205619</dd><dt>T2728_batch1</dt><dd>0.34847051967376</dd><dt>T4748_batch1</dt><dd>0.330262548306278</dd><dt>TON16_batch1</dt><dd>0.399581543726336</dd><dt>Undetermined_batch1</dt><dd>0.397929665965922</dd><dt>YSE11_batch1</dt><dd>0.332442409213756</dd><dt>YSE12_batch1</dt><dd>0.248481715732151</dd><dt>YSE13_batch1</dt><dd>0.377488323656576</dd><dt>YSE21_batch1</dt><dd>0.337721846193512</dd><dt>YSE22_batch1</dt><dd>0.304925625399666</dd><dt>YSE23_batch1</dt><dd>0.373153877903357</dd><dt>YSL51_batch1</dt><dd>0.220506311439244</dd><dt>YSL52_batch1</dt><dd>0.296908995885397</dd><dt>YSL53_batch1</dt><dd>0.342803117855548</dd><dt>YSL61_batch1</dt><dd>0.328756047252761</dd><dt>YSL62_batch1</dt><dd>0.300359878738876</dd><dt>YSL63_batch1</dt><dd>0.352659175790332</dd><dt>YSS21_batch1</dt><dd>0.355742901637022</dd><dt>YSS22_batch1</dt><dd>0.277097379535592</dd><dt>YSS23_batch1</dt><dd>0.325113818179096</dd><dt>YT_batch1</dt><dd>0.428710956595187</dd><dt>NK1617_batch2</dt><dd>0.254760361342303</dd><dt>NK4142_batch2</dt><dd>0.563453313388799</dd><dt>NK4748_batch2</dt><dd>0.241859585546518</dd><dt>S1L53_batch2</dt><dd>0.263938640145987</dd><dt>S1L73_batch2</dt><dd>0.301067848400789</dd><dt>S6E11_batch2</dt><dd>0.325330979594618</dd><dt>S6E13_batch2</dt><dd>0.436261514250578</dd><dt>S6E21_batch2</dt><dd>0.387502590682189</dd><dt>S6E23_batch2</dt><dd>0.363643528595393</dd><dt>S6L51_batch2</dt><dd>0.301681337678221</dd><dt>S6L53_batch2</dt><dd>0.350967600393695</dd><dt>S6L61_batch2</dt><dd>0.286716591284511</dd><dt>S6L63_batch2</dt><dd>0.337286646515197</dd><dt>S6S21_batch2</dt><dd>0.291816245390704</dd><dt>S6S22_batch2</dt><dd>0.246013073796619</dd><dt>S6S23_batch2</dt><dd>0.380505415553419</dd><dt>S1L53_batch3</dt><dd>0.372353135404057</dd><dt>S1L73_batch3</dt><dd>0.413749665949658</dd><dt>S6E11_batch3</dt><dd>0.465336887305509</dd><dt>S6E21_batch3</dt><dd>0.608899271085906</dd><dt>S6L51_batch3</dt><dd>0.462812419439184</dd><dt>S6L61_batch3</dt><dd>0.408348259153499</dd><dt>S6S21_batch3</dt><dd>0.414886902142875</dd><dt>S6S22_batch3</dt><dd>0.378929480570055</dd></dl>




```R
##save the qseaSet
setwd(outDir)
#write.table(final_list, "Remove_low-quality-samples_final_list_122024.txt", sep="\t", quote = FALSE, row.names=F, col.names = T)
save(qseaSet, file = "qseaSet_merged_bam.RData") 
save(qseaSet_blind, file = "qseaSet_blind_merged_bam.RData") 
```


```R
setwd(outDir)
write.table(samples_list, "samples_list__merged_bam_082025.txt", sep="\t", quote = FALSE, row.names=F, col.names = T)
```


```R
load("qseaSet.RData")
load("qseaSet_blind.RData")
```
