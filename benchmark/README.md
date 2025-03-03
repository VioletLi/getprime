# Experiments
## Benchmarks
- [x] textbook.1/activestudents **error: 02 not disjoint, natural join**
- [x] textbook.1/bstudents  **error: 03 putget is not validated, natural join**
- [x] textbook.1/goodstudents
- [x] textbook.2/paramountmovies
- [x] textbook.3/newpc  **error: 03 putget is not validated, natural join without primary key**, 68 lines
- [x] mysql-tutorial/officeinfo
- [x] mysql-tutorial/luxuryitems
- [x] oracle-tutorial/car_master
- [x] oracle-tutorial/all_cars  **error: 03 putget is not validated, natural join**   
- [x] oracle-tutorial.2/vw_customers  
- [x] oracle-tutorial.2/vw_customers.2  **error: 02 not disjoint, if only left deletion rule, then the putget is not validated**
- [x] postgres-tutorial/emp_view
- [x] postgres-tutorial.2/usa_city
- [x] postgres-sharding/measurement
- [x] sqlserver-tutorial/vw_brands
- [x] sqlserver-tutorial/vw_brands.2
- [x] pods06/tracks1    **error: 03 putget is not validated, natural join**  
- [x] pods06/tracks2
- [x] pods06/tracks3
- [x] case-study/residents
- [x] case-study/ced
- [x] case-study/residents1962
- [x] case-study/employees
- [x] case-study/researchers
- [x] case-study/retired
- [x] stackexchange/ukaz_lok
- [x] stackexchange.2/purchaseview  **error: 03 putget is not validated, natural join**  
- [x] stackexchange.2/purchaseview.2    **error: 03 putget is not validated, natural join**  
- [x] stackexchange.3/message   
- [x] stackexchange.4/outstanding_task  **error: 03 putget is not validated**
- [x] stackexchange.4/outstanding_task.2    **error: 03 putget is not validated**
- [x] stackexchange.4/outstanding_task.3    **error: 03 putget is not validated**
- [x] stackexchange.5/products  **error: 03 putget is not validated**
- [x] stackexchange.6/poi_view  **error: 01 time out for 1h in birds**
- [x] stackoverflow/VW_COMPANY_PHONELIST
- [x] stackoverflow.2/vehicle_view  **error: 03 putget is not validated, natural join**
- [x] stackoverflow.3/vwEmployees   **error: 01 time out for 1h in birds, 123 lines of temp.dl generated, natural join**
- [x] stackoverflow.4/Koncerty  **error: 01 time out for 1h in birds, 457 lines of temp.dl generated, natural join**
- [x] stackoverflow.5/AverageByGroup
- [x] personalblog/person_detail_job_vw 

## summary table



