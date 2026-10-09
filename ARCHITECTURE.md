# DataCo Supply Chain: Data Science Project Architecture

> **For Claude Code:** read this whole file before every task. It is the single source of truth for this project. If a request conflicts with this file, or this file doesn't cover something, **stop and ask John**. Never guess.

---

## 1\. What this project is

**A data science project with supporting engineering, not an engineering project with some data science.**

John (final-year Software Engineering student, aiming for a junior Data Scientist role at a multinational) is building this as his main portfolio project. It uses the **DataCo Smart Supply Chain** dataset to solve real supply chain problems with ML. Then it shows the results in a dashboard, backed by a clean, tested, reproducible data pipeline.

### Audience

**Data science recruiters and hiring managers** who will skim the GitHub repo. Everything should be easy to understand in 2 minutes from the README, and solid when someone digs deeper.

### What "good" looks like: three equal pillars

| Pillar | What it means |
| :---- | :---- |
| **Models** | Four well-evaluated ML use cases, explained with SHAP, judged by business cost, not just accuracy |
| **Insights** | Strong EDA, a clear business story, written recommendations, a 4-page Power BI dashboard |
| **Pipeline** | Reproducible data flow: Docker, Postgres, dbt (tested), MLflow, Airflow, FastAPI |

No pillar should be weak. When forced to choose, **correctness and clarity beat more features**.

### Timeline

Target is about 4 weeks at 4 to 6 hours a day, but **the timeline is flexible. Quality and doing it right matter more than speed.** Never cut corners to save time without asking.

---

## 2\. How Claude Code must work on this project (most important section)

### 2.1 Who writes what

| Area | Who writes it | Claude Code's role |
| :---- | :---- | :---- |
| Engineering (Docker, Postgres setup, ingestion, dbt, MLflow setup, Airflow, FastAPI, CI) | **Claude Code** | Writes it **and teaches it** so John fully understands every line |
| Data science notebooks (EDA, feature exploration, modeling experiments) | **John** | Creates the notebook outline with section headings and hints, answers questions, reviews John's work, points out mistakes (especially leakage). **Does not write the analysis for him** unless he asks |
| Turning John's final notebook logic into `src/ml/` scripts | **Claude Code** | Converts it faithfully, explains every change, keeps John's logic and decisions |
| Docs (model cards, ADRs, README) | Together | Claude Code drafts, John edits. Model cards must reflect John's actual results |

John must be able to **explain every file in an interview**. If something is too complex to explain simply, it is probably too complex for this project. Simplify it or ask.

### 2.2 Teaching protocol: every step, no exceptions

For **every step** (not just every phase):

1. **Before building:** explain in simple words what you're about to build, why the project needs it, and how it connects to the rest. Define every new term the first time it appears (for example: "a *container* is...").  
2. **Build** only that one step.  
3. **After building:**  
   - List every file created or changed, with one line on what each does.  
   - Walk through the important parts of the code in plain English.  
   - Give John the exact commands to **run and test it himself**, and what he should see.  
   - Explain how this step affects the data, the models, or the final output.  
   - Mention one thing that commonly goes wrong here and how to spot it.  
4. **Stop and wait** for John to say continue. Never start the next step on your own.

### 2.3 Hard rules

- **Ask before** adding any tool, library, or service not listed in Section 4\.  
- **Ask before** any decision listed as open in Section 13\.  
- **Never** commit data files, `.env`, secrets, or credentials. **The repo is public from day one.**  
- **Never** edit or overwrite anything in `data/raw/`.  
- **Never** use a column that leaks the target as a feature (Section 8.3). If unsure, ask.  
- Prefer the simplest solution that works. No clever abstractions John can't explain.  
- Use Python `logging`, not `print`, in `src/` code (fine in notebooks).

### 2.4 Git workflow

- One branch per phase: `phase-00-setup`, `phase-01-load-raw`, and so on.  
- Small commits after each step, with Conventional Commit messages (`feat:`, `fix:`, `docs:`, `chore:`, `test:`).  
- At the end of a phase: open a pull request into `main` with a summary of what was built. CI must pass before merging.  
- John merges. Claude Code does not merge into `main` itself.

---

## 3\. Environment

