# Motor Insurance Risk Model

## Project Overview
This project develops a statistical model for estimating motor insurance claim frequency, claim severity and expected annual claim costs using French motor third-party liability insurance data. I am investigating what policyholder and vehicle characteristics can be used to estimate annual claim costs and then build a risk-based motor insurance premium. I have used pricing techniques such as Generalised Linear Models (GLMs) to investigate how characteristics such as driver age, Bonus-Malus and vehicle age are correlated with insurance claims. I implemented this in R to  focus on statistical modelling and actuarial interpretation.

## Dataset

This project uses the French motor third-party liability (MTPL)
insurance dataset `freMTPL2`.

The dataset contains information on motor insurance policies,
including driver characteristics, vehicle characteristics,
geographical information, exposure and claims.

The data is divided into two datasets:

- `freMTPL2freq` — policy-level data used for modelling claim frequency.
- `freMTPL2sev` — claim-level data used for modelling claim severity.

The two datasets are linked using `IDpol`.

## Severity data

freMTPL2sev contains 26,444 individual claims and records:
Policy identifier (IDpol)
Claim amount
The two datasets can be linked using the policy identifier IDpol.

## Data Quality and Initial Exploration 
The datasets contained no missing values in the variables used for the analysis. Policy exposure varies substantially, ranging from approximately one day to just over two years. This is important when analysing claim frequency because policies with greater exposure have more opportunity to generate claims. The claim count distribution is highly concentrated at zero, with approximately 96% of policies having no claims. Multiple claims are relatively uncommon. Claim severity is strongly right-skewed. The median claim amount is approximately €1,172, compared with a mean of approximately €2,266. While 99% of claims are below approximately €16,451, the 99.9th percentile is approximately €152,223 and the largest claim exceeds €4 million.This heavy-tailed severity distribution means that relatively rare large claims can have a substantial effect on aggregate claims costs.

### Frequency Dataset

`freMTPL2freq` contains 677,991 insurance policy observations.

Each row represents an insurance policy and contains information
about the policyholder, vehicle, exposure period and number of claims.

### Severity Dataset

`freMTPL2sev` contains 26,444 individual claim observations.

Each row represents an individual claim and contains the policy ID
and the amount of the claim.

## Exploratory Data Analysis
Claim frequencies were calculated using total claims/ total exposure to account for differences in the amount of time each policy was observed, and also using a 95% confidence interval. 

## Driver Age
Driver Age showed a strong nonlinear relationship with the observed claim frequency. Drivers aged 18–25 have an observed frequency of approximately 0.148 claims per exposure-year, compared with approximately 0.072 for drivers aged 36–45. Claim frequency then generally decreases through older age groups, although the oldest group shows a small increase. This suggests that driver age should not necessarily be represented by a simple linear effect in a frequency model.

## Vehicle Age
Vehicle age displays a non-monotonic relationship with claim frequency. Frequency is approximately 0.073–0.074 for vehicles aged 0–5 years, rises to approximately 0.081 for vehicles aged 6–10, and then falls to approximately 0.040 for vehicles aged 21 or more. This indicates that a simple assumption of a linear relationship between vehicle age and claim frequency may be inappropriate.

## Bonus-Malus
Bonus-Malus shows one of the strongest relationships with observed claim frequency. Frequency increases substantially as the Bonus-Malus coefficient increases:

Bonus-Malus 50: 0.0515
51–60: 0.0745
61–70: 0.1176
71–80: 0.1053
81–100: 0.1434
101–150: 0.3458
151–230: 0.5677

The relationship is broadly increasing and becomes particularly pronounced at higher Bonus-Malus values. However, Bonus-Malus reflects previous claims history and therefore should not be interpreted as a purely independent demographic risk factor.

## Vehicle Power
Vehicle power shows relatively modest differences in observed claim frequency. Frequency ranges from 0.067 for vehicles with power category 4 to around 0.085 for some of the highest power categories. Compared with factors such as Bonus-Malus, driver age and geographical characteristics, vehicle power appears to be a relatively weak univariate predictor.

