# 💡 Project Overview: Supervised & Unsupervised Statistical Learning: kNN vs. Lasso Logistic Regression & Discovering the Big Five

This repository contains my first individual assignment for the **Statistical Learning** course of the Master's programme in Statistics & Data Science (Leiden University). The assignment consists of two parts. **Part A (supervised learning)** compares **k-Nearest Neighbours (kNN)** against **Lasso Logistic Regression (LLR)** on a simulated binary classification problem, first in a low-dimensional setting (3 relevant predictors + 3 noise variables) and then in a high-dimensional setting (3 relevant predictors + 200 noise variables), to study the **bias-variance trade-off** and the value of regularization under increasing noise. **Part B (unsupervised learning)** applies **Principal Component Analysis (PCA)** and clustering (**k-means**, **hierarchical**) to a personality questionnaire of 1,000 students, and recovers the well-known **Big Five (OCEAN)** personality structure.

> **Assignment:** *Statistical Learning, Individual Assignment 1*,
> submitted April 2024. Full write-up in
> [ind_assignment01_JD.pdf](ind_assignment01_JD.pdf).

<br>

# 🔢 Data

| Dataset | Description | Source |
|---|---|---|
| `Data4036018.csv` | 10,000 simulated cases: binary response $Y$, relevant predictors $X_1$–$X_3$, and 200 uniform noise variables $X_4$–$X_{203}$. Generated with a personal seed via [GenerateDataSDS.R](GenerateDataSDS.R) | simulated |
| `data.US.csv` / `data.US.txt` | 1,000 students × 30 standardized personality items (`V2`–`V31`), ~1 item per personality facet | course-provided |

**Simulation design (Part A).** The predictors are drawn as $X_1 \sim \mathcal{U}(-2, 2)$, $X_2 \sim \mathcal{N}(4, 2)$, $X_3 \sim \mathcal{N}(0, 1)$; all noise variables are $\mathcal{U}(-2, 2)$. The response is generated from a deliberately **non-linear** logit:

$$
\eta = -1.5 + 1.5 X_1 + 0.85 X_1^2 - 0.20 X_1^3 + 2.5 \cdot \mathbb{I}(X_2 < 0) + \mathbb{I}(X_2 > 3) + 0.3 X_3
$$

$$
Y \sim \mathrm{Bernoulli}\left(\frac{e^{\eta}}{1 + e^{\eta}}\right)
$$

Polynomials and indicator jumps make the true decision boundary non-linear. This is exactly the regime where a flexible non-parametric method and a regularized linear method should behave very differently.

<br>

# 🛠️ Methods

## k-Nearest Neighbours (kNN)

- Non-parametric, **low bias / high variance**: flexible enough to capture non-linear decision boundaries
- $k$ tuned over 1–200 via **10-fold cross-validation** (`caret`), with centering and scaling
- Sensitive to irrelevant predictors, since distances degrade as noise dimensions accumulate (curse of dimensionality)

## Lasso Logistic Regression (LLR)

- Parametric, **higher bias / low variance**: the L1 penalty shrinks irrelevant coefficients to (near) zero
- Shrinkage parameter $\lambda$ tuned via **10-fold cross-validation** (`cv.glmnet`, misclassification loss)
- Built-in variable selection, but restricted to **linear** decision boundaries

## PCA + Clustering (Part B)

- Component retention decided by **PVE / cumulative PVE**, **scree (elbow) plot**, **Kaiser's rule**, and **Horn's parallel analysis** (`nFactors`)
- **Varimax rotation** of loadings for interpretability
- **k-means** ($k$ chosen via elbow method on within-cluster SS) and **hierarchical clustering** (complete, average, and single linkage) on the retained PC scores

<br>

# 📊 Key findings (TLDR)

**Part A: flexibility wins in low dimensions, regularization wins in high dimensions.**

| Setting | kNN test accuracy | LLR test accuracy |
|---|---|---|
| Low-dimensional ($X_1$–$X_6$, $k = 79$) | **71.74%** | 67.28% |
| High-dimensional ($X_1$–$X_{203}$, $k = 41$) | 57.14% | **67.02%** |

