
# Motor Insurance Pricing Model
# 03 - Claim Frequency Modelling

library(MASS)
library(splines)
library(ggplot2)

# The following objects are created in 01_data_preparation.R:
#   freq_data
#   freq_train
#   freq_test
# Claim frequency is modelled using a count distribution with
# exposure included as an offset.


# 1. Baseline Poisson frequency model


poisson_model <- glm(
  ClaimNb ~
    VehPower +
    VehAge +
    DrivAge +
    BonusMalus +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region +
    offset(log(Exposure)),
  family = poisson(link = "log"),
  data = freq_train
)

summary(poisson_model)


# 2. Check for overdispersion

# The Poisson model assumes that the conditional variance of the
# claim count is equal to its conditional mean. We assess this
# assumption using the Pearson dispersion statistic.

poisson_pearson_dispersion <- sum(
  residuals(poisson_model, type = "pearson")^2
) / poisson_model$df.residual

poisson_pearson_dispersion
# A value substantially greater than 1 indicates overdispersion,
# suggesting that the Poisson distribution does not adequately
# capture the variability in claim counts.


# 3. Negative Binomial frequency model

# The Poisson model showed substantial overdispersion.
# A Negative Binomial model is therefore fitted to allow the
# variance of claim counts to exceed the mean.

frequency_model_nb <- glm.nb(
  ClaimNb ~
    VehPower +
    VehAge +
    DrivAge +
    BonusMalus +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region +
    offset(log(Exposure)),
  data = freq_train
)

summary(frequency_model_nb)

# Compare the Poisson and Negative Binomial models.
# Both models are fitted to the same training data.

AIC(poisson_model, frequency_model_nb)

# The Negative Binomial model has a lower AIC than the Poisson
# model, indicating improved fit despite the additional
# dispersion parameter.

# 4. Nonlinear effects: Driver Age and Bonus-Malus

# The EDA suggested that claim frequency does not change
# linearly with Driver Age or Bonus-Malus. Natural cubic
# splines are therefore used to allow flexible nonlinear
# relationships while avoiding an overly rigid functional form.

frequency_model_nb_spline <- glm.nb(
  ClaimNb ~
    ns(DrivAge, df = 4) +
    ns(BonusMalus, df = 4) +
    VehAge +
    VehPower +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region +
    offset(log(Exposure)),
  data = freq_train
)

summary(frequency_model_nb_spline)

AIC(frequency_model_nb, frequency_model_nb_spline)
# The spline model substantially reduces AIC relative to the
# linear Negative Binomial model, indicating that nonlinear
# relationships between Driver Age, Bonus-Malus and claim
# frequency provide a materially better fit.

# 5. Driver Age × Bonus-Malus interaction
# The interaction allows the effect of Bonus-Malus to vary
# across driver ages rather than assuming that the two effects
# operate independently.

frequency_model_nb_age_bm_interaction <- glm.nb(
  ClaimNb ~
    ns(DrivAge, df = 4) *
    ns(BonusMalus, df = 4) +
    VehAge +
    VehPower +
    VehBrand +
    VehGas +
    Area +
    log(Density) +
    Region +
    offset(log(Exposure)),
  data = freq_train
)

summary(frequency_model_nb_age_bm_interaction)

AIC(
  frequency_model_nb_spline,
  frequency_model_nb_age_bm_interaction
)
# The Driver Age × Bonus-Malus interaction further reduces AIC,
# indicating that the effect of Bonus-Malus on claim frequency
# varies across driver ages. The interaction is therefore retained
# in the final frequency model.
# Formal likelihood-ratio test of the Driver Age × Bonus-Malus interaction.
# The highly significant result indicates that the effect of Bonus-Malus
# on claim frequency varies across driver ages, supporting retention of
# the interaction in the final frequency model.
anova(
  frequency_model_nb_spline,
  frequency_model_nb_age_bm_interaction,
  test = "Chisq"
)

frequency_final_pearson_dispersion <- sum(
  residuals(
    frequency_model_nb_age_bm_interaction,
    type = "pearson"
  )^2
) / frequency_model_nb_age_bm_interaction$df.residual

frequency_final_pearson_dispersion

# Pearson dispersion is retained as a diagnostic measure.
# The Negative Binomial model explicitly accounts for
# overdispersion through its estimated dispersion parameter.

# 6. Driver Age × Bonus-Malus predicted frequency analysis

age_bands <- c(
  "18-25",
  "26-35",
  "36-45",
  "46-55",
  "56-65",
  "66-75",
  "76-100"
)

bm_bands <- c(
  "50",
  "51-60",
  "61-70",
  "71-80",
  "81-100",
  "101-150",
  "151-230"
)

age_bm_grid <- expand.grid(
  DrivAge = c(21.5, 30.5, 40.5, 50.5, 60.5, 70.5, 88),
  BonusMalus = c(50, 55, 65, 75, 90, 125, 190)
)

age_bm_grid$VehAge <- median(freq_train$VehAge)
age_bm_grid$VehPower <- median(freq_train$VehPower)
age_bm_grid$VehBrand <- levels(freq_train$VehBrand)[1]
age_bm_grid$VehGas <- levels(freq_train$VehGas)[1]
age_bm_grid$Area <- levels(freq_train$Area)[1]
age_bm_grid$Density <- median(freq_train$Density)
age_bm_grid$Region <- levels(freq_train$Region)[1]
age_bm_grid$Exposure <- 1


age_bm_grid$PredictedFrequency <- predict(
  frequency_model_nb_age_bm_interaction,
  newdata = age_bm_grid,
  type = "response"
)

age_bm_grid$AgeBand <- factor(
  rep(age_bands, times = length(bm_bands)),
  levels = age_bands
)

age_bm_grid$BMBand <- factor(
  rep(bm_bands, each = length(age_bands)),
  levels = bm_bands
)

age_bm_matrix <- xtabs(
  PredictedFrequency ~ AgeBand + BMBand,
  data = age_bm_grid
)

age_bm_matrix

age_bm_plot_data <- as.data.frame(age_bm_matrix)

ggplot(
  age_bm_plot_data,
  aes(x = BMBand, y = AgeBand, fill = Freq)
) +
  geom_tile() +
  geom_text(aes(label = round(Freq, 3)), colour = "white") +
  scale_fill_viridis_c(
    option = "C",
    trans = "sqrt"
  ) +
  labs(
    title = "Predicted Claim Frequency by Driver Age and Bonus-Malus",
    x = "Bonus-Malus band",
    y = "Driver age band",
    fill = "Predicted frequency"
  ) +
  theme_minimal()
