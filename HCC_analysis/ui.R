#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
#library(ggplot2)

shinyUI(fluidPage(
  
  # Application title
  titlePanel("Cluster analysis for Liver Cancer"),
  tabPanel('All',
           column(3,
                  wellPanel(
                    selectInput('data_type','Plz choose a data type',c('Expression'='exp','Methylation'='methy'),selected = 'methy'),
                    conditionalPanel(
                      condition='input.conditionedPanels=="tabpre"',
                      uiOutput('genelist')),
                    conditionalPanel(
                      'input.conditionedPanels=="tabpre"',
                      uiOutput('phenotypelist')),
                    conditionalPanel('input.phenotypelist && input.conditionedPanels=="tabpre"',
                                     p('Download heatmap for which you selected'),
                                     downloadButton('downloadheat', 'Download')),
                    conditionalPanel('input.phenotypelist|input.conditionedPanels=="tabpre"',plotOutput('Feature_Barplot')),              
                    conditionalPanel('input.conditionedPanels=="tabgenes"',sliderInput('cluster','Cluster Count',min=2,max = 6,value=2)),             
                    conditionalPanel(
                      'input.conditionedPanels=="tabgenes"',
                      uiOutput('phenotype_test')),
                    conditionalPanel(
                      'input.conditionedPanels=="tabgenes"',
                      uiOutput('filtergene_count')
                      )
                  )),
           column(9,
                  textOutput('input.conditionedPanels'),
                  mainPanel(
                    tabsetPanel(
                      tabPanel('Preview','Preview',
                               plotOutput('pre_heatmap'),
                               DT::dataTableOutput('phenodemo'),
                               value='tabpre'
                      ),
                      tabPanel('Filter','Selected genes',
                               plotOutput('heatmap_selected'),
                               DT::dataTableOutput('genedemo'),
                               downloadButton('downloadData', 'Download'),
                               value='tabgenes'
                      ),
                      id = "conditionedPanels",selected = 'tabgenes')
                  )
           )
  )
)
)