| Item | Value |
| :---- | :---- |
| OS | Windows, 16 GB RAM |
| Docker | Docker Desktop with WSL2. Limit WSL2 to about 8 GB in `.wslconfig` so Windows, Power BI, and the browser stay usable |
| Python | 3.11+, **local virtual environment on Windows** (venv or uv, chosen in Phase 0 with John). Notebooks run locally in VS Code |
| Databases and services | Run in Docker; local Python connects to them via `localhost` |
| Later | Once Docker is proven stable, John may move Python/notebooks into Docker (open decision, Section 13\) |

**Windows rules:**

- `.gitattributes` must include `* text=auto eol=lf` (CRLF line endings break scripts inside containers).  
- Use paths that work on Windows and Linux (`pathlib`, never hardcoded `C:\...`).  
- Every Docker service gets a memory limit and a healthcheck.

---

## 4\. Tech stack (fixed, ask before changing)

| Purpose | Tool | Arrives in phase |
| :---- | :---- | :---- |
| Containers | Docker \+ Docker Compose | 0 |
| Warehouse | PostgreSQL 16 | 0 |
| Data loading | Python (pandas \+ psycopg) | 1 |
| Transformations \+ data quality | dbt-core \+ dbt-postgres (dbt tests only, no Great Expectations) | 2 |
| Analysis | Jupyter notebooks, pandas, matplotlib/seaborn/plotly | 3 |
| ML | scikit-learn, XGBoost or LightGBM, SHAP, statsmodels/Prophet-type tool for forecasting (choose with John in Phase 6\) | 4 to 7 |
| Experiment tracking \+ model registry | MLflow | 4 (tracking), 8 (registry) |
| Orchestration | Apache Airflow (LocalExecutor, no Celery/Redis) | 9 |
| Model serving | FastAPI \+ Pydantic | 10 |
| Monitoring | Evidently, **scope is an open decision** (Section 13\) | 11 |
| Dashboard | Power BI Desktop | 12 |
| Code quality | ruff (lint \+ format), pytest, pre-commit | 0 onward |
| CI | GitHub Actions | 0 onward |

**Not used:** Spark, Kafka, cloud services, Great Expectations, Celery, Redis.

---

## 5\. Dataset

**Source:** Kaggle, "DataCo SMART SUPPLY CHAIN FOR BIG DATA ANALYSIS". Used **as-is**, with no artificial dirt added.

| File (in `data/raw/`) | Content | Approx. size |
| :---- | :---- | :---- |
| `DataCoSupplyChainDataset.csv` | Orders at order-item level, 53 columns | \~180k rows |
| `tokenized_access_logs.csv` | Website clickstream: product, category, department, date, hour, IP, URL | \~470k rows |
| `DescriptionDataCoSupplyChain.csv` | Column dictionary | small |

