# Life Expectancy in Europe (Shiny App)

This Shiny application provides an interactive map showing average life expectancy at birth across Europe from 1900 to 2009.  
Users can explore trends over time using a year slider, and the map dynamically updates to display country-level life expectancy.

---

## Features
- Year slider to select any year between 1900 and 2009.
- Interactive choropleth map of Europe, coloured by life expectancy:
  - Red indicates lower life expectancy.
  - Green indicates higher life expectancy.
- Hover tooltips display country names and exact life expectancy values.
- Animated playback to visualise changes over time.

---

## Data Sources
- **Life Expectancy Data:**  
  [Our World in Data](https://ourworldindata.org/life-expectancy)  
  Data compiled from:
  - Human Mortality Database  
  - Clio-Infra (Zijdeman et al.) for pre-1950 estimates  
  - United Nations World Population Prospects (1950 onwards)
- **Geospatial Data:**  
  [Natural Earth](https://www.naturalearthdata.com/) country boundaries via the **rnaturalearth** R package.

---

## Installation and Setup

### 1. Clone the repository
```bash
git clone https://github.com/<anguscsd>/<European-Life-Expectancy-Shiny>.git
cd <European-Life-Expectancy-Shiny>



