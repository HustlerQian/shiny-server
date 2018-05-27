#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(visNetwork)
library(stringr)
# Define server logic required to draw a visnetwork
shinyServer(function(input, output) {
  
  net.df <- reactive({
    req(input$Input)
    #net.df <- read.csv('./demo_data/CHOL.csv',header = T,stringsAsFactors = F)
    net.df <- read.csv(input$Input$datapath,
                       header = T,
                       stringsAsFactors = F)
    colnames(net.df) <- c("group",  "P_name", "S_name", "n")
    return(net.df)
    }
  )
  
  output$Network <- renderVisNetwork({
    req(input$Input)
    chol <- net.df()
    
    #Nodes df
    cancer=unique(chol$group)
    gene=unique(chol$S_name)
    chol_node=data.frame(name=c(cancer,gene),
                         group=c(rep('cancer',length(cancer)),rep('gene',length(gene))),
                         size=10
    )
    chol_node$id=0:(nrow(chol_node)-1)
    chol_node$label=chol_node$name
    chol_node_dic=chol_node
    rownames(chol_node_dic)=chol_node_dic$name
    #Make edge
    chol_edge <- chol
    chol_edge$from <- chol_node_dic[chol$S_name,'id']
    chol_edge$to <- chol_node_dic[chol$group,'id']
    chol_edge$color <- chol_edge$P_name
    chol_edge$value <- chol_edge$n
    ##Use relation for specifying the edge color
    table(chol_edge$P_name)
    chol_edge$color=str_replace_all(chol_edge$color,'AFFECTS','#EF476F')
    chol_edge$color=str_replace_all(chol_edge$color,'ASSOCIATED_WITH','#06D6A0')
    chol_edge$color=str_replace_all(chol_edge$color,'AUGMENTS','#BA5A31')
    chol_edge$color=str_replace_all(chol_edge$color,'CAUSES','#118AB2')
    chol_edge$color=str_replace_all(chol_edge$color,'DISRUPTS','#073B4C')
    chol_edge$color=str_replace_all(chol_edge$color,'PREVENTS','#FAEA77')
    chol_edge$color=str_replace_all(chol_edge$color,'TREATS','#B7B3B3')
    
    ledges <- data.frame(color = unique(chol_edge$color),
                         label = unique(chol_edge$P_name), 
                         arrows =rep("to", length(unique(chol_edge$color))))
    #Make visnetwork to view
    cancer_chol_network<-visNetwork(chol_node, chol_edge, height = "1000px", width = "100%")%>%
      #Add group with color
      visGroups(groupname = "cancer", color = "#F45B24") %>%
      visGroups(groupname = "gene", color = "#547B94") %>%
      visPhysics(stabilization = T)%>%
      visLegend(addEdges = ledges)
    cancer_chol_network
  })
  
})