1. With only 3 noise variables, kNN's flexibility captured the non-linear boundary and beat LLR, whose linear form couldn't represent the polynomial/indicator structure
2. With 200 noise variables, kNN collapsed (high variance *and* high bias), while the lasso shrank virtually all noise coefficients to zero and held its accuracy almost unchanged: a textbook demonstration of the bias-variance trade-off
3. In the low-dimensional fit, LLR zeroed out $X_5$ and $X_6$ and shrank $X_4$ to $\approx 0.008$, confirming its variable-selection behaviour even when it loses on accuracy

**Part B: the Big Five emerge from the data.**

1. Five principal components retained (56.89% of variance), consistently supported by the elbow plot, Kaiser's rule, and parallel analysis
2. After varimax rotation, the loading clusters map cleanly onto **neuroticism, extraversion, agreeableness, conscientiousness, and openness**, replicating the OCEAN model
3. k-means suggested **3 personality profiles** (sizes 284 / 390 / 326), differing mainly in **neuroticism** and **extraversion**; hierarchical clustering (complete linkage) produced a comparable 3-cluster solution (198 / 487 / 315)

<br>
<br>

# 📈 Results in detail

## Part A: kNN vs. Lasso under increasing noise

Both classifiers were tuned with **10-fold cross-validation** on the 5,000 training observations and evaluated once on the 5,000 held-out test observations, first with 3 noise variables, then with 200.

| Setting | Model | Tuned parameter | Test accuracy |
|---|---|---|---|
| Low-dim ($X_1$–$X_6$) | kNN | $k = 79$ | **71.74%** |
| Low-dim ($X_1$–$X_6$) | LLR | $\lambda = 0.0103$ | 67.28% |
| High-dim ($X_1$–$X_{203}$) | kNN | $k = 41$ | 57.14% |
| High-dim ($X_1$–$X_{203}$) | LLR | $\lambda = 0.0059$ | **67.02%** |

**Results:**
- In the low-dimensional setting, kNN's flexible decision boundary captured the polynomial/indicator structure of the true logit and beat the lasso by ~4.5 percentage points; the cross-validated $k = 79$ smooths the boundary enough to keep variance in check
- The low-dimensional lasso fit shows exactly the behaviour it is known for: $X_5$ and $X_6$ shrunk to precisely zero, $X_4$ to $\approx 0.008$, leaving essentially

$$
\log\left(\frac{p}{1-p}\right) = -0.326 + 0.682 X_1 + 0.132 X_2 + 0.168 X_3
$$

- Adding 197 more noise dimensions **collapsed kNN's accuracy by 14.6 points** (distances lose meaning in high dimensions, the curse of dimensionality), while the lasso barely moved (67.28% → 67.02%): it simply zeroed out virtually all 200 noise coefficients
- kNN's high-dimensional fit was poor even on training data (62.76%), showing it suffered from **both** high variance and high bias

<br>

## Part B: choosing the number of components

Component retention was triangulated with four criteria: proportion of variance explained (PVE), the cumulative PVE / scree elbow, Kaiser's eigenvalue rule, and Horn's parallel analysis.

<p align="center">
  <img src="img/cpve.png" width="480">
  <br>
  <em>Cumulative proportion of variance explained per number of components.</em>
</p>

<p align="center">
  <img src="img/parallel_scree.png" width="560">
  <br>
  <em>Horn's parallel analysis: observed eigenvalues against the mean eigenvalues of 1,000 simulated datasets.</em>
</p>

**Results:**
- The elbow sits at **PC5**; the CPVE-ratio criterion peaks going from component 5 to 6 (ratio = 1.62)
- PC5 still explains 5.37% of variance, PC6 only 3.32%, with all later components equally flat
- Kaiser's rule agrees (eigenvalues of PC1–PC5 are $> 1$; PC6 just misses with $\lambda_6 = 0.995$), and in parallel analysis the 6th eigenvalue falls exactly on the simulated mean
- Decision: keep **5 components**, jointly explaining **56.89%** of the variance. This is the conservative choice that also maximizes interpretability

<br>

## Part B: interpreting the components, recovering the Big Five

To give the retained components meaning, the loading matrix was **varimax-rotated**, which polarizes the loadings (high → higher, low → lower) so each component draws on a distinct block of items.

<p align="center">
  <img src="img/biplot.png" width="560">
  <br>
  <em>Biplot of the first two principal components.</em>
</p>

**Results:**

