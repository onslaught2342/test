# ============================================================
# GENERATE 10,000 PRODUCTION RECORDS
# ============================================================

import pandas as pd
import numpy as np


# Reproducible random data
np.random.seed(42)


NUMBER_OF_RECORDS = 10_000


# ============================================================
# 1. GENERATE BASIC INFORMATION
# ============================================================

batch_ids = [
    f"B{i:05d}"
    for i in range(1, NUMBER_OF_RECORDS + 1)
]


production_lines = np.random.choice(
    ["Line A", "Line B", "Line C"],
    size=NUMBER_OF_RECORDS
)


# ============================================================
# 2. GENERATE PRODUCTION DATA
# ============================================================

units = np.random.randint(
    500,
    5001,
    NUMBER_OF_RECORDS
)


electricity = np.random.randint(
    1000,
    15001,
    NUMBER_OF_RECORDS
)


fuel = np.random.randint(
    100,
    1001,
    NUMBER_OF_RECORDS
)


raw_transport = np.random.randint(
    200,
    1501,
    NUMBER_OF_RECORDS
)


product_transport = np.random.randint(
    200,
    1501,
    NUMBER_OF_RECORDS
)


waste = np.random.randint(
    20,
    501,
    NUMBER_OF_RECORDS
)


packaging = np.random.randint(
    100,
    801,
    NUMBER_OF_RECORDS
)


# ============================================================
# 3. CREATE DATAFRAME
# ============================================================

df = pd.DataFrame({

    "Batch ID": batch_ids,

    "Production Line": production_lines,

    "Units Produced": units,

    "Electricity (kWh)": electricity,

    "Fuel (L)": fuel,

    "Raw Transport (ton-km)": raw_transport,

    "Product Transport (ton-km)": product_transport,

    "Waste (kg)": waste,

    "Packaging (kg)": packaging

})


# ============================================================
# 4. SAVE CSV
# ============================================================

df.to_csv(
    "production_plant_10000_records.csv",
    index=False
)


# ============================================================
# 5. ALSO SAVE EXCEL
# ============================================================

df.to_excel(
    "production_plant_10000_records.xlsx",
    index=False
)


# ============================================================
# 6. DISPLAY SAMPLE
# ============================================================

print("=" * 70)
print("10,000 RECORD PRODUCTION DATASET")
print("=" * 70)

print(
    f"\nRecords Generated: {len(df):,}"
)

print("\nFirst 10 Records:")

print(
    df.head(10).to_string(
        index=False
    )
)

print("\nFiles Created:")

print(
    "production_plant_10000_records.csv"
)

print(
    "production_plant_10000_records.xlsx"
)