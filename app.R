install.packages(c("shiny","leaflet","dplyr","readr","sf","rnaturalearth","rnaturalearthdata","bslib","htmltools"))

library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(bslib)
library(htmltools)

# ---- Load geographic data (Europe polygons) ----
# Natural Earth via rnaturalearth (public domain)
eu_sf <- rnaturalearth::ne_countries(scale = 50, returnclass = "sf")
# Keep countries in the UN "Europe" region or the "Europe" continent
eu_sf <- eu_sf %>%
  filter(region_un == "Europe" | continent == "Europe") %>%
  st_as_sf()

# We'll focus the map on a bbox over Europe
eu_bbox <- list(lng1 = -25, lat1 = 34, lng2 = 45, lat2 = 72)

# ---- Load life expectancy data (OWID grapher) ----
life_url <- "https://ourworldindata.org/grapher/life-expectancy.csv"
life_raw <- readr::read_csv(life_url, show_col_types = FALSE)

# Make names syntactic and find the value column robustly
names(life_raw) <- make.names(names(life_raw))
val_col <- setdiff(names(life_raw), c("Entity", "Code", "Year"))[1]
names(life_raw)[names(life_raw) == val_col] <- "life_expectancy"

# Restrict to European ISO3 codes we actually have on the map, and target years
eu_codes <- unique(eu_sf$iso_a3)
life_eu <- life_raw %>%
  filter(Code %in% eu_codes, Year >= 1900, Year <= 2009)

# Use a stable legend/domain across the whole 1900–2009 period
legend_domain <- range(life_eu$life_expectancy, na.rm = TRUE)

# ---- UI ----
ui <- fluidPage(
  theme = bs_theme(bootswatch = "flatly"),
  tags$head(
    tags$style(HTML("
      body { font-family: system-ui, -apple-system, Segoe UI, Roboto, 'Helvetica Neue', Arial, 'Noto Sans', 'Apple Color Emoji', 'Segoe UI Emoji'; }
      .app-title { font-weight: 700; font-size: 24px; margin: 10px 0 2px; }
      .subtitle { color: #6c757d; margin-bottom: 16px; }
      .panel { background: #ffffff; border-radius: 16px; box-shadow: 0 6px 18px rgba(0,0,0,0.06); padding: 16px; }
      .leaflet-container { border-radius: 16px; box-shadow: 0 6px 18px rgba(0,0,0,0.06); }
      .data-note { font-size: 13px; color: #495057; }
      .footer { font-size: 12px; color: #6c757d; margin-top: 8px; }
    "))
  ),
  div(class = "app-title", "Europe: Life Expectancy at Birth"),
  div(class = "subtitle", "Use the slider to explore 1900–2009. Red = lower; green = higher."),
  fluidRow(
    column(
      width = 3,
      div(class = "panel",
          sliderInput(
            "year", "Year",
            min = 1900, max = 2009, value = 2000, step = 1,
            animate = animationOptions(interval = 1200, loop = TRUE)
          ),
          div(class = "data-note",
              HTML(
                "<strong>About the data</strong><br/>
                This map shows <em>period life expectancy at birth</em> (years) by country. 
                Values are compiled by <a href='https://ourworldindata.org/life-expectancy' target='_blank'>Our World in Data</a> 
                from the Human Mortality Database &amp; Zijdeman et&nbsp;al. for pre-1950 estimates and the 
                <a href='https://population.un.org/wpp/' target='_blank'>UN World Population Prospects</a> from 1950 onward. 
                Country borders © <a href='https://www.naturalearthdata.com/' target='_blank'>Natural Earth</a> via the {rnaturalearth} R package."
              )
          ),
          div(class = "footer",
              "Tip: press play to animate through the years.")
      )
    ),
    column(
      width = 9,
      leafletOutput("map", height = 650)
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  
  # Join life expectancy for the selected year to European polygons
  map_data <- reactive({
    life_year <- life_eu %>% filter(Year == input$year)
    # Join by ISO3; many OWID codes match Natural Earth iso_a3
    eu_sf %>%
      left_join(life_year, by = c("iso_a3" = "Code"))
  })
  
  output$map <- renderLeaflet({
    md <- map_data()
    
    pal <- colorNumeric(
      palette = colorRampPalette(c("#d7191c", "#1a9641"))(256), # red -> green
      domain = legend_domain,
      na.color = "#e0e0e0"
    )
    
    labels <- sprintf(
      "<strong>%s</strong><br/>%s",
      htmlEscape(md$name_long),
      ifelse(is.na(md$life_expectancy), "No data", sprintf("%.1f years", md$life_expectancy))
    ) %>% lapply(HTML)
    
    leaflet(md, options = leafletOptions(minZoom = 2, worldCopyJump = TRUE)) %>%
      addProviderTiles(providers$CartoDB.Positron, options = providerTileOptions(opacity = 0.8)) %>%
      addPolygons(
        fillColor = ~pal(life_expectancy),
        weight = 0.6, color = "#555555", opacity = 1,
        fillOpacity = 0.9,
        label = labels,
        highlight = highlightOptions(weight = 2, color = "#000000", fillOpacity = 0.95, bringToFront = TRUE),
        smoothFactor = 0.2
      ) %>%
      addLegend(
        "bottomright", pal = pal, values = legend_domain,
        title = "Life expectancy at birth (years)",
        labFormat = labelFormat(suffix = " yrs"),
        opacity = 0.9
      ) %>%
      fitBounds(lng1 = eu_bbox$lng1, lat1 = eu_bbox$lat1, lng2 = eu_bbox$lng2, lat2 = eu_bbox$lat2)
  })
}

shinyApp(ui, server)