| Component | High-loading items | Interpretation |
|---|---|---|
| PC1 | anxiety, hostility, depression, self-consciousness, impulsiveness, vulnerability | **Neuroticism** |
| PC2 | warmth, gregariousness, assertiveness, activity, excitement-seeking, positive emotions | **Extraversion** |
| PC3 | trust, straightforwardness, altruism, compliance, modesty, tender-mindedness | **Agreeableness** |
| PC4 | competence, order, dutifulness, achievement striving, self-discipline, deliberation | **Conscientiousness** |
| PC5 | fantasy, aesthetics, feelings, ideas, actions, values | **Openness** |

- The five rotated loading clusters map one-to-one onto the **Big Five / OCEAN** model, recovered purely from the covariance structure, without any labels
- PC5 (openness) is the cleanest component: after rotation, only its six defining items load on it at all

<br>

## Part B: k-means clustering

k-means was run on the retained 5-component score matrix; the number of clusters was chosen via the elbow method on the within-cluster sum of squares and cross-checked visually in PC1–PC2 space.

<p align="center">
  <img src="img/elbow_wss.png" width="480">
  <br>
  <em>Within-cluster sum of squares against the number of clusters.</em>
</p>

<p align="center">
  <img src="img/kmeans_clusters.png" width="600">
  <br>
  <em>The three k-means personality profiles in the space of the first two components.</em>
</p>

**Results:**
- The elbow suggests $k = 3$; in PC1–PC2 space the three clusters separate without overlap, while $k = 4$ introduces substantial overlap
- Cluster sizes: **284 / 390 / 326** students
- Comparing cluster means on the rotated components shows that the groups do **not** differ on agreeableness, conscientiousness, or openness. The profiles are defined almost entirely by **neuroticism and extraversion**: group 2 is high-neurotic and average-extraverted, group 1 is low-neurotic and extraverted, group 3 is low-neurotic and comparatively introverted

<br>

## Part B: hierarchical clustering

Hierarchical clustering (Euclidean distance on the 5-component scores) was run with complete, average, and single linkage as a robustness check on the k-means solution.

<p align="center">
  <img src="img/dendrogram_complete.png" width="640">
  <br>
  <em>Complete-linkage dendrogram with the chosen cut (red line, h = 13).</em>
</p>

**Results:**
- With 1,000 observations the dendrogram is too dense for a full taxonomy, but a clear macro-structure emerges; cutting at $h = 13$ yields **3 clusters of 198 / 487 / 315** students
- Group 3 is nearly identical in size across both algorithms (326 vs. 315); the methods disagree mainly on the boundary between groups 1 and 2
- A finer 5-cluster cut is defensible and would mostly subdivide the largest cluster. The granularity choice mirrors the resolution trade-off inherent to all clustering

<br>

# 🛠️ Implementation details

## Project structure

```
01/
├── ind_assignment01_JD.Rmd           # main analysis (R Markdown): Parts A & B
├── ind_assignment01_JD.pdf           # knitted report (submitted)
├── ind_assignment_01_JDR.R           # standalone R script version
├── GenerateDataSDS.R                 # simulation function for the Part A data
├── Data4036018.csv                   # simulated classification data (Part A)
├── data.US.csv / data.US.txt         # personality data, 1,000 students (Part B)
└── 2024-assignment_1.pdf             # assignment instructions
```

## Quickstart

```r
# required packages
install.packages(c("readr", "caret", "class", "glmnet", "ModelMetrics",
                   "dplyr", "nFactors", "ISLR2", "HSAUR", "ggplot2"))

# knit the full analysis to PDF
rmarkdown::render("ind_assignment01_JD.Rmd")

# or regenerate the Part A data with your own seed
source("GenerateDataSDS.R")
data <- GenerateDataSDS(seed = 4036018)
```

All model fits use `set.seed(4036018)` for reproducibility; training/test data are split 50/50 (5,000 / 5,000 observations).

<br>

# 💡 What can we take away from this?

No classifier dominates universally: the same kNN that wins by 4+ percentage points in six dimensions loses by 10 in two hundred. Which method is "right" depends on the ratio of signal to noise dimensions. Flexibility pays off only as long as the variance it introduces stays controlled, and regularization pays off exactly when it doesn't. On the unsupervised side, PCA plus clustering recovered the Big Five structure without ever being told it exists, a nice reminder that well-established psychological constructs are visible directly in the covariance structure of the data.

<br>

# Reference

James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021).
*An Introduction to Statistical Learning with Applications in R* (2nd ed.). Springer.
