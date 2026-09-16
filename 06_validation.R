
# Motor Insurance Pricing Model
# 06 - Model Validation


library(dplyr)
library(ggplot2)

# The following objects are created in previous scripts:
#
# From 01_data_preparation.R:
#   freq_test
#   sev_test
#
# From 03_frequency_model.R:
#   frequency_model_nb_age_bm_interaction
#
# From 04_severity_model.R:
#   severity_model_final
#
# Validation is performed on the held-out test data to assess
# out-of-sample predictive performance.

# 1. Frequency validation

freq_test$PredictedFrequency <- predict(
  frequency_model_nb_age_bm_interaction,
  newdata = freq_test,
  type = "response"
)

actual_frequency <- sum(freq_test$ClaimNb) /
  sum(freq_test$Exposure)

predicted_frequency <- sum(freq_test$PredictedFrequency) /
  sum(freq_test$Exposure)

actual_frequency
predicted_frequency

frequency_percentage_difference <-
  (predicted_frequency / actual_frequency - 1) * 100

frequency_percentage_difference

# 2. Frequency calibration by risk decile

# Convert predicted claim counts into annualised predicted
# claim frequencies by removing the exposure component.

freq_test$PredictedAnnualFrequency <-
  freq_test$PredictedFrequency / freq_test$Exposure

freq_test$FrequencyDecile <- ntile(
  freq_test$PredictedAnnualFrequency,
  10
)

frequency_decile_validation <- freq_test %>%
  group_by(FrequencyDecile) %>%
  summarise(
    Exposure = sum(Exposure),
    ActualClaims = sum(ClaimNb),
    PredictedClaims = sum(PredictedFrequency),
    ActualFrequency = ActualClaims / Exposure,
    PredictedFrequency = PredictedClaims / Exposure
  )

frequency_decile_validation <- frequency_decile_validation %>%
  mutate(
    CalibrationRatio =
      ActualFrequency / PredictedFrequency
  )

frequency_decile_validation

# 3. Frequency calibration plot

ggplot(
  frequency_decile_validation,
  aes(x = FrequencyDecile)
) +
  geom_line(
    aes(y = ActualFrequency, linetype = "Actual")
  ) +
  geom_point(
    aes(y = ActualFrequency)
  ) +
  geom_line(
    aes(y = PredictedFrequency, linetype = "Predicted")
  ) +
  geom_point(
    aes(y = PredictedFrequency)
  ) +
  labs(
    title = "Actual vs Predicted Claim Frequency by Risk Decile",
    x = "Predicted annual frequency decile",
    y = "Claim frequency",
    linetype = NULL
  ) +
  theme_minimal()


# 4. Severity validation

sev_test$PredictedSeverity <- predict(
  severity_model_final,
  newdata = sev_test,
  type = "response"
)

actual_severity <- mean(sev_test$ClaimAmount)

predicted_severity <- mean(sev_test$PredictedSeverity)

actual_severity
predicted_severity

severity_percentage_difference <-
  (predicted_severity / actual_severity - 1) * 100

severity_percentage_difference

# ------------------------------------------------------------
# 5. Severity calibration by predicted-risk decile
# ------------------------------------------------------------

sev_test$SeverityDecile <- ntile(
  sev_test$PredictedSeverity,
  10
)

severity_decile_validation <- sev_test %>%
  group_by(SeverityDecile) %>%
  summarise(
    Claims = n(),
    ActualSeverity = mean(ClaimAmount),
    PredictedSeverity = mean(PredictedSeverity)
  )

severity_decile_validation


# 6. Severity calibration plot

ggplot(
  severity_decile_validation,
  aes(x = SeverityDecile)
) +
  geom_line(
    aes(y = ActualSeverity, linetype = "Actual")
  ) +
  geom_point(
    aes(y = ActualSeverity)
  ) +
  geom_line(
    aes(y = PredictedSeverity, linetype = "Predicted")
  ) +
  geom_point(
    aes(y = PredictedSeverity)
  ) +
  labs(
    title = "Actual vs Predicted Claim Severity by Risk Decile",
    x = "Predicted severity decile",
    y = "Average claim severity (£)",
    linetype = NULL
  ) +
  theme_minimal()


# 7. Aggregate claims-cost validation


# Predicted claims cost over the actual exposure period
predicted_total_claim_cost <- sum(
  freq_test$PurePremium * freq_test$Exposure
)

# Observed claims cost
actual_total_claim_cost <- sum(
  sev_test$ClaimAmount
)

predicted_total_claim_cost
actual_total_claim_cost

# Absolute difference
claims_cost_difference <-
  predicted_total_claim_cost -
  actual_total_claim_cost

claims_cost_difference

# Percentage difference
claims_cost_percentage_difference <-
  (predicted_total_claim_cost /
     actual_total_claim_cost - 1) * 100

claims_cost_percentage_difference

# 8. Pricing discrimination - Gini coefficient

# Start with the original held-out policy data
gini_test <- freq_data[
  as.character(freq_data$IDpol) %in%
    as.character(freq_test$IDpol),
  c("IDpol", "Exposure")
]

# Calculate observed claim cost for each policy
claim_cost_by_policy <- sev_test %>%
  group_by(IDpol) %>%
  summarise(
    ActualClaimCost = sum(ClaimAmount),
    .groups = "drop"
  )

# Attach observed claim cost to every test policy
gini_test <- gini_test %>%
  left_join(
    claim_cost_by_policy,
    by = "IDpol"
  )

# Policies with no claims have zero observed claim cost
gini_test$ActualClaimCost[
  is.na(gini_test$ActualClaimCost)
] <- 0

# Get model predictions from the existing test predictions
prediction_data <- freq_test %>%
  select(IDpol, PurePremium)

# Attach predicted pure premium
gini_test <- gini_test %>%
  left_join(
    prediction_data,
    by = "IDpol"
  )

# Rank policies from lowest to highest predicted risk
gini_test <- gini_test %>%
  arrange(PurePremium)

# Cumulative exposure and observed claims cost
gini_test <- gini_test %>%
  mutate(
    CumulativeExposure =
      cumsum(Exposure) / sum(Exposure),
    
    CumulativeClaimsCost =
      cumsum(ActualClaimCost) /
      sum(ActualClaimCost)
  )

# Add origin to Lorenz curve
lorenz_x <- c(0, gini_test$CumulativeExposure)
lorenz_y <- c(0, gini_test$CumulativeClaimsCost)

# Area under Lorenz curve
lorenz_area <- sum(
  diff(lorenz_x) *
    (head(lorenz_y, -1) +
       tail(lorenz_y, -1)) / 2
)

# Gini coefficient
gini_model <- 1 - 2 * lorenz_area

gini_model

# 9. Individual policy-level prediction error


# Start with all test policies
mae_test <- freq_data[
  as.character(freq_data$IDpol) %in%
    as.character(freq_test$IDpol),
  c("IDpol", "Exposure")
]

# Calculate total observed claim cost for each policy
actual_cost_by_policy <- sev_test %>%
  group_by(IDpol) %>%
  summarise(
    ActualClaimCost = sum(ClaimAmount),
    .groups = "drop"
  )

# Attach observed claim cost to every test policy
mae_test <- mae_test %>%
  left_join(
    actual_cost_by_policy,
    by = "IDpol"
  )

# Policies with no claims have zero observed cost
mae_test$ActualClaimCost[
  is.na(mae_test$ActualClaimCost)
] <- 0

# Attach predicted pure premium
mae_test <- mae_test %>%
  left_join(
    freq_test %>%
      select(IDpol, PurePremium),
    by = "IDpol"
  )


# Model predicted claims cost over actual exposure
mae_test <- mae_test %>%
  mutate(
    PredictedClaimCost =
      PurePremium * Exposure
  )

# Absolute prediction error
mae_test <- mae_test %>%
  mutate(
    AbsoluteError =
      abs(PredictedClaimCost - ActualClaimCost)
  )

# Mean Absolute Error
model_mae <- mean(
  mae_test$AbsoluteError
)

model_mae


# 10. Naive baseline MAE

