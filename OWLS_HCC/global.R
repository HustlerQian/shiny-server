rm(list=ls())
#########Library#######
#.libPaths(c(normalizePath('./lib/'),.libPaths()))
library(shiny)
library(visNetwork)
library(shinydashboard)
library(timevis)
library(DT)
library(dygraphs)
library(tidyr)
library(shinyWidgets)
library(RColorBrewer)
#####Data#######
#Genelist
genelist.df=read.csv('./Genelist.csv',header = T,stringsAsFactors = F)

#Make raw RDF data
rdf_raw=read.csv('./Predication.csv',header = T,stringsAsFactors = F)
#Make raw Relation and raw group
Relation_raw=unique(rdf_raw$P_name)

#rdf=read.csv('./Predication.csv',header = T,stringsAsFactors = F)

#group_dic=data.frame(name=c(rdf_raw$S_name,rdf_raw$O_name),group=c(rdf_raw$S_SMTY,rdf_raw$O_SMTY),stringsAsFactors = F)



# rdf_raw=rdf_raw %>% separate(P_id,c('pmid','p_no'),sep='[.]')
# rdf_raw$pmid=substr(rdf_raw$pmid,2,nchar(rdf_raw$pmid))
# links=data.frame(S_name=rdf_raw$S_name,O_name=rdf_raw$O_name,label=rdf_raw$P_name,
#                  #For prediction custom hovering text
#                  title=paste0("<p><a href='http://www.ncbi.nlm.nih.gov/pubmed/?term=",
#                               rdf_raw$pmid,"' target='_blank'>",rdf_raw$Proof,"</br></a><font color='red'>",
#                               rdf_raw$S_raw,"</font> <font color='blue'>",rdf_raw$P_raw,"</font> <font color='green'>",rdf_raw$O_raw,"</font></p>"),stringsAsFactors = F)
# 
# test=data.frame(name=c(rdf_raw$S_name,rdf_raw$O_name),cui=c(rdf_raw$S_cui_entrezid,rdf_raw$O_cui_entrezid),stringsAsFactors = F)
# #Unique by name
# nodes=test[!duplicated(test$name),]
# 
# #Make data description
# nodes_dic=nodes
# rownames(nodes_dic)=nodes$name
# nodes_dic$name=0:(nrow(nodes)-1)
# 
# group_dic_uniq=group_dic[rownames(unique(subset(group_dic,select='name'))),]