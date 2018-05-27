library(timevis)


########Server START#########

# Define server logic required to draw a HCC knowledge
shinyServer(function(input, output,session) {

  ####Filtering_Reactiving data######
  #Rdf
  rdf<-reactive({
    rdf=read.csv('./Predication.csv',header = T,stringsAsFactors = F)
    rdf=rdf %>% separate(P_id,c('pmid','p_no'),sep='[.]')
    rdf$pmid=substr(rdf$pmid,2,nchar(rdf$pmid))
    #Select by filter Widgets
    #Filter by Relationship
    rdf=rdf[which(rdf$P_name %in% input$Relation),]
    #Filter by Group
    rdf=rdf[which(rdf$S_SMTY %in% groups()),]
    rdf=rdf[which(rdf$O_SMTY %in% groups()),]
    rdf
  })
  #Nodes
  nodes<-reactive({
    rdf=rdf()
    #Make group dictionary
    group_dic=data.frame(name=c(rdf$S_name,rdf$O_name),group=c(rdf$S_SMTY,rdf$O_SMTY),stringsAsFactors = F)
    group_dic_uniq=group_dic[!duplicated(group_dic$name),]
    rownames(group_dic_uniq)=group_dic_uniq$name
    #group_dic_uniq=group_dic[rownames(unique(subset(group_dic,select='name'))),]
    
    
    test=data.frame(name=c(rdf$S_name,rdf$O_name),cui=c(rdf$S_cui_entrezid,rdf$O_cui_entrezid),stringsAsFactors = F)
    #Unique by name
    nodes=test[!duplicated(test$name),]
    nodes$group=group_dic_uniq[nodes$name,'group']
    nodes$id=0:(nrow(nodes)-1)
    nodes$label=nodes$name
    #write.csv(x=nodes,file = 'nodes.csv')
    nodes
  })
  #Links
  links<-reactive({
    rdf=rdf()
    #Make nodes_dic
    nodes_dic=nodes()
    rownames(nodes_dic)=nodes()$name
    nodes_dic$name=0:(nrow(nodes())-1)
    
    links=data.frame(S_name=rdf$S_name,O_name=rdf$O_name,label=rdf$P_name,
                     #For prediction custom hovering text
                     title=paste0("<p><a href='http://www.ncbi.nlm.nih.gov/pubmed/?term=",
                                  rdf$pmid,"' target='_blank'>",
                                  rdf$Proof,
                                  #"See more.
                                  "</br></a><font color='red'>",
                                  rdf$S_raw,"</font> <font color='blue'>",
                                  rdf$P_raw,"</font> <font color='green'>",
                                  rdf$O_raw,"</font></p>"
                                  ),stringsAsFactors = F)
    links$from=nodes_dic[links$S_name,'name']
    links$to=nodes_dic[links$O_name,'name']
    links$arrows = 'to'
    links$color=rdf$P_type
    #Give id for shiny selection
    links$id=0:(nrow(links)-1)
    #write.csv(x=links,file = 'links.csv')
    links
  })
  #Groups
  groups<-reactive({
    if(!is.null(input$Group)){
      return(input$Group)
    }else{
      return(c('neop','gngm'))
    }
  })
  #####UI output#######
  output$Group<-renderUI({
    if(is.null(input$Relation)){return()}
     group=unique(nodes()$group)
     group=group[!is.na(group)]
     selectInput('Group','Group:',group,selected = c('neop','gngm'),multiple = T)

  })
  #####INTRO SECTION#######
  output$timeline_bigpic <- renderTimevis({
    TL_bigpic=read.csv(normalizePath('./timeline_bigpics.csv'),header = T)
    timevis(TL_bigpic)
  })
  
  #####SEARCH SECTION#######
  output$wiki <- renderUI({
    wikiinfo=readLines(normalizePath(paste0('./wikiinfobox/',input$Gene_Search,'.txt')))
    HTML(wikiinfo)
  })
  
  ######GRAPH SECTION#######
  #Network
  output$Network <- renderVisNetwork({
    #Make edges for network plotting
    #Selection of Relation then filter the nodes
    edges=links()
    edges.palette=brewer.pal(9,"Set1")
    index=0
    for (i in levels(factor(edges$label))){
      index=index+1
      edges[which(edges$label==i),]$color=edges.palette[index]
    }
    edges$title=NA
    edges=edges[!duplicated(paste0(edges$S_name,edges$O_name)),]
    edges$label=NA
    #Make nodes for network plotting
    nodes.df=nodes()[which(nodes()$group %in% groups()),]
    nodes.df$shape=NA
    nodes.df$color=NA
    shapetype=c('square','triangle','circle')
    nodes.palette=brewer.pal(12,"Set3")
    lnodes=data.frame(label=groups(),shape=NA,color=NA)
    index=0
    for (i in levels(factor(groups()))){
      index=index+1
      nodes.df[which(nodes.df$group==i),]$shape=shapetype[index %% 3]
      nodes.df[which(nodes.df$group==i),]$color=nodes.palette[index]
      lnodes[which(lnodes$label==i),]$shape=shapetype[index %% 3]
      lnodes[which(lnodes$label==i),]$color=nodes.palette[index]
    }
    nodes.df$name=gsub(',','',nodes.df$name)
    nodes.df$label=gsub(',','',nodes.df$label)
    
    #Vis network interaction
    withProgress(message = 'Creating plot', value = 0.1, {
      Sys.sleep(0.25)
      ntwk=visNetwork(nodes.df, edges, height = "800px", width = "100%") %>% 
      visLegend(addEdges = data.frame(label=unique(edges$label),
                                      color=edges.palette[1:length(unique(edges$label))]),
                addNodes = lnodes,
                useGroups = F,ncol = 2) %>%
      visExport(type = "pdf") %>%
      visOptions( nodesIdSelection = TRUE,selectedBy = "group")
    #For navigationwidgets  
    #%>%
     # visInteraction(navigationButtons = TRUE)
      Sys.sleep(0.25)
    })
    ntwk
  })
  #Dygraph
  output$Trend <- renderDygraph({
    dygraph(nhtemp, main = "Trend for this graph") %>% 
      dyRangeSelector(dateWindow = c("1920-01-01", "1960-01-01"))
  })
  #Debug
  output$debug <- renderPrint({
    id=input$Network_selected
    nodes()[which(nodes()$id==id),]$name
    #paste("Current node selection : ", input$Network_selected)
  })
  #Infobox
  output$prooflist <- renderUI({
    id=input$Network_selected
    links=links()
    
    nodes.df=nodes()[which(nodes()$group %in% groups()),]
    outindex=nodes()[which(nodes()$group %in% groups()),]$name
    name=nodes.df[which(nodes.df$id==id),]$name
    #print(name)
    proof.df=rbind(links[which(links$S_name==name),],links[which(links$O_name==name),])
    #print(proof.df)
    #proof.df=proof.df[!which(proof.df$S_name %in% outindex),]
    #proof.df=proof.df[!which(proof.df$O_name %in% outindex),]
    proof.html=proof.df$title
    title_list=paste(proof.html,sep=' <br><hr>')
    HTML(title_list)
  })
  ######BARPLOT SECTION########
  #Predication
  output$barplot_relation <- renderPlot({
    #Set margin for plot
    par(mar=c(11,4,4,4))
    #barplot and store the x location
    x=barplot(table(links()$label),
              las=2,
              col = c('red','blue','yellow','green'),
              main = 'Count for Prediction'
              )
    #Annotation
    text(x,table(links()$label)/2,table(links()$label))
  })
  #Semantic type
  output$barplot_group <- renderPlot({
    #Set margin for plot
    par(mar=c(6,4,4,4))
    #barplot and store the x location
    x=barplot(table(nodes()$group),
              las=2,
              col = c('red','blue','yellow','green'),
              main = 'Count for Group'
    )
    #Annotation
    text(x,table(nodes()$group)/2,table(nodes()$group))
  })
  #Entity in gene
  output$barplot_gene <- renderPlot({
    par(mar=c(11,4,4,4))
    links=links()
    nodesindex=nodes()[which(nodes()$group %in% c('gngm')),]$name
    gene=data.frame(entity=c(links[which(links$S_name %in% nodesindex),]$S_name,links[which(links$O_name %in% nodesindex),]$O_name))
    #print(table(gene$entity))
    x=barplot(table(gene$entity),
              las=2,
              col = c('red','blue','yellow','green'),
              main = 'Count for Gene'
    )
    #Annotation
    text(x,table(gene$entity)/2,table(gene$entity))
  })
  #Entity in neop
  output$barplot_neop <- renderPlot({
    par(mar=c(11,4,4,4))
    links=links()
    nodesindex=nodes()[which(nodes()$group %in% c('neop')),]$name
    neop=data.frame(entity=c(links[which(links$S_name %in% nodesindex),]$S_name,links[which(links$O_name %in% nodesindex),]$O_name))
    #print(table(neop$entity))
    x=barplot(table(neop$entity),
              las=2,
              col = c('red','blue','yellow','green'),
              main = 'Count for Neop'
    )
    #Annotation
    text(x,table(neop$entity)/2,table(neop$entity))
  })
  ######DATATABLE SECTION#######
  output$links.dt <- renderDataTable({
    #nodes()
    edges=links()
    edges.palette=brewer.pal(9,"Set1")
    index=0
    for (i in levels(factor(edges$label))){
      index=index+1
      edges[which(edges$label==i),]$color=edges.palette[index]
    }
    edges
  })
  output$edges.dt <- renderDataTable({
    nodes.df=nodes()[which(nodes()$group %in% groups()),]
    nodes.df$shape=NA
    shapetype=c('square','triangle','circle')
    index=0
    for (i in levels(factor(groups()))){
      index=index+1
      nodes.df[which(nodes.df$group==i),]$shape=shapetype[index %% 3]
    }
    nodes.df
  })
})
