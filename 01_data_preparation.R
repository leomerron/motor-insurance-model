# Motor Insurance Pricing Model
# 01 - Data Preparation


# 1. Load raw data

# French Motor Third Party Liability (MTPL) insurance dataset.
# The raw data is stored locally in MTPL_raw_data.RData.
# This file is excluded from GitHub via .gitignore because the
# raw dataset is not distributed with this repository.

load("MTPL_raw_data.RData")

freq_data <- freq_raw[, c(
  "IDpol",
  "ClaimNb",
  "Exposure",
  "VehPower",
  "VehAge",
  "DrivAge",
  "BonusMalus",
  "VehBrand",
  "VehGas",
  "Area",
  "Density",
  "Region"
)]




# 3. Create claim-level severity dataset


severity_data <- merge(
  sev_raw,
  freq_data[, c(
    "IDpol",
    "DrivAge",
    "VehAge",
    "VehPower",
    "BonusMalus",
    "VehBrand",
    "VehGas",
    "Area",
    "Density",
    "Region"
  )],
  by = "IDpol"
)

# 4. Basic data checks


# Dimensions
dim(freq_data)
dim(severity_data)

# Missing values
colSums(is.na(freq_data))
colSums(is.na(severity_data))

# Exposure must be positive
sum(freq_data$Exposure <= 0)

# Claim amounts must be positive
sum(severity_data$ClaimAmount <= 0)

# Claim frequency distribution
table(freq_data$ClaimNb)

# Severity distribution
summary(severity_data$ClaimAmount)

# Check variable types
str(freq_data)
str(severity_data)

# 5. Train/test split

set.seed(123)

policy_ids <- as.character(freq_data$IDpol)

train_ids <- sample(
  policy_ids,
  size = 0.8 * length(policy_ids)
)

freq_train <- freq_data[
  as.character(freq_data$IDpol) %in% train_ids,
]

freq_test <- freq_data[
  !as.character(freq_data$IDpol) %in% train_ids,
]

sev_train <- severity_data[
  as.character(severity_data$IDpol) %in% train_ids,
]

sev_test <- severity_data[
  !as.character(severity_data$IDpol) %in% train_ids,
]

# Check split sizes
dim(freq_train)
dim(freq_test)
dim(sev_train)
dim(sev_test)

# Check that no policy appears in both training and test sets
length(intersect(train_ids, 
                 as.character(freq_test$IDpol)))
