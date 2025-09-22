# OLAP Ingestion Comparison Report

## Overview

This report compares two architectures for ingesting and processing OLAP data.
The focus is on measuring **memory usage** under different insertion loads using a controlled Docker-based environment.

### Architectures Evaluated

1. **Debezium + Redpanda (CDC Streaming)**
   *Flow:* PostgreSQL → Debezium → Redpanda → RisingWave → OLAP

2. **Direct Approach**
   *Flow:* PostgreSQL → RisingWave → OLAP

---

## Test Setup

* **Database:** PostgreSQL (running with preloaded schema + data dump)
* **Workload:**

  * Create materialized view by joining multiple tables
  * Insert rows to trigger view updates
  * Test insertion sizes: **500k rows** and **1M rows**
* **Environment:** Docker containers for all components
* **Metric Collected:** Memory usage (per container, before and after insertions)

---

## Results

### 1. Debezium + Redpanda (CDC Streaming)

| Test   | Rows Inserted | Debezium (Before / After) | Redpanda (Before / After) | RisingWave (Before / After) | ClickHouse (Before / After) |
| ------ | ------------- | ------------------------- | ------------------------- | --------------------------- | --------------------------- |
| Test A | 500k          | 1951 MB / 1949 MB         | 791 MB / 699 MB           | 4032 MB / 5269 MB           | 1086 MB / 954 MB            |
| Test B | 1M            | 472 MB / 1839 MB          | 278 MB / 704 MB           | 186 MB / 6892 MB            | 260 MB / 763 MB             |


*Memory graph for 500k rows*

![Memory usage graph](with_debezium-500k.png)

*Memory graph for 1000k rows*

![Memory usage graph](with_debezium-1000k.png)

---

### 2. Direct Approach

| Test   | Rows Inserted | RisingWave (Before / After) | ClickHouse (Before / After) |
| ------ | ------------- | --------------------------- | --------------------------- |
| Test A | 500k          | 487 MB / 5085 MB            | 386 MB / 721 MB             |
| Test B | 1M            | 487 MB / 6024 MB            | 487 MB / 651 MB             |



*Memory graph for 500k rows*

![Memory usage graph](without_debezium-500k.png)

*Memory graph for 1000k rows*

![Memory usage graph](without_debezium-1000k.png)


---

## Observations

* Both architectures successfully handled **1M row insertion**.
* Memory usage patterns differed significantly:

### Debezium + Redpanda (CDC Streaming)

* **Debezium & Redpanda** stayed relatively stable (small increases or even decreases in some runs).
* **RisingWave** showed the **largest memory growth** (from \~4 GB → \~5.3 GB for 500k, and \~186 MB → \~6.9 GB for 1M).
* **ClickHouse** usage fluctuated slightly but remained under 1 GB.

### Direct Approach

* **RisingWave** again consumed the most memory, with large spikes:

  * 500k: \~487 MB → \~5.0 GB
  * 1M: \~487 MB → \~6.0 GB
* **ClickHouse** memory remained moderate (\~650–720 MB).
* No extra overhead from Debezium/Redpanda since they were not in the flow.

**Key Takeaway:**

* Adding Debezium + Redpanda introduces extra components but did not dominate memory consumption — RisingWave was the main memory consumer in both setups.
* The **Direct Approach** uses fewer containers, but RisingWave still spikes heavily under large insertions.
* CDC streaming setup offers more flexibility for downstream consumers at the cost of extra system complexity, but memory behavior was broadly comparable.


---

## Conclusion

* **Scalability:** Both approaches are capable of handling 1M row insertions.
* **Trade-offs:**

  * *Debezium + Redpanda*: Provides event streaming flexibility but adds memory overhead.
  * *Direct Approach*: Simpler, leaner setup with fewer moving parts.
* **Recommendation:** Even though the undirect approach adds memory overhead, the most consuming service is the RisingWave, it is better to use separate server for this particular database.
  For now, 1 million rows test already provide enough evidence that our system is good enough for the current load. If in the future, there is another improvement in terms of performance 
  or scalability, then the `Debezium + Redpanda` approach can be suitable.