| Benchmark Name                     | view type                                                    | LOC in BIRDS | LOC in our tool |      Generated LOC      |            Correctness             | Generation  & Verification Time (s) |
| :--------------------------------- | ------------------------------------------------------------ | :----------: | :-------------: | :---------------------: | :--------------------------------: | :---------------------------------: |
| textbook.1/activestudents          | selection + projection + **join** on non-pk attr + projection |      19      |       24        | **error**: not disjoint |                 -                  |                  -                  |
| textbook.1/bstudents               | selection + **join** on PK + projectioin                     |      13      |       18        |           41            | **error**: putget is not validated |               121.934               |
| textbook.1/goodstudents            | selection + projection                                       |      5       |        9        |           17            |                 √                  |               21.602                |
| textbook.2/paramountmovies         | selection + projection                                       |      7       |        8        |           16            |                 √                  |               21.233                |
| textbook.3/newpc                   | **join** without PK + selection                              |      15      |       11        |           68            | **error**: putget is not validated |              1114.708               |
| mysql-tutorial/officeinfo          | projection                                                   |      7       |        8        |           16            |                 √                  |               50.828                |
| mysql-tutorial/luxuryitems         | selection                                                    |      5       |        5        |           19            |                 √                  |               31.025                |
| oracle-tutorial/car_master         | projection                                                   |      4       |        8        |           16            |                 √                  |               23.341                |
| oracle-tutorial/all_cars           | **join** with PK                                             |      13      |       19        |           68            | **error**: putget is not validated |               107.189               |
| oracle-tutorial.2/vw_customers     | **join** with PK, only insertion                             |      19      |       24        |           40            |                 √                  |               15.125                |
| oracle-tutorial.2/vw_customers.2   | **join** on non-pk, projection on non-pk                     |      19      |       26        | **error**: not disjoint |                 -                  |                  -                  |
| postgres-tutorial.2/usa_city       | projection + selection                                       |      5       |        9        |           17            |                 √                  |               37.890                |
| postgres-sharding/measurement      | union                                                        |      13      |       13        |           31            |                 √                  |               11.201                |
| sqlserver-tutorial/vw_brands       | union(distinct) + projection                                 |      8       |       14        |           26            |                 √                  |               47.529                |
| sqlserver-tutorial/vw_brands.2     | union(distinct) + projection                                 |      9       |       14        |           25            |                 √                  |               29.393                |
| pods06/tracks1                     | **join** with PK                                             |      12      |       19        |           124           | **error**: putget is not validated |               210.818               |
| pods06/tracks2                     | projection                                                   |      8       |        8        |           16            |                 √                  |               93.968                |
| pods06/tracks3                     | selection                                                    |      7       |        5        |           19            |                 √                  |               51.524                |
| case-study/residents               | union                                                        |      10      |       22        |           44            |                 √                  |               581.067               |
| case-study/good_residents          | projection + complement                                      |      6       |       12        |           21            |                 √                  |               22.062                |
| case-study/ced                     | complement                                                   |      6       |        7        |           28            |                 √                  |               28.572                |
| case-study/residents1962           | selection                                                    |      6       |       10        |           18            |                 √                  |               216.825               |
| case-study/employees               | selection                                                    |      6       |       12        |           21            |                 √                  |               28.801                |
| case-study/researchers             | projection + selection + intersection                        |      6       |       12        |           25            |                 √                  |               13.900                |
| case-study/retired                 | projection + complement                                      |      6       |       12        |           25            |                 √                  |               13.031                |
| stackexchange/ukaz_lok             | identity                                                     |      6       |        6        |           20            |                 √                  |               241.192               |
| stackexchange.2/purchaseview       | **join** with PK                                             |      19      |       24        |           48            | **error**: putget is not validated |               352.441               |
| stackexchange.2/purchaseview.2     | **join** with PK                                             |      15      |       24        |           31            | **error**: putget is not validated |               31.632                |
| stackexchange.3/message            | union(distinct)                                              |      8       |        8        |           28            |                 √                  |               261.168               |
| stackexchange.4/outstanding_task   | **join** without PK+ projection                              |      10      |       28        |           29            | **error**: putget is not validated |               53.939                |
| stackexchange.4/outstanding_task.2 | **join** with PK+ projection                                 |      15      |       43        |           120           | **error**: putget is not validated |               119.271               |
| stackexchange.4/outstanding_task.3 | **join** with PK+ projection                                 |      13      |       43        |           120           | **error**: putget is not validated |               118.466               |
| stackexchange.5/products           | left join                                                    |      16      |       22        |                         |                 √                  |                                     |
| stackexchange.6/poi_view           | projection + **join**                                        |      12      |       18        |           117           |     **error**: time out for 1h     |             **over 1h**             |
| stackoverflow/VW_COMPANY_PHONELIST | union(distinct)                                              |      11      |       19        |           35            |                 √                  |              2424.871               |
| stackoverflow.2/vehicle_view       | **join** with PK + projection                                |      20      |       23        |           47            | **error**: putget is not validated |               49.032                |
| stackoverflow.3/vwEmployees        | **join** with PK                                             |      12      |       18        |           123           |     **error**: time out for 1h     |             **over 1h**             |
| stackoverflow.4/Koncerty           | **join** with PK (three db)                                  |      17      |       27        |           457           |     **error**: time out for 1h     |             **over 1h**             |
| personalblog/person_detail_job_vw  | left join                                                    |      14      |       22        |           42            |                 √                  |               232.831               |

| Indicator                                                   | Number |  Rate  | Avg     | Max      | Min    |
| :---------------------------------------------------------- | :----: | :----: | ------- | -------- | ------ |
| Total benchmarks                                            |   39   |   -    |         |          |        |
| Passed benchmarks                                           |   23   | 58.97% | 195.608 | 2424.871 | 11.201 |
| Timeout benchmark for 1h                                    |   4    | 10.26% | -       | -        | -      |
| Failed verification benchmarks, all related to natural join |   10   | 25.64% | 227.943 | 1114.708 | 31.632 |
| Failed generation benchmarks, all related to natural join   |   2    | 5.13%  | -       | -        | -      |





## note:

1. Two cases are not implemented in BIRDS: `postgres-tutorial/emp_view` ; `stackoverflow.5/AverageByGroup`.s
2. generated **LOC** are exp of **original LOC**
3. generation and verification **time** are exp of **original LOC**, **numbers of column** 
4. to speed up the generation and verification, we specify the **GET** for those run slow.
5. original sources have too many columns that do not affect the result of verfication but make it very slow, so we remove those unimportant columns, like `stackexchange.3/message`
6. cannot implement strategies in putdelta, which may cause non-injective, like `pods06/tracks2`
7. cannot implement strategies in putdelta, which is too complex to express in our syntax, like `textbook.1/activestudents`, `textbook.3/newpc`
8. next_xxx_id(ID) may be multiple, but is simplified in our experiments

