#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(pheatmap)
#library(ggplot2)
library(limma)
#library(plotly)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  exprs.m<-reactive({
    if(input$data_type=='methy'){
      #Load methylation matrix
      data=read.csv('./READ_1918_methy.csv',header = T)
      METHY_MAT=data[,-1]
      rownames(METHY_MAT)=data[,1]
      colnames(METHY_MAT)=substr(colnames(METHY_MAT),1,12)
      return(METHY_MAT)
    }
    if(input$data_type=='exp'){
      #Load expression matrix
      data=read.csv('./READ_1918_exp.csv',header = T)
      EXP_MAT=log2(data[,-1]+1)
      rownames(EXP_MAT)=data[,1]
      colnames(EXP_MAT)=substr(colnames(EXP_MAT),1,12)
      return(EXP_MAT)
    }
  })
  anotation.m<-reactive({
    #Load anotation matrix
    ano_mat=read.table('./clinical_patient_READ.txt',header = T,sep = '\t',quote='')
    ANO_COL=ano_mat[,c(-1)]
    row.names(ANO_COL)=gsub('-','.',ano_mat[,1],fixed = T)
    return(ANO_COL)
  })
  
  #Dynamic UI
  #PREVIEW
  output$genelist<-renderUI({
    #if(is.null(input$data_pre)){return(NULL)}
    #Load gene data
    genelist=rownames(exprs.m())
    textInput("genelist", label = h3("Input a genelist split by comma,eg:TP53"), value = paste(genelist[1:4],collapse=','))
    #Multiple Selection
    #selectInput('genelist','GeneList',c('ALL',genelist),selected = 'ALL',multiple = TRUE)
  })
  output$phenotypelist<-renderUI({
    #if(is.null(input$feature_pre)){return(NULL)}
    #Load phenotype data
    phenotype <- colnames(anotation.m())
    selectInput('phenotypelist','Plz select the clinical features',phenotype,multiple=TRUE,selected = phenotype[1])
  })
  #Make a download widget
  output$downloadheat<-downloadHandler(
    filename = function() {
      paste('heatmap-', Sys.Date(),'.pdf', sep='')
    },
    # a function that actually opens a connection to a pdf and print the result to it
    content = function(FILE) { # this function must take at least an input variable, namely the filename of the file to save
      pdf(file=FILE, onefile=T)
      ano_col=subset(anotation.m(),select=input$phenotypelist)
      #Split the genelist Need add unlist 
      genelist=unlist(strsplit(input$genelist,','))
      if('ALL' %in% genelist){pheatmap(exprs.m(),annotation_col = ano_col)}
      else{pheatmap(exprs.m()[genelist,],annotation_col = ano_col)}
      dev.off()
    }
  )
  ###Filter
  output$phenotype_test<-renderUI({
    if(is.null(input$phenotypelist)){return()}
    #Load phenotype data
    phenotype <- colnames(anotation.m())
    if(length(input$phenotypelist)==1){selectInput('phenotype_test','Clinical features',phenotype,selected = input$phenotypelist)}
    else{selectInput('phenotype_test','Clinical features',phenotype,selected = input$phenotypelist[-1])}
  })
  output$filtergene_count<-renderUI({
    if(is.null(input$phenotypelist)){return()}
    sliderInput('filtergene_count','Filtered gene counts by selected phenotype pvalue(Low to high)',min=1,max=50,value=10)
  })
  
  
  #Make heatmap
  output$pre_heatmap<-renderPlot({
    if(is.null(input$phenotypelist)){return()}
    #Take annotation column
    ano_col=subset(anotation.m(),select=input$phenotypelist)
    #Split the genelist Need add unlist 
    genelist=unlist(strsplit(input$genelist,','))
    if(length(genelist)<2){return()}
    else{
      if(length(genelist)>10){showrow=F}else{showrow=T}
      if(length(rownames(ano_col))>10){showcol=F}else{showcol=T}
      return(pheatmap(exprs.m()[genelist,],annotation_col = ano_col,show_rownames = showrow,show_colnames = showcol))
    }
  })
  #Plot Feature frequency
  output$Feature_Barplot<-renderPlot({
    if(is.null(input$phenotypelist)){return()}
    #Load donorID
    donorId=colnames(exprs.m())
    #Load pheno type make barplot and test  
    ano_col=subset(anotation.m()[donorId,],select=input$phenotypelist)
    for (pheno in input$phenotypelist){
      xx=barplot(table(ano_col[pheno]),col = rainbow(length(table(ano_col[pheno]))),main=paste0('Barplot for ',pheno))
      yy=table(ano_col[pheno])
      text(xx,yy/2,yy)         
    }
  })
  output$phenodemo<-DT::renderDataTable({
    if(is.null(input$phenotypelist)){return()}
    #Load donorID
    donorId=colnames(exprs.m())
    #Load pheno type make barplot and test  
    ano_col=subset(anotation.m()[donorId,],select=input$phenotypelist)
    DT::datatable(ano_col)
  })
  gene_mat<-reactive({
    if(is.null(input$phenotype_test))return()
    #Load donorID
    donorId=colnames(exprs.m())
    gene_mat=data.frame(Mean=apply(exprs.m(),1,mean))
    
    #Load pheno type make barplot and test  
    ano_col=subset(anotation.m()[donorId,],select=input$phenotype_test)
    for(pheno in input$phenotype_test){
      if(length(levels(ano_col[pheno][,1]))==2){gene_mat[paste0(pheno,'-pvalue')]=apply(exprs.m(),1,function(x) wilcox.test(x~ano_col[pheno][,1])$p.value)}
      else{gene_mat[paste0(pheno,'-pvalue')]=apply(exprs.m(),1,function(x) kruskal.test(x~ano_col[pheno][,1])$p.value)}
      #Limit feature level counts
      if(length(levels(ano_col[pheno][,1]))<=3){
        for(value in levels(ano_col[pheno][,1])){
          gene_mat[paste0(value,'-Mean')]=apply(exprs.m(),1,function(x) mean(x[which(ano_col[pheno]==value)]))
        }
      }
      pheno.v <- ano_col[,pheno]
      left.idx <- which(!is.na(pheno.v))
      phenoORI.v <- pheno.v
      pheno.v <- pheno.v[left.idx]
      data.m <- exprs.m()[, left.idx]
      sampletype.f <- as.factor(pheno.v);
      design.sample <- model.matrix(~ sampletype.f );
      colnames(design.sample) <- levels(sampletype.f);
      ### linear model fit
      lmf.o <- lmFit(data.m,design.sample);
      ### empirical Bayesian estimation of differentially expressed genes (DEGs)
      bay.o <- eBayes(lmf.o);
      ### build ranked list of DEGs
      results <- topTable(bay.o,coef=2,adjust.method='fdr',number=Inf)[,c(1,4,5)];
      gene_mat[paste0(pheno,'-logFC')]=results$logFC
      #gene_mat[paste0(pheno,'-adj.P.Val')]=results$adj.P.Val
    }
    gene_mat
  })
  output$genedemo<-DT::renderDataTable({
    if(is.null(input$phenotype_test)){return()}
    DT::datatable(gene_mat())
  })
  res_select<-reactive({
    if(is.null(input$cluster)|is.null(input$phenotype_test)){return()}
    #Load donorID
    donorId=colnames(exprs.m())
    #Load select phenotype and gene count
    gene_index=order(gene_mat()[paste0(input$phenotype_test,'-pvalue')])[c(1:input$filtergene_count)]
    ano_col=subset(anotation.m()[donorId,],select=input$phenotype_test)
    if(length(rownames(ano_col))>10){showcol=F}else{showcol=T}
    pheatmap(exprs.m()[gene_index,],annotation_col = ano_col,cutree_cols = input$cluster,cutree_rows = input$cluster,show_colnames = showcol)
  })
  output$heatmap_selected<-renderPlot({
    res_select()
  })
  output$downloadData<- downloadHandler(
    filename = function() { 
      paste(paste0('READ_',input$phenotype_test), '.csv', sep='') 
    },
    content = function(file) {
      index=order(gene_mat()[paste0(input$phenotype_test,'-pvalue')])
      write.csv(gene_mat()[index,], file)
    }
  )

})
