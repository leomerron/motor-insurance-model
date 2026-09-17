# Motor Insurance Pricing Model
# 02 - Exploratory Data Analysis
# Packages

library(ggplot2)
library(dplyr)

# The following objects are created in 01_data_preparation.R:
# freq_data
# severity_data
# freq_train
# freq_test
# sev_train
# sev_test


# 1. Overall portfolio characteristics

# Number of policies

n_policies <- nrow(freq_data)

# Total exposure

total_exposure <- sum(freq_data$Exposure)

# Total claims

total_claims <- sum(freq_data$ClaimNb)

# Overall claim frequency

overall_frequency <- total_claims / total_exposure

# Number of individual claims with recorded severity

n_severity_claims <- nrow(severity_data)

# Average claim severity

mean_severity <- mean(severity_data$ClaimAmount)

# Total observed claim cost

total_claim_cost <- sum(severity_data$ClaimAmount)

# Display portfolio summary

n_policies
total_exposure
total_claims
overall_frequency
n_severity_claims
mean_severity
total_claim_cost


# 2. Driver age and claim frequency

# Group drivers into age bands

freq_data$AgeBand <- cut(
  freq_data$DrivAge,
  breaks = c(17, 25, 35, 45, 55, 65, 75, 100),
  labels = c(
    "18-25",
    "26-35",
    "36-45",
    "46-55",
    "56-65",
    "66-75",
    "76-100"
  ),
  include.lowest = TRUE
)

age_frequency <- freq_data %>%
  group_by(AgeBand) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

age_frequency

ggplot(age_frequency, aes(x = AgeBand, y = Frequency)) +
  geom_col() +
  labs(
    title = "Claim Frequency by Driver Age",
    x = "Driver age",
    y = "Claim frequency"
  ) +
  theme_minimal()

# Compare the youngest two age groups

age_rr_18_25_vs_26_35 <- age_frequency$Frequency[
  age_frequency$AgeBand == "18-25"
] / age_frequency$Frequency[
  age_frequency$AgeBand == "26-35"
]

age_rr_18_25_vs_26_35

# Key finding:
# Claim frequency is substantially higher among drivers aged 18-25
# Frequency falls sharply after the youngest age band, remains
# relatively stable through ages 26-55, and declines further
# among older drivers before a small increase in the 76-100 group.
# The 18-25 group has approximately 1.99 times the claim frequency
# of the 26-35 group.


# 3. Vehicle age and claim frequency

# Group vehicles into age bands

freq_data$VehAgeBand <- cut(
  freq_data$VehAge,
  breaks = c(-1, 2, 5, 10, 15, 20, 100),
  labels = c(
    "0-2",
    "3-5",
    "6-10",
    "11-15",
    "16-20",
    "21+"
  ),
  include.lowest = TRUE
)

vehicle_age_frequency <- freq_data %>%
  group_by(VehAgeBand) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

vehicle_age_frequency

ggplot(
  vehicle_age_frequency,
  aes(x = VehAgeBand, y = Frequency)
) +
  geom_col() +
  labs(
    title = "Claim Frequency by Vehicle Age",
    x = "Vehicle age",
    y = "Claim frequency"
  ) +
  theme_minimal()

# Key finding:
# The 6-10 vehicle-age group has approximately 9.0% higher
# claim frequency than the 3-5 group.
# The 95% confidence interval for the rate ratio is
# approximately 1.05 to 1.13, indicating that the difference
# is statistically significant under a Poisson-rate approximation.
# This is an unadjusted association; the multivariable frequency
# model will determine whether vehicle age remains important
# after controlling for other rating factors.


# 4. Bonus-Malus and claim frequency

# Group Bonus-Malus scores into broader bands

freq_data$BMBand <- cut(
  freq_data$BonusMalus,
  breaks = c(49, 50, 60, 70, 80, 100, 150, 230),
  labels = c(
    "50",
    "51-60",
    "61-70",
    "71-80",
    "81-100",
    "101-150",
    "151-230"
  ),
  include.lowest = TRUE
)

bm_frequency <- freq_data %>%
  group_by(BMBand) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

bm_frequency

ggplot(bm_frequency, aes(x = BMBand, y = Frequency)) +
  geom_col() +
  labs(
    title = "Claim Frequency by Bonus-Malus Score",
    x = "Bonus-Malus score",
    y = "Claim frequency"
  ) +
  theme_minimal()

# Relative risk compared with the BM 50 baseline

bm_frequency$RelativeRisk <- bm_frequency$Frequency /
  bm_frequency$Frequency[bm_frequency$BMBand == "50"]

bm_frequency