## Fuel Type
Diesel vehicles have an observed claim frequency of approximately 0.079, compared with 0.069 for regular-fuel vehicles. This represents a moderate difference in observed frequency, although the relationship may partly reflect differences in other characteristics associated with vehicle type and policyholder characteristics.

## Geographical Area
The geographical Area variable shows a strong gradient in observed claim frequency:
Area A: 0.0543
Area B: 0.0612
Area C: 0.0679
Area D: 0.0837
Area E: 0.0959
Area F: 0.0952
The highest-frequency areas have substantially greater observed claim frequency than the lowest-frequency areas. This suggests that geographical characteristics provide useful information for insurance risk classification.

## Region
Claim frequency also varies substantially between French regions.Observed frequencies range from approximately 0.0526 in Midi-Pyrénées to 0.0934 in Rhône-Alpes.
Unlike Area, the regional relationship is not monotonic, with some regions having considerably higher or lower frequencies than others. Because Area, Region and Population Density all contain geographical information, their independent contribution will need to be assessed in the multivariable model.

## Population Density
Population density displays a strong approximately increasing relationship with claim frequency.Observed frequency increases from approximately 0.0543 for areas with population density below 50 to approximately 0.099 for densities between 5,001 and 10,000.The highest-density category has a slightly lower estimate of approximately 0.095, although its confidence interval overlaps substantially with the 5,001–10,000 category. Overall, the data suggests that higher population density is associated with greater claim frequency, although this should not be interpreted as a causal relationship.

## Vehicle Brand
Vehicle brand shows some variation in observed claim frequency, ranging from approximately 0.058 to 0.096 claims per exposure-year.The differences are considerably smaller than those observed for factors such as Bonus-Malus and driver age. Vehicle brand may nevertheless contain additional predictive information, which will be assessed in the multivariable model.

## Frequency Modelling
The first modelling stage estimates the expected number of claims for each policy. A Poisson Generalised Linear Model (GLM) was initially fitted, using the number of claims as the response variable and policy exposure as an offset.
The model takes the form:
$$
N_i \sim \text{Poisson}(\lambda_i)
$$

$$
\log(\lambda_i) =
\log(\text{Exposure}_i)
+ \beta_0
+ \beta_1x_{i1}
+\cdots+
\beta_px_{ip}
$$
where \(N_i\) represents the number of claims for policy \(i\), and the exposure offset accounts for differences in the amount of time each policy was insured.

The initial Poisson model showed evidence of overdispersion. The Pearson dispersion statistic was approximately **1.82**, indicating that the observed variability in claim counts was substantially greater than assumed by the Poisson model.A Negative Binomial GLM was therefore fitted to allow for additional variation in claim frequency. The Negative Binomial model produced a substantially lower AIC than the Poisson model:

| Model             |           AIC |
| ----------------- | ------------: |
| Poisson           |     215,557.6 |
| Negative Binomial | **214,906.9** |

The Negative Binomial model was therefore selected as the primary frequency model. However, its Pearson dispersion statistic remained approximately **1.78**, indicating that some unexplained heterogeneity remains in the data. Several variables showed strong associations with claim frequency after controlling for the other characteristics in the model. Driver age, vehicle age, vehicle power and Bonus-Malus were statistically significant, while claim frequency also varied across vehicle types and geographical areas. The positive coefficient for Bonus-Malus indicates that higher Bonus-Malus values are associated with higher predicted claim frequency, holding the other model variables constant. These relationships should be interpreted as associations rather than causal effects.

### Frequency Model Validation

Predicted claim counts were obtained from the Negative Binomial model. Because the model includes exposure as an offset, these predictions represent expected claim counts over each policy's observed exposure period. To compare policies according to their underlying annual risk, predicted claim counts were divided by exposure to obtain predicted annual claim frequencies. Policies were then ranked into ten risk deciles according to predicted annual claim frequency. Observed and predicted frequencies were compared within each decile.

| Risk decile | Observed frequency | Predicted frequency |
| ----------: | -----------------: | ------------------: |
|           1 |              0.036 |               0.038 |
|           2 |              0.042 |               0.046 |
|           3 |              0.050 |               0.051 |
|           4 |              0.054 |               0.056 |
|           5 |              0.056 |               0.061 |
|           6 |              0.070 |               0.067 |
|           7 |              0.080 |               0.075 |
|           8 |              0.093 |               0.088 |
|           9 |              0.118 |               0.113 |
|          10 |              0.190 |               0.199 |

