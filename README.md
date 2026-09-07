# Motor Insurance Risk Model

## Project Objective

Can policyholder and vehicle characteristics be used to estimate
expected annual claim costs and construct a risk-based motor
insurance premium?

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

## Dataset Structure

### Frequency Dataset

`freMTPL2freq` contains 677,991 insurance policy observations.

Each row represents an insurance policy and contains information
about the policyholder, vehicle, exposure period and number of claims.

### Severity Dataset

`freMTPL2sev` contains 26,444 individual claim observations.

Each row represents an individual claim and contains the policy ID
and the amount of the claim.

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