# Key finding:
# Bonus-Malus shows a strong positive association with claim frequency.
# Frequency increases substantially as the Bonus-Malus score rises,
# particularly for scores above 100.
# The 151-230 group has very high observed frequency, but contains
# relatively little exposure, so estimates for this extreme group
# should be interpreted with caution.
# Relative to the BM 50 baseline, the 51-60, 61-70, 71-80,
# 81-100, 101-150 and 151-230 bands have approximately
# 1.45x, 2.28x, 2.05x, 2.79x, 6.72x and 11.0x the claim frequency.
# The 95% confidence interval for the 151-230 rate ratio is
# approximately 8.44 to 14.41.


# 5. Bonus-Malus at individual score level


# Calculate observed claim frequency at each individual
# Bonus-Malus score

bm_frequency_exact <- freq_data %>%
  group_by(BonusMalus) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

bm_frequency_exact

# Plot observed frequencies together with a smoothed trend

ggplot(
  bm_frequency_exact,
  aes(x = BonusMalus, y = Frequency)
) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "loess", se = TRUE) +
  labs(
    title = "Claim Frequency by Bonus-Malus Score",
    x = "Bonus-Malus score",
    y = "Claim frequency"
  ) +
  theme_minimal()

# Key finding:
# The relationship between Bonus-Malus score and claim frequency
# is clearly nonlinear.
# Frequency increases gradually across lower Bonus-Malus scores,
# becomes relatively flat around scores of 100-150, and rises
# sharply at higher scores.
# Individual Bonus-Malus levels can be noisy where exposure is low,
# so the smoothed trend is more informative than interpreting each
# observed rate independently.
# The nonlinear observed relationship provides motivation for
# considering a nonlinear Bonus-Malus effect in the frequency model.


# 6. Vehicle characteristics and claim frequency

vehicle_power_frequency <- freq_data %>%
  group_by(VehPower) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

vehicle_power_frequency

ggplot(
  vehicle_power_frequency,
  aes(x = VehPower, y = Frequency)
) +
  geom_point() +
  geom_line() +
  labs(
    title = "Claim Frequency by Vehicle Power",
    x = "Vehicle power",
    y = "Claim frequency"
  ) +
  theme_minimal()

# Compare claim frequency between the lowest and highest
# vehicle power categories

vehicle_power_frequency_ratio <- vehicle_power_frequency$Frequency[
  vehicle_power_frequency$VehPower == 15
] /
  vehicle_power_frequency$Frequency[
    vehicle_power_frequency$VehPower == 4
  ]

vehicle_power_frequency_ratio

# Key finding:
# Vehicle power 15 has approximately 14.3% higher observed
# claim frequency than vehicle power 4.

vehicle_gas_frequency <- freq_data %>%
  group_by(VehGas) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

vehicle_gas_frequency

# Compare claim frequency between fuel types

vehicle_gas_frequency_ratio <- vehicle_gas_frequency$Frequency[
  vehicle_gas_frequency$VehGas == "Diesel"
] /
  vehicle_gas_frequency$Frequency[
    vehicle_gas_frequency$VehGas == "Regular"
  ]

vehicle_gas_frequency_ratio

# Key finding:
# Diesel vehicles have approximately 13.9% higher observed
# claim frequency than Regular vehicles.

ggplot(vehicle_gas_frequency, aes(x = VehGas, y = Frequency)) +
  geom_col() +
  labs(
    title = "Claim Frequency by Vehicle Fuel Type",
    x = "Fuel type",
    y = "Claim frequency"
  ) +
  theme_minimal()

area_frequency <- freq_data %>%
  group_by(Area) %>%
  summarise(
    Policies = n(),
    Exposure = sum(Exposure),
    Claims = sum(ClaimNb),
    Frequency = Claims / Exposure
  )

area_frequency

# Compare claim frequency between the lowest and highest
# frequency areas

area_frequency_ratio <- area_frequency$Frequency[
  area_frequency$Area == "E"
] /
  area_frequency$Frequency[
    area_frequency$Area == "A"
  ]

area_frequency_ratio

# Key finding:
# Area E has approximately 77% higher observed claim frequency
# than Area A.

ggplot(area_frequency, aes(x = Area, y = Frequency)) +
  geom_col() +
  labs(
    title = "Claim Frequency by Area",
    x = "Area",
    y = "Claim frequency"
  ) +
  theme_minimal()


# 7. Correlation between numeric rating factors

numeric_correlations <- cor(
  freq_data[, c(
    "DrivAge",
    "VehAge",
    "VehPower",
    "BonusMalus",
    "Density"
  )],
  method = "spearman"
)

round(numeric_correlations, 2)

# Spearman correlation is used because relationships between rating
# factors may be non-linear. It measures the strength and direction
# of monotonic relationships and is less sensitive to outliers than
# Pearson correlation.
# Driver age and Bonus-Malus show the strongest association
# (rho = -0.57). The remaining explanatory variables have relatively
# weak pairwise correlations, suggesting no obvious severe
# multicollinearity at this stage.


