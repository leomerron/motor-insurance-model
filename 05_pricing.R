
# Motor Insurance Pricing Model
# 05 - Pure Premium and Commercial Pricing

library(dplyr)

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

# 1. Predict claim frequency

freq_test$PredictedFrequency <- predict(
  frequency_model_nb_age_bm_interaction,
  newdata = freq_test,
  type = "response"
)

summary(freq_test$PredictedFrequency)


# 2. Predict severity for all test policies

freq_test$PredictedSeverity <- predict(
  severity_model_final,
  newdata = freq_test,
  type = "response"
)

summary(freq_test$PredictedSeverity)

# 3. Calculate annualised pure premium

# Convert the exposure-adjusted frequency prediction into an
# annual claim frequency.
freq_test$PredictedAnnualFrequency <-
  freq_test$PredictedFrequency / freq_test$Exposure

# Pure premium represents expected annual claim cost:
# expected annual frequency × expected claim severity.
freq_test$PurePremium <-
  freq_test$PredictedAnnualFrequency *
  freq_test$PredictedSeverity

summary(freq_test$PredictedAnnualFrequency)
summary(freq_test$PurePremium)

# 4. Pure premium distribution

ggplot(freq_test, aes(x = PurePremium)) +
  geom_histogram(bins = 100) +
  scale_x_log10() +
  labs(
    title = "Distribution of Predicted Annual Pure Premium",
    x = "Predicted pure premium (£, log scale)",
    y = "Number of policies"
  ) +
  theme_minimal()

pure_premium_quantiles <- quantile(
  freq_test$PurePremium,
  probs = c(0.5, 0.75, 0.9, 0.95, 0.99)
)
pure_premium_quantiles

# 5. Commercial premium

# Illustrative commercial loadings:
#   20% expenses
#    5% risk margin
#   10% profit margin
#
# These are illustrative assumptions rather than estimates
# from the dataset.

expense_loading <- 0.20
risk_loading <- 0.05
profit_loading <- 0.10

commercial_loading <- 
  (1 + expense_loading) *
  (1 + risk_loading) *
  (1 + profit_loading)

freq_test$CommercialPremium <-
  freq_test$PurePremium * commercial_loading

summary(freq_test$CommercialPremium)

quantile(
  freq_test$CommercialPremium,
  probs = c(0.5, 0.75, 0.9, 0.95, 0.99)
)

# 6. Premium by risk decile

freq_test$PricingDecile <- ntile(
  freq_test$PurePremium,
  10
)

pricing_deciles <- freq_test %>%
  group_by(PricingDecile) %>%
  summarise(
    Policies = n(),
    MeanPurePremium = mean(PurePremium),
    MeanCommercialPremium = mean(CommercialPremium)
  )

pricing_deciles


