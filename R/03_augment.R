rm(list = ls())

library(tidyverse)
source('R/99_proj_func.R')

# Load clean data
data_clean <- read_csv("data/02_data_clean.csv")
data_new <- read_csv("data/02_data_new_clean.csv")


# Join data ---------------------------------------------------------------
data_aug <- data_clean %>% 
  full_join(data_new) %>% 
  replace(list = is.na(.), values = 0)

# Rename colnames to only contain abbreviations
colnames(data_aug) <- str_split(string = colnames(data_aug),
                                pattern = " \\(",
                                simplify = TRUE)[, 1] %>%
   str_replace(pattern = "-toxin", replacement = "toxin")


# Group toxins ------------------------------------------------------------
SVMPs <- data_aug %>% 
  select(ends_with('SVMP'))

disintegrins <- data_aug %>% 
  select(ends_with('disintegrin'))

lectins <- data_aug %>% 
  select(CTL, Selectins, Gal)

FTx3 <- data_aug %>% 
  select(contains('NTx'), `3Ftx`, Muscarinictoxin, Mojavetoxin, `beta-BTx`)

PLA2s <- data_aug %>% 
  select(contains('PLA2'))

VAPs <- data_aug %>% 
  select(VAP, NP, BPP, BIP)

unknowns <- data_aug %>% 
  select(contains('Unknown'))

data_aug <- data_aug %>% 
  select(-all_of(colnames(SVMPs)), 
         -all_of(colnames(disintegrins)),
         -all_of(colnames(lectins)),
         -all_of(colnames(FTx3)),
         -all_of(colnames(PLA2s)),
         -all_of(colnames(VAPs)),
         -all_of(colnames(unknowns))
  ) %>% 
  mutate(
    SVMP = SVMPs %>% rowSums(),
    Disintegrin = disintegrins %>% rowSums(),
    Lectins = lectins %>% rowSums(),
    `3FTx` = FTx3 %>% rowSums(),
    PLA2 = PLA2s %>% rowSums(),
    VAP = VAPs %>% rowSums(),
    Unknown = unknowns %>% rowSums()
  )




# Remove toxins with few occurances ---------------------------------------
count_toxins <- data_aug %>% 
  select_if(is.numeric) %>%
  select(-Unknown) %>%
  summarise_all(is_not_zero) %>% 
  pivot_longer(cols = everything(), values_to = 'toxin_occurrence', names_to = 'toxin') %>%
  filter(toxin_occurrence > 5)

data_aug <- data_aug %>% 
  select(c("Snake", "Reference", "Country", count_toxins$toxin)) %>% 
  mutate(Unknown = 100 - Reduce(`+`, select_if(., is.numeric)))


# Separate snake names into genus and species ----------------------------------------------------
data_aug <- data_aug %>% 
  separate(col = Snake,
           into = c("Genus", "Species"),
           sep = " ",
           remove = FALSE,
           extra = "drop")


# Add snake families ------------------------------------------------------------
snake_families <- read_csv("https://docs.google.com/spreadsheets/d/e/2PACX-1vR1J2-JTgyqdK48fycrWrlC5bqWFHxVatiCLhvWuxnxTJYhuKoq-bMpEvxjL57LwePK819TJAHU-tkC/pub?gid=1798552264&single=true&output=csv",
                           col_types = "cc") %>% 
  rename(Genus = 'Snake genus') %>% 
  unique()

# Join families to data
data_aug <- data_aug %>% 
  left_join(snake_families, by = "Genus") %>% 
  select(Snake, Genus, Species, Family, Country, Reference, everything())

# Sanity check
data_aug %>% 
  count(Family)


# Write augmented data ----------------------------------------------------
data_aug %>% 
  write_csv('data/03_data_aug.csv')