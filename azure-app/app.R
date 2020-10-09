#
# Pretty Version
# Shinyapps.io Azure SQL Connection App
#

library(shiny)
library(odbc)
library(config)
library(DBI)
library(glue)
library(dplyr)


conn_args <- config::get("dataconnection")

con <- dbConnect(odbc::odbc(),
                 Driver = conn_args$driver, 
                 Server = conn_args$server, 
                 UID = Sys.getenv("userid"), 
                 PWD = Sys.getenv("pwd"), 
                 Port = conn_args$port, 
                 Database = conn_args$database
)

product_categories <- dbGetQuery(con, "SELECT pc.Name as CategoryName, pc.ProductCategoryID as ID FROM SalesLT.ProductCategory pc")


ui <- fluidPage(
    
                titlePanel("Shiny + Azure SQL Bike Store Explorer"),
                
                sidebarLayout(
                    sidebarPanel(
                        h3('Connect to a SQL Server Database in Microsoft Azure'),
                        hr(),
                        p('This Shiny application connects to a SQL Server database seeded with sample data available from Microsoft Azure.'),
                        p('To reproduce this application, follow the Quickstart guide to first set up a database.'),
                        tags$strong('Resources:'),
                        tags$ul(
                            tags$li(tags$a(href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-get-started-portal", 
                                           "Quickstart: Create an Azure SQL Database")),
                            tags$li(tags$a(href="https://db.rstudio.com/best-practices/portable-code/", 
                                           "Database Best Practices for RStudio"))
                        ),
                        hr(),
                        HTML('<center><img src="rstudio.png"></center>')
                    ),
                    
                    mainPanel(
                        br(),
                        fluidRow(
                            column(6,
                                   selectInput("category", "Select a Product Category:", choices = product_categories$CategoryName)
                            ),
                            column(3,
                                   HTML('<center><img src="azure-sql-img.png" height="100"></center>')
                            ),
                            column(3,
                                   HTML('<center><img src="bicycle.png" height="100"></center>')
                            )
                        ),
                        tabsetPanel(
                            tabPanel("Inventory",
                                     br(),
                                     dataTableOutput("products")
                            ),
                            tabPanel("Sales Reports"),
                            tabPanel("Order Tracker")
                        )
                    )
                )
)

server <- function(input, output) {
    
    cat_id <- reactive({
        cat_row <- product_categories %>% filter(CategoryName == !!input$category)
        cat_row$ID
    })
    
    output$products <- renderDataTable({
        product_sql <- glue_sql("SELECT ProductID, Name, ProductNumber, Color, ListPrice 
                                FROM SalesLT.Product WHERE ProductCategoryID = ?")
        get_products <- dbSendQuery(con, product_sql)
        dbBind(get_products, cat_id())
        dbFetch(get_products)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