# Calculate the training-set portfolio average annual
# claims frequency and mean claim severity.
training_frequency <- sum(freq_train$ClaimNb) /
  sum(freq_train$Exposure)

training_severity <- mean(
  sev_train$ClaimAmount
)

# Use the training portfolio averages to construct a simple
# baseline annual pure premium.
baseline_annual_pure_premium <-
  training_frequency * training_severity

baseline_annual_pure_premium

# Apply the baseline to each test policy using its actual
# exposure period.
mae_test <- mae_test %>%
  mutate(
    BaselineClaimCost =
      baseline_annual_pure_premium * Exposure
  )

# Calculate the baseline Mean Absolute Error.
baseline_mae <- mean(
  abs(
    mae_test$BaselineClaimCost -
      mae_test$ActualClaimCost
  )
)

baseline_mae

# Compare the model MAE with the naive baseline.
mae_reduction_percent <-
  (baseline_mae - model_mae) /
  baseline_mae * 100

mae_reduction_percent


# 11. Frequency model residual diagnostics

# Calculate predicted claim counts for the held-out test data.
freq_test$FittedFrequency <- predict(
  frequency_model_nb_age_bm_interaction,
  newdata = freq_test,
  type = "response"
)

# Calculate Pearson residuals for the held-out test data.
#
# For a Negative Binomial model:
# Var(Y) = mu + mu^2 / theta
#
# where mu is the predicted claim count and theta is the
# estimated Negative Binomial dispersion parameter.

freq_test$FrequencyResidual <- (
  freq_test$ClaimNb -
    freq_test$FittedFrequency
) / sqrt(
  freq_test$FittedFrequency +
    freq_test$FittedFrequency^2 /
    frequency_model_nb_age_bm_interaction$theta
)

# Plot Pearson residuals against fitted claim counts.
ggplot(
  freq_test,
  aes(
    x = FittedFrequency,
    y = FrequencyResidual
  )
) +
  geom_point(alpha = 0.1) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Frequency Model Residuals vs Fitted Values",
    x = "Fitted claim count",
    y = "Pearson residual"
  ) +
  theme_minimal()

# Binned residual diagnostic

freq_test <- freq_test %>%
  mutate(
    FittedFrequencyBin = ntile(
      FittedFrequency,
      20
    )
  )

frequency_residual_bins <- freq_test %>%
  group_by(FittedFrequencyBin) %>%
  summarise(
    MeanFittedFrequency = mean(FittedFrequency),
    MeanResidual = mean(FrequencyResidual),
    .groups = "drop"
  )

frequency_residual_bins

ggplot(
  frequency_residual_bins,
  aes(
    x = MeanFittedFrequency,
    y = MeanResidual
  )
) +
  geom_point() +
  geom_line() +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Binned Frequency Model Residuals",
    x = "Mean fitted claim count",
    y = "Mean Pearson residual"
  ) +
  theme_minimal()


# 12. Severity model residual diagnostics


# Calculate predicted claim severity for the held-out test data.
sev_test$FittedSeverity <- predict(
  severity_model_final,
  newdata = sev_test,
  type = "response"
)

# Calculate Gamma deviance residuals for the held-out test data.
#
# For a Gamma GLM, the deviance contribution is:
#
# D_i = 2 * ((y_i - mu_i) / mu_i -
#            log(y_i / mu_i))
#
# where y_i is the observed severity and mu_i is
# the predicted severity.

severity_deviance <- 2 * (
  (sev_test$ClaimAmount - sev_test$FittedSeverity) /
    sev_test$FittedSeverity -
    log(
      sev_test$ClaimAmount /
        sev_test$FittedSeverity
    )
)

sev_test$SeverityResidual <- sign(
  sev_test$ClaimAmount -
    sev_test$FittedSeverity
) * sqrt(
  severity_deviance
)

# Plot deviance residuals against fitted severity.
ggplot(
  sev_test,
  aes(
    x = FittedSeverity,
    y = SeverityResidual
  )
) +
  geom_point(alpha = 0.1) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Severity Model Residuals vs Fitted Values",
    x = "Fitted claim severity (£)",
    y = "Deviance residual"
  ) +
  theme_minimal()