The model demonstrates good discriminatory ability across the risk deciles, with observed claim frequency increasing substantially from approximately **0.036** claims per policy-year in the lowest-risk decile to **0.190** in the highest-risk decile. Predicted and observed frequencies are also relatively close across the risk groups, indicating reasonable calibration. At the portfolio level, the observed claim frequency was approximately **0.0738**, compared with a modelled frequency of approximately **0.0742**. Further validation will include residual diagnostics and Gini/Lorenz analysis to assess the model's discriminatory power.

## Severity Modelling
The second stage will model the size of individual claims using freMTPL2sev.
The highly right-skewed claim distribution will be investigated using appropriate severity distributions and transformations.
The objective is to estimate:
[
E[\text{Claim Amount} \mid \text{claim occurs}]
]
for different risk profiles.

## Expected Claim Costs
Frequency and severity estimates will then be combined to estimate the expected annual claims cost:
E[\text{Claim Frequency}]
\times
E[\text{Claim Severity}]
]
This represents the expected annual claims cost before incorporating expenses, risk margins, profit margins or other components of an insurance premium. The project will subsequently investigate how these expected costs vary between different policyholder risk profiles.

## Model Validation
Model performance is being assessed using both statistical and actuarial measures.For the frequency model, predicted and observed claim frequencies were compared across ten predicted-risk deciles. The model showed good separation between low- and high-risk policies while maintaining reasonably close predicted and observed frequencies across the deciles. Further validation will include residual diagnostics, Gini/Lorenz analysis and analysis of predicted versus observed aggregate claims costs. The severity model will also be assessed separately before frequency and severity predictions are combined.

## Actuarial Interpretation
A key objective of the project is to translate statistical results into actuarial conclusions.
The analysis will consider:
Which characteristics provide the greatest predictive information?
Whether relationships are linear or nonlinear
Whether different geographical variables provide overlapping information
Whether the model adequately captures high-risk policyholders
Whether predicted premiums are appropriately calibrated
How uncertainty and extreme claims affect expected costs
Observed relationships will not automatically be interpreted as causal effects, since policyholder and vehicle characteristics may be correlated.

## Limitations
Several limitations should be considered. The dataset represents a particular French motor insurance portfolio and may not be representative of the UK motor insurance market. Some variables may contain information that overlaps with other rating factors. In particular, geographical variables such as Area, Region and Population Density may be correlated. Bonus-Malus also reflects previous claims experience, meaning that its strong predictive relationship with claim frequency should be interpreted in the context of its role as a claims-history variable. Finally, the claim severity distribution contains a small number of extremely large claims. These observations can have a disproportionate effect on aggregate claims costs and therefore require careful treatment rather than simply being removed as outliers.

## Conclusion
The exploratory analysis indicates substantial heterogeneity in motor insurance claim frequency across policyholder, vehicle and geographical characteristics. The strongest observed relationships are associated with Bonus-Malus, driver age, geographical Area and population density, while vehicle power and vehicle brand show comparatively weaker univariate relationships. The next stage of the project will determine whether these relationships remain important after controlling for other characteristics using multivariable statistical models. The final objective is to combine frequency and severity predictions to estimate expected annual claims costs and investigate how these estimates could be translated into a risk-based motor insurance premium.



## Variables

| Variable | Description |
|---|---|
| `IDpol` | Unique policy identifier |
| `ClaimNb` | Number of claims during the exposure period |
| `Exposure` | Duration for which the policy was observed, measured in years |
| `VehPower` | Vehicle power |
| `VehAge` | Age of the vehicle |
| `DrivAge` | Age of the driver |
| `BonusMalus` | French bonus-malus insurance rating |
| `VehBrand` | Vehicle brand |
| `VehGas` | Fuel type |
| `Area` | Geographical area |
| `Density` | Population density |
| `Region` | French region |
| `ClaimAmount` | Amount of an individual claim |

## Data Quality

No missing values were identified in either dataset.

## Modelling

*To be completed.*

## Results

*To be completed.*
- 
- 
- 
