
# Motor Insurance Pricing Model
# 04 - Claim Severity Modelling


library(ggplot2)
library(dplyr)
library(splines)

# The following objects are created in 01_data_preparation.R:
#   severity_data
#   sev_train
#   sev_test

# Claim severity is modelled conditional on a claim occurring.

# 1. Examine claim severity distribution


summary(sev_train$ClaimAmount)

severity_quantiles <- quantile(
  sev_train$ClaimAmount,
  probs = c(0.5, 0.75, 0.9, 0.95, 0.99, 0.999)
)

severity_quantiles

# Claim severity is strongly right-skewed, with most claims
# relatively small and a small number of very large claims.
# The positive, right-skewed nature of the response motivates
# the use of a Gamma GLM with a log link.

ggplot(sev_train, aes(x = ClaimAmount)) +
  geom_histogram(bins = 100) +
  scale_x_log10() +
  labs(
    title = "Claim Severity Distribution",
    x = "Claim amount (£, log scale)",
    y = "Number of claims"
  ) +
  theme_minimal()


# 2. Baseline Gamma severity model

severity_model_baseline <- glm(
  ClaimAmount ~
    DrivAge +
    VehAge +
    VehPower +
    BonusMalus +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region,
  family = Gamma(link = "log"),
  data = sev_train
)

summary(severity_model_baseline)

# Compare baseline model fit using AIC
AIC(severity_model_baseline)

# 3. Nonlinear Driver Age effect

severity_model_age_spline <- glm(
  ClaimAmount ~
    ns(DrivAge, df = 4) +
    VehAge +
    VehPower +
    BonusMalus +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region,
  family = Gamma(link = "log"),
  data = sev_train
)

summary(severity_model_age_spline)

# Compare baseline and spline models
AIC(
  severity_model_baseline,
  severity_model_age_spline
)
# The nonlinear Driver Age spline substantially reduces AIC
# relative to the baseline model, indicating that claim severity
# varies nonlinearly with driver age. The spline is therefore
# retained in the final severity model.


# 4. Final Gamma severity model

severity_model_final <- glm(
  ClaimAmount ~
    ns(DrivAge, df = 4) +
    VehAge +
    VehPower +
    BonusMalus +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region,
  family = Gamma(link = "log"),
  data = sev_train
)

summary(severity_model_final)

# Final model AIC
AIC(severity_model_final)

# 5. Severity model dispersion

severity_dispersion <- sum(
  residuals(
    severity_model_final,
    type = "deviance"
  )^2
) / severity_model_final$df.residual

severity_dispersion
# A dispersion estimate of 1.56 is retained as a residual
# diagnostic. It does not indicate a severe lack of fit by itself,
# and the Gamma model explicitly allows variance to increase with
# the expected claim severity.


# 6. In sample severity prediction check

sev_train$PredictedSeverity <- predict(
severity_model_final,
newdata = sev_train,
type = "response"
)

mean_actual_severity <- mean(sev_train$ClaimAmount)
mean_predicted_severity <- mean(sev_train$PredictedSeverity)

mean_actual_severity
mean_predicted_severity

# Compare observed and predicted mean severity
severity_mean_difference <- mean_predicted_severity -
  mean_actual_severity

severity_mean_percentage_difference <-
  (mean_predicted_severity / mean_actual_severity - 1) * 100

severity_mean_difference
severity_mean_percentage_difference

# The model underpredicts the mean claim severity by approximately
# 2.9% in the training data. This represents reasonably close
# portfolio-level calibration, although further validation on the
# held-out severity data is required before assessing predictive
# performance.

# 7. Severity prediction by risk decile

sev_train$SeverityDecile <- ntile(
  sev_train$PredictedSeverity,
  10
)

severity_decile_validation <- sev_train %>%
  group_by(SeverityDecile) %>%
  summarise(
    Claims = n(),
    ActualSeverity = mean(ClaimAmount),
    PredictedSeverity = mean(PredictedSeverity)
  )

severity_decile_validation

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
    title = "Actual vs Predicted Claim Severity by Decile",
    x = "Predicted severity decile",
    y = "Average claim severity (£)",
    linetype = NULL
  ) +
  theme_minimal()

# The model broadly captures the increasing severity pattern
# across predicted-risk deciles. Agreement between observed and
# predicted severity is strongest through approximately the first
# seven deciles, while greater divergence occurs in the upper
# deciles. This reflects the substantial variability in large