**Known quirks (verify, don't assume):**

- The orders CSV is **not UTF-8**; read with `encoding="latin-1"`.  
- Column names have spaces and parentheses (for example `Days for shipping (real)`).  
- Some customer fields are masked or empty (for example `Customer Email`, `Customer Password`, `Product Description`). These are candidates to drop in silver; confirm with John.  
- Confirm the date range of the orders in Phase 3 EDA; it affects the time-based split and forecasting.

---

## 6\. Architecture overview

 data/raw/ (3 CSVs, never edited)

      │

      │  Phase 1: Python loader (method is an open decision: one-time load or simulated daily batches)

      ▼

 ┌──────────────────────── PostgreSQL (database: warehouse) ────────────────────────┐

 │  bronze.\*   raw tables, exactly as loaded \+ audit columns                         │

 │  silver.\*   cleaned, typed, renamed, deduplicated              (dbt staging/int)  │

 │  gold.\*     star schema for BI \+ ML feature tables             (dbt marts)        │

 │  ml.\*       model predictions written back for Power BI                           │

 │  meta.\*     load log (and watermarks if batch loading is chosen)                  │

 └───────────────┬──────────────────────────────┬────────────────────────────────────┘

                 │                              │

                 ▼                              ▼

     Notebooks (John's DS work)          Power BI (reads gold.\* and ml.\*)

                 │

                 ▼

     src/ml/ training scripts ──► MLflow (experiments, metrics, registry)

                                          │

                                          ▼

                                 FastAPI /predict (loads registered model)

                                          │

                                 Evidently monitoring (scope TBD)

 Airflow (Phase 9\) automates the chain: load ─► dbt build \+ tests ─► train ─► register ─► score

Databases inside the one Postgres container: `warehouse` (project data), `mlflow` (MLflow backend), `airflow` (added in Phase 9).

---

## 7\. Repository structure

supply-chain-platform/

├── CLAUDE.md                   \# tiny pointer: "read ARCHITECTURE.md first"

├── ARCHITECTURE.md             \# this file

├── README.md                   \# recruiter-facing: story, diagram, results, how to run

├── Makefile                    \# short commands: make up, make down, make load, make dbt, make test, make lint

├── docker-compose.yml

├── .env.example                \# placeholder variable names only

├── .gitignore                  \# data/, .env, mlruns/, mlartifacts/, target/, logs/, \_\_pycache\_\_/, .venv/, \*.pbix, .ipynb\_checkpoints/

├── .gitattributes              \# \* text=auto eol=lf

├── pyproject.toml              \# dependencies \+ ruff \+ pytest config

├── .pre-commit-config.yaml

├── .github/workflows/ci.yml

│

├── data/                       \# gitignored

│   ├── raw/                    \# the 3 Kaggle files, never edited

│   └── landing/                \# only used if batch loading is chosen

│

├── docker/

│   ├── postgres/init/          \# SQL run on first start: databases, schemas, roles

│   ├── mlflow/Dockerfile

│   ├── airflow/Dockerfile      \# Phase 9

│   └── api/Dockerfile          \# Phase 10

│

├── src/

│   ├── ingestion/              \# config.py, schemas.py (file contracts), loader.py (+ splitter.py if batches)

│   ├── ml/

│   │   ├── common/             \# shared: data access, time split, evaluation, SHAP, MLflow logging

│   │   ├── late\_delivery/      \# train.py, predict.py

│   │   ├── fraud/

│   │   ├── forecasting/

│   │   └── segmentation/

│   ├── api/                    \# FastAPI app (Phase 10\)

│   └── monitoring/             \# Evidently scripts (Phase 11\)

│

├── dbt/

│   ├── dbt\_project.yml

│   ├── profiles.yml            \# reads env vars, no secrets

│   ├── models/

│   │   ├── sources.yml

│   │   ├── staging/            \# stg\_\*  (silver)

│   │   ├── intermediate/       \# int\_\*  (silver)

│   │   └── marts/

│   │       ├── core/           \# dim\_\*, fct\_\*  (gold, for BI)

│   │       └── features/       \# feat\_\*  (gold, for ML)

│   ├── tests/                  \# singular business-rule tests

│   ├── macros/

│   └── seeds/                  \# tiny lookups only

│

├── dags/                       \# Airflow DAGs (Phase 9\)

├── tests/                      \# pytest: ingestion, features, (API later)

│

├── notebooks/                  \# John's DS work, numbered in reading order

│   ├── 01\_eda/

│   ├── 02\_late\_delivery/

│   ├── 03\_fraud/

│   ├── 04\_forecasting/

│   └── 05\_segmentation/

│

├── reports/

│   ├── figures/                \# exported charts used in README and findings

│   └── findings.md             \# business insights and recommendations

│

├── powerbi/                    \# screenshots \+ data-model notes (.pbix gitignored, see Phase 12\)

│

└── docs/

    ├── business\_story.md       \# written after EDA (Phase 3\)

    ├── data\_dictionary.md      \# source link, download date, column meanings

    ├── model\_cards/            \# one per model

    ├── adr/                    \# decision records: NNNN-title.md

    └── diagrams/               \# architecture diagram for the README

---

## 8\. Data science design

### 8.1 Use cases (all four at full depth)

**Late delivery** is the main use case, built first and used to set the template the others follow. The list may change after EDA, and John decides.

| \# | Use case | Type | Likely target (confirm in EDA) | Business question |
| :---- | :---- | :---- | :---- | :---- |
| 1 | **Late delivery risk** (main) | Binary classification | `Late_delivery_risk` | Which orders will arrive late, known at order time, so operations can act early? |
| 2 | Fraud detection | Binary classification, highly imbalanced | `Order Status == 'SUSPECTED_FRAUD'` | Which orders should be held for review before shipping? |
| 3 | Demand forecasting | Time series | Quantity/sales by category (or product) per day/week | How much will we sell next period, to plan stock? |
| 4 | Customer segmentation | Clustering (e.g. RFM \+ K-Means) | none (unsupervised) | Which customer groups exist and how should each be treated? |

"Full depth" means every use case gets: EDA section, features in dbt, notebook experiments, a `src/ml/` training script, MLflow tracking, a model card, findings in `reports/findings.md`, and output in Power BI. Registry, serving, and monitoring apply to the supervised models; which ones get a FastAPI endpoint is decided per model with John.

### 8.2 Modeling standard (applies to every supervised model)

1. **Baseline first:** a dummy or simple-rule model, so every result has something to beat.  
2. **Simple model:** Logistic Regression (classification) or a naive/seasonal baseline (forecasting).  
3. **Strong models:** Random Forest and XGBoost or LightGBM.  
4. **Tuning** with cross-validation that respects time (`TimeSeriesSplit` or an expanding window), never random folds on time-ordered data.  
5. **Threshold selection** based on business cost (Section 8.4).  
6. **Explanation with SHAP:** global importance plus a few individual examples explained in plain English.  
7. **Error analysis:** where the model fails (by market, shipping mode, category).  
8. Everything logged to MLflow: parameters, metrics, feature list, data split dates, git commit, plots.

### 8.3 Leakage rules (critical)

Features must only use information **known at the moment the order is placed**.

For **late delivery**, these columns describe the outcome and are **banned as features**: `Days for shipping (real)`, `Delivery Status`, `Late_delivery_risk` (it's the target), `shipping date (DateOrders)`, and any `Order Status` value that is only known after shipping. `Days for shipment (scheduled)` is allowed (known at order time).

For **fraud**, `Order Status` is the target source and must not appear as a feature.

Every model card lists its **allowed feature list** and why each banned column was excluded. Claude Code must flag any suspected leakage immediately, even in John's notebooks.

### 8.4 Evaluation

- **Split:** time-based. Train on older orders, validate on the next period, test on the most recent period. The exact cut dates are set after EDA and recorded in an ADR.  
- **Late delivery:** PR-AUC as the main metric, plus precision and recall at a threshold chosen by business cost. A missed late order (false negative) and a false alarm (false positive) get explicit assumed costs, written in the model card. ROC-AUC and F1 are reported but not used to choose the model.  
- **Fraud:** same approach as late delivery (PR-AUC \+ cost-based threshold); handle imbalance with class weights first and resampling only if needed.  
- **Forecasting:** MAE and MAPE (or WAPE) against the naive baseline, on a time holdout.  
- **Segmentation:** silhouette score \+ business interpretability of each segment (a named profile per segment).

### 8.5 Clickstream logs

Used as a **feature source**: aggregate views by product/category per day (and by hour if useful), then join to orders by product/category and date, using only views **before** the order time (no future leakage). Built as dbt models in `gold.feat_*`.

### 8.6 Business story

**Open until after EDA.** In Phase 3 John studies the data, then writes `docs/business_story.md` (the company, the stakeholder, the problems, the decisions the models support). Claude Code helps shape it but John decides. Every later artifact (README, findings, dashboard titles, model cards) follows this story.

---

## 9\. Data layers (PostgreSQL)

| Schema | Content | Written by | Rules |
| :---- | :---- | :---- | :---- |
| `bronze` | `orders_raw`, `access_logs_raw` | Python loader | As received, text or loose types, audit columns `_loaded_at`, `_source_file` (plus `_batch_id` if batches). No business logic. Never updated in place |
| `silver` | `stg_*`, `int_*` | dbt | snake\_case names, correct types, trimmed text, parsed dates, masked/empty columns dropped (confirm with John), dedupe on business key |
| `gold` | `dim_*`, `fct_*`, `feat_*` | dbt | Star schema for BI; feature tables for ML; **contracts enforced** on gold models |
| `ml` | `predictions_*`, `segments` | `src/ml/` scripts | Model outputs with model version and scored-at timestamp, for Power BI |
| `meta` | `load_log` (+ `watermarks` if batches) | Python loader | One row per load: source, file, rows, status, start/end time, error |

**Gold star schema (first version, adjust after EDA):**

- Facts: `fct_order_items` (one row per order line), `fct_orders` (one row per order), `fct_web_activity_daily`.  
- Dimensions: `dim_customer`, `dim_product`, `dim_category`, `dim_department`, `dim_geography`, `dim_shipping_mode`, `dim_date`.  
- Features: `feat_late_delivery`, `feat_fraud`, `feat_demand`, `feat_customer_rfm`.

**Database roles:** separate roles for loader, dbt, MLflow, and a **read-only role for Power BI**.

---

## 10\. Data quality and testing

**dbt tests (all models):**

- Keys: `unique` \+ `not_null`.  
- `relationships` between every fact and its dimensions.  
- `accepted_values` on status/category fields.  
- Range checks with `dbt_utils` (quantities ≥ 0, discount rate between 0 and 1, etc.).  
- Singular tests for business rules (e.g. order date ≤ shipping date, scheduled days ≥ 0).  
- Source freshness on bronze `_loaded_at`.  
- Severity: `error` for keys, relationships, and contracts; `warn` for soft business rules.

**pytest (Python):**

- Ingestion: file contract check (right columns, encoding handled), row counts match the raw files, loading twice doesn't duplicate.  
- Features and ML common code: time split never leaks future rows, feature builders return the expected columns.  
- Small fixture files only, never the full dataset.

---

## 11\. CI (GitHub Actions), on every push and pull request

1. `ruff check` and `ruff format --check`  
2. `pytest`  
3. `dbt deps` \+ `dbt compile` (with a dummy profile, no real database)  
4. `docker compose config` (validates the compose file)

CI starts in Phase 0 with lint only and grows as each phase adds code. It must stay green.

---

## 12\. Phases (DS-first order)

Every phase is on its own branch, built **step by step with the teaching protocol (Section 2.2)**, and ends with a PR. Each phase lists its **done-when checks**.

### Phase 0: Setup

- Repo skeleton (folders above), `.gitignore`, `.gitattributes`, `.env.example`, `Makefile`, `pyproject.toml`, pre-commit, tiny `CLAUDE.md`, README stub, CI with lint.  
- `docker-compose.yml` with **Postgres only** (+ healthcheck, memory limit, named volume). Init SQL creates the `warehouse` and `mlflow` databases, the schemas, and the roles.  
- Local Python virtual environment (choose venv or uv with John).  
- ADRs: Postgres as warehouse, dbt-only data quality, no Spark, local Python first.  
- **Done when:** `make up` gives a healthy Postgres; John can connect and see all schemas; `make down` keeps the data; CI is green; the 3 CSVs sit in `data/raw/` and `git status` doesn't show them.

### Phase 1: Load raw data into bronze

- **First, explain both loading options to John (one-time load vs. simulated daily batches) with pros, cons, and effort, and wait for his decision.** Record it in an ADR.  
- Build `schemas.py` (file contracts), `loader.py` (and `splitter.py` if batches), `meta.load_log`, pytest tests.  
- **Done when:** bronze row counts equal the raw file row counts; running the load twice doesn't duplicate; a broken file is rejected and logged; tests pass.

### Phase 2: dbt silver and gold

- dbt project, sources, `stg_*`, `int_*`, gold `dim_*`/`fct_*` with contracts, all tests from Section 10\. Feature tables wait until Phase 4\.  
- **Done when:** `dbt build` passes with zero errors; row counts reconcile bronze → silver → gold (any intentional drops documented); `dbt docs generate` works; Power BI can connect to `gold` with the read-only role.

### Phase 3: EDA and business story (John leads)

- Claude Code creates the `notebooks/01_eda/` outline (sections and guiding questions), then supports and reviews. John does the analysis.  
- Outputs: `docs/business_story.md`, `docs/data_dictionary.md`, first figures in `reports/figures/`, confirmed use-case list, confirmed date range and split dates (ADR).  
- **Done when:** John has written the business story and confirmed the targets, banned columns, and split dates for each use case.

### Phase 4: Late delivery model (main use case)

- dbt `feat_late_delivery` (+ clickstream features), with tests.  
- Start **MLflow tracking** (Docker service, backend in Postgres `mlflow` db) so every experiment is logged from the start.  
- John's notebook `02_late_delivery/`: baseline → simple → strong models → tuning → threshold by cost → SHAP → error analysis.  
- Claude Code converts the final approach into `src/ml/common/` \+ `src/ml/late_delivery/train.py`, with pytest tests.  
- Model card \+ findings section.  
- **Done when:** `python -m src.ml.late_delivery.train` reproduces John's best result and logs it to MLflow; leakage review passed; model card written.

### Phase 5: Fraud detection

Same pattern as Phase 4 (feature table, notebook, `src/ml/fraud/`, MLflow, model card, findings), with imbalance handling.

### Phase 6: Demand forecasting

Same pattern; choose the forecasting tool with John (ADR); time-based backtesting against a naive baseline.

### Phase 7: Customer segmentation

Same pattern; RFM features in dbt, clustering, named segment profiles, segments written to `ml.segments`.

### Phase 8: Model registry and scoring

- MLflow Model Registry: register each final model, use a `champion` alias.  
- Batch scoring scripts that write predictions to `ml.predictions_*` with model version.  
- **Done when:** each model can be retrained, registered, and used to score from one command each.

### Phase 9: Airflow orchestration

- Add Airflow (LocalExecutor) to Docker Compose with memory limits; `airflow` database in Postgres.  
- DAGs: load → dbt build \+ test → train → register → score. dbt runs via BashOperator inside the Airflow image.  
- **Done when:** one DAG run goes end to end; a failing dbt test turns the DAG red and stops downstream tasks.

### Phase 10: FastAPI serving

- FastAPI app loading the `champion` model(s) from the registry; `/health` and `/predict` endpoints with Pydantic validation; pytest tests; Docker service.  
- **Done when:** a sample request returns a prediction matching the batch scoring for the same input.

### Phase 11: Monitoring (scope decided by John before starting)

- Option A: Evidently drift reports only. Option B: drift reports \+ automatic retraining trigger in Airflow. Claude Code explains both, then waits for John's choice.

### Phase 12: Power BI dashboard

Four pages, connected to `gold` and `ml` with the read-only role:

1. **Executive overview:** sales, profit, orders, key KPIs by market and over time.  
2. **Delivery performance:** late rates by shipping mode, region, product; delay trends.  
3. **Model outputs:** late-delivery risk, fraud flags, forecasts vs actuals, segments.  
4. **Customer and product:** segment profiles, top products/categories, web traffic vs sales.

Screenshots go in `powerbi/` and the README. Because `.pbix` is gitignored by default, decide with John whether to commit the `.pbix` (it contains no secrets if credentials aren't saved) or share screenshots only.

### Phase 13: Polish

- README: the business story in brief, architecture diagram, results per model (with the business meaning), dashboard screenshots, how to run in a few commands.  
- Final check of all model cards, ADRs, and findings.  
- **Done when:** a stranger can clone the repo and run it from the README alone.

---

## 13\. Open decisions (ask John, never decide alone)

| \# | Decision | When |
| :---- | :---- | :---- |
| 1 | Data loading: one-time load vs simulated daily batches | Start of Phase 1 |
| 2 | Business story and stakeholder | End of Phase 3 |
| 3 | Final use-case list (may change after EDA) | End of Phase 3 |
| 4 | Time split cut dates | End of Phase 3 |
| 5 | Forecasting tool and grain (daily/weekly, product/category) | Start of Phase 6 |
| 6 | Which models get a FastAPI endpoint | Start of Phase 10 |
| 7 | Monitoring scope (reports only vs auto-retrain) | Start of Phase 11 |
| 8 | Move Python/notebooks into Docker or keep local | After Docker is stable (any time) |
| 9 | Commit the `.pbix` or screenshots only | Phase 12 |
| 10 | venv vs uv | Phase 0 |

---

## 14\. Documentation

- **Model cards** (`docs/model_cards/<model>.md`): goal, business question, target, allowed features and banned columns, split dates, metrics vs baseline, chosen threshold and its cost assumptions, SHAP highlights, known limits.  
- **ADRs** (`docs/adr/NNNN-title.md`): Context → Decision → Alternatives considered → Consequences. One per real decision (stack choices, every item in Section 13).  
- **Architecture diagram** (`docs/diagrams/`): one clear picture of Section 6 for the README.  
- **README**: written for a recruiter first, then for a technical reader.

---

## 15\. Conventions

- **Python:** type hints, small functions, `ruff` formatting, config from environment variables, `pathlib` for paths, `logging` in `src/`.  
- **SQL/dbt:** snake\_case; prefixes `stg_`, `int_`, `dim_`, `fct_`, `feat_`; one CTE per logical step; every model has a description and tests in YAML.  
- **Notebooks:** numbered, a markdown cell explaining the goal at the top and a conclusions cell at the bottom; clear outputs before committing large plots if file size grows.  
- **Naming:** clear and boring beats short and clever.


# CLAUDE.md

Read `ARCHITECTURE.md` fully before every task. It is the source of truth for this project.

- This is a data science project with supporting engineering. Correctness and clarity beat more features.
- Follow the teaching protocol (ARCHITECTURE.md Section 2.2): explain, build one step, explain, then stop and wait.
- Ask before adding tools or making any open decision (Section 13). Never guess.