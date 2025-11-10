### Folder case-study
#### all_items.dbpl
```SQL
CREATE VIEW all_items AS
SELECT ITEM FROM on_sale
UNION
SELECT ITEM FROM in_stock;
```

#### all_books.dbpl
```SQL
CREATE VIEW all_books AS
SELECT BOOK, AUTHOR FROM author
UNION
SELECT BOOK, AUTHOR FROM author_old;
```

#### courses.dbpl
```SQL
CREATE VIEW courses AS
SELECT DISTINCT CNAME
FROM enrollment;
```

#### all_authors.dbpl
```SQL
CREATE VIEW all_authors AS
SELECT DISTINCT AUTHOR
FROM author;
```

#### book_info.dbpl
```SQL
CREATE VIEW book_info AS
SELECT A.BOOK, A.AUTHOR, COALESCE(V.VER, 'NULL') FROM author AS A
LEFT OUTER JOIN edition AS V ON A.BOOK = V.BOOK;
```

#### book_bob.dbpl
```SQL
CREATE VIEW book_bob AS
SELECT BOOK, AUTHOR FROM author where AUTHOR = 'Bob';
```

### Folder PODS85
#### ny.*.dbpl
```SQL
CREATE VIEW ny AS
SELECT EMPLOYEE, DEPARTMENT FROM emp
WHERE LOCATION = 'NEW YORK';
```

#### baseball.*.dbpl
```SQL
CREATE VIEW baseball AS
SELECT EMPLOYEE FROM emp
WHERE BASEBALL = true;
```

### Folder BIRDS-benchmark/case-study
#### ced.dbpl
```SQL
CREATE VIEW ced AS
SELECT ed.EMP_NAME, ed.DEPT_NAME FROM ed
WHERE NOT EXISTS (
    SELECT 1 FROM eed
    WHERE eed.EMP_NAME = ed.EMP_NAME AND eed.DEPT_NAME = ed.DEPT_NAME
);
```

#### employees.dbpl
```SQL
CREATE VIEW employees (EMP_NAME, BIRTH_DATE, GENDER) AS
SELECT
    T1.EMP_NAME,
    T1.BIRTH_DATE,
    T1.GENDER
FROM
    residents AS T1
INNER JOIN
    ced AS T2 ON T1.EMP_NAME = T2.EMP_NAME;
```

#### researchers.dbpl
```SQL
CREATE VIEW researchers (EMP_NAME) AS
SELECT T1.EMP_NAME
FROM residents AS T1
INNER JOIN ced AS T2 ON T1.EMP_NAME = T2.EMP_NAME
WHERE T2.DEPT_NAME = 'Research';
```

#### residents.dbpl
```SQL
CREATE VIEW residents (EMP_NAME, BIRTH_DATE, GENDER) AS
SELECT T1.EMP_NAME, T1.BIRTH_DATE, 'M' AS GENDER
FROM male AS T1

UNION

SELECT T2.EMP_NAME, T2.BIRTH_DATE, 'F' AS GENDER
FROM female AS T2

UNION

SELECT T3.EMP_NAME, T3.BIRTH_DATE, T3.GENDER
FROM others AS T3;
```

#### residents1962.dbpl
```SQL
CREATE VIEW residents1962 (EMP_NAME, BIRTH_DATE, GENDER) AS
SELECT T1.EMP_NAME, T1.BIRTH_DATE, T1.GENDER
FROM residents AS T1
WHERE T1.BIRTH_DATE >= '1962-01-01' AND T1.BIRTH_DATE <= '1962-12-31';
```

#### retired.dbpl
```SQL
CREATE VIEW retired (EMP_NAME) AS
SELECT T1.EMP_NAME
FROM residents AS T1
WHERE T1.EMP_NAME NOT IN (
    SELECT T2.EMP_NAME
    FROM ced AS T2
);
```

### Folder BIRDS-benchmark/mysql-tutorial
#### luxuryitems.dbpl
```SQL
CREATE VIEW luxuryitems (ID, NAME, PRICE) AS
SELECT T1.ID, T1.NAME, T1.PRICE
FROM items AS T1
WHERE T1.PRICE > 700.0;
```

#### officeinfo.dbpl
```SQL
CREATE VIEW officeinfo (OFFICECODE, PHONE, CITY) AS
SELECT T1.OFFICECODE, T1.PHONE, T1.CITY
FROM offices AS T1;
```

### Folder BIRDS-benchmark/oracle-tutorial
#### all_cars.dbpl
```SQL
CREATE VIEW all_cars (CAR_ID, CAR_NAME, BRAND_ID, BRAND_NAME) AS
SELECT
    T1.CAR_ID,
    T1.CAR_NAME,
    T1.BRAND_ID,
    T2.BRAND_NAME
FROM
    cars AS T1
INNER JOIN
    brands AS T2 ON T1.BRAND_ID = T2.BRAND_ID;
```

#### cars_master.dbpl
```SQL
CREATE VIEW cars_master (CAR_ID, CAR_NAME) AS
SELECT T1.CAR_ID, T1.CAR_NAME
FROM cars AS T1;
```

### Folder BIRDS-benchmark/personalblog
#### personal_detail_job_vw.dbpl
```SQL
CREATE VIEW person_detail_job_vw (PID, PNAME, JOB) AS
SELECT
    T1.PID,
    T1.PNAME,
    COALESCE(T2.JOB, 'None') AS JOB
FROM
    person_detail AS T1
LEFT JOIN
    person_job AS T2 ON T1.PID = T2.PID;
```

### Folder BIRDS-benchmark/PODS06
#### tracks1.dbpl
```SQL
CREATE VIEW tracks1 (TRACK, DATE, RATING, ALBUM, QUANTITY) AS
SELECT
    T1.TRACK,
    T1.DATE,
    T1.RATING,
    T1.ALBUM,
    T2.QUANTITY
FROM
    tracks AS T1
INNER JOIN
    albums AS T2 ON T1.ALBUM = T2.ALBUM;
```

#### tracks2.dbpl
```SQL
CREATE VIEW tracks2 (TRACK, RATING, ALBUM, QUANTITY) AS
SELECT T1.TRACK, T1.RATING, T1.ALBUM, T1.QUANTITY
FROM tracks1 AS T1;
```

#### tracks3.dbpl
```SQL
CREATE VIEW tracks3 (TRACK, RATING, ALBUM, QUANTITY) AS
SELECT T1.TRACK, T1.RATING, T1.ALBUM, T1.QUANTITY
FROM tracks2 AS T1
WHERE T1.QUANTITY > 2;
```

### Folder BIRDS-benchmark/postgres-sharding
#### measurement.dbpl
```SQL
CREATE VIEW measurement (CITY_ID, LOGDATE, PEAKTEMP, UNITSALES) AS
SELECT T1.CITY_ID, T1.LOGDATE, T1.PEAKTEMP, T1.UNITSALES
FROM measurement_y2006m02 AS T1

UNION ALL

SELECT T2.CITY_ID, T2.LOGDATE, T2.PEAKTEMP, T2.UNITSALES
FROM measurement_y2006m03 AS T2;
```

### Folder BIRDS-benchmark/postgres-tutorial.2
#### usa_city.dbpl
```SQL
CREATE VIEW usa_city (CITY_ID, CITY, COUNTRY_ID) AS
SELECT T1.CITY_ID, T1.CITY, T1.COUNTRY_ID
FROM city AS T1
WHERE T1.COUNTRY_ID = 103;
```

### Folder BIRDS-benchmark/sqlserver-tutorial
#### vw_brands.*.dbpl
```SQL
CREATE VIEW vw_brands (BRAND_NAME, APPROVAL_STATUS) AS
SELECT T1.BRAND_NAME, 'Approved' AS APPROVAL_STATUS
FROM brands AS T1

UNION

SELECT T2.BRAND_NAME, 'Pending Approval' AS APPROVAL_STATUS
FROM brand_approvals AS T2;
```

### Folder BIRDS-benchmark/stackexchange.3
#### message.dbpl
```SQL
CREATE VIEW message (TXTMESSAGEID, MESSAGETECH, MESSAGETYPE, MESSAGE, MESSAGEDATE, MESSAGEMOBILE, MESSAGEREAD, MESSAGESENDER) AS
SELECT
    T1.TXTMESSAGEID,
    'S' AS MESSAGETECH,  -- 插入常量 'S'
    T1.MESSAGETYPE,
    T1.MESSAGE,
    T1.MESSAGEDATE,
    T1.MESSAGEMOBILE,
    T1.MESSAGEREAD,
    T1.MESSAGESENDER
FROM
    messagecentre AS T1

UNION ALL

SELECT
    T2.MESSAGEID AS TXTMESSAGEID, -- 别名匹配视图
    'E' AS MESSAGETECH,  -- 插入常量 'E'
    T2.TYPE AS MESSAGETYPE,     -- 别名匹配视图
    T2.TEXT AS MESSAGE,         -- 别名匹配视图
    T2.DATE AS MESSAGEDATE,     -- 别名匹配视图
    T2.ADDRESS AS MESSAGEMOBILE, -- 别名匹配视图 (ADDRESS 对应 MOBILE)
    T2.READ AS MESSAGEREAD,     -- 别名匹配视图
    T2.SENDER AS MESSAGESENDER  -- 别名匹配视图
FROM
    messagecentreemail AS T2;
```

### Folder BIRDS-benchmark/stackexchange.4
#### outstanding_task.*.dbpl
```SQL
CREATE VIEW outstanding_task (ID, PARENT_TASK_ID, CINEMA_ID, VENUE_ID, MOVIE_ID, EVENT_ID, RESULT, CONTEXT, GUIDE, STARTED_AT, ENDED_AT, CREATED_AT, UPDATED_AT) AS
SELECT
    T1.ID, T1.PARENT_TASK_ID, T1.CINEMA_ID, T1.VENUE_ID, T1.MOVIE_ID, T1.EVENT_ID, T1.RESULT, T1.CONTEXT, T1.GUIDE, T1.STARTED_AT, T1.ENDED_AT, T1.CREATED_AT, T1.UPDATED_AT
FROM
    task AS T1
INNER JOIN
    task AS T2 ON T1.PARENT_TASK_ID = T2.ID;
```

### Folder BIRDS-benchmark/stackexchange.5
#### products.dpbl
```SQL
CREATE VIEW products (ID, TITLE, DESCRIPTION, MANUFACTURER_ID, CREATED_AT, UPDATED_AT, MPN, VISIBLE, SUBSCRIPTIONS_COUNT) AS
SELECT
    T1.ID,
    T1.TITLE,
    T1.DESCRIPTION,
    T1.MANUFACTURER_ID,
    T1.CREATED_AT,
    T1.UPDATED_AT,
    T1.MPN,
    T1.VISIBLE,
    COALESCE(T2.SUBSCRIPTIONS_COUNT, 0) AS SUBSCRIPTIONS_COUNT
FROM
    products_raw AS T1
LEFT JOIN
    subscriptions_agg AS T2 ON T1.ID = T2.PRODUCT_ID;
```

<!-- ### Folder BIRDS-benchmark/stackexchange.6
#### poi_view.dbpl
```SQL
CREATE VIEW poi_view (POI_ID, COL_A, COL_B, COL_D, COL_E) AS
SELECT
    T1.POI_ID,
    T1.COL_A,
    T1.COL_B,
    T2.COL_D,
    T2.COL_E
FROM
    poi AS T1
INNER JOIN
    points AS T2 ON T1.POI_ID = T2.POI_ID;
``` -->

### Folder BIRDS-benchmark/stackexchange
#### ukaz_lok.dbpl
```SQL
CREATE VIEW ukaz_lok (_KOD, _NAZEV, _KATASTR, _PRESNOST, _SIRKA, _DELKA) AS
SELECT
    T1.KOD_LOK,
    T1.NAZEV,
    T1.KATASTR,
    T1.PRESNOST,
    50.0 AS _SIRKA,  -- 插入常量 50.0
    14.0 AS _DELKA   -- 插入常量 14.0
FROM
    lokalita AS T1;
```

### Folder BIRDS-benchmark/stackoverflow.3
#### vwEmployees.dbpl
```SQL
CREATE VIEW vwemployees (PERSONID, EMPLOYEEID, FIRSTNAME, LASTNAME, TITLE) AS
SELECT
    T1.PERSONID,
    T1.EMPLOYEEID,
    T2.FIRSTNAME,
    T2.LASTNAME,
    T1.TITLE
FROM
    employees AS T1
INNER JOIN
    persons AS T2 ON T1.PERSONID = T2.PERSONID;
```

### Folder BIRDS-benchmark/stackoverflow.4
#### Koncerty.dbpl
```SQL
CREATE VIEW koncerty (NAZWA_KLUBU, ADRES_KLUBU, NAZWA_ZESPOLU, ILOSC_CZLONKOW_ZESPOLU, DATA_WYSTEPU) AS
SELECT
    T1.NAZWA_KLUBU,
    T2.ADRES,       -- ADRES 对应 ADRES_KLUBU
    T1.NAZWA_ZESPOLU,
    T3.ILOSC_CZLONKOW, -- ILOSC_CZLONKOW 对应 ILOSC_CZLONKOW_ZESPOLU
    T1.DATA_WYSTEPU
FROM
    koncert AS T1
INNER JOIN
    klub AS T2 ON T1.NAZWA_KLUBU = T2.NAZWA
INNER JOIN
    zespol AS T3 ON T1.NAZWA_ZESPOLU = T3.NAZWA;
```

### Folder BIRDS-benchmark/stackoverflow
#### VW_COMPANY_PHONELIST.dbpl
```SQL
CREATE VIEW vw_company_phonelist ("source", id, number, lastname, fistname, phoneno) AS
SELECT
    'Customer' AS "source", -- 插入常量 'Customer'
    T1.customerid AS id,
    T1.customernumber AS number,
    T1.customerlastname AS lastname,
    T1.customerfirstname AS fistname,
    T1.phoneno
FROM
    customer AS T1

UNION ALL

SELECT
    'Supplier' AS "source", -- 插入常量 'Supplier'
    T2.supplierid AS id,
    T2.suppliernumber AS number,
    T2.supplierlastname AS lastname,
    T2.supplierfirstname AS fistname,
    T2.phoneno
FROM
    supplier AS T2

UNION ALL

SELECT
    'Vendor' AS "source", -- 插入常量 'Vendor'
    T3.vendorid AS id,
    T3.vendornumber AS number,
    T3.vendorlastname AS lastname,
    T3.vendorfirstname AS fistname,
    T3.phoneno
FROM
    vendor AS T3;
```

### Folder BIRDS-benchmark/textbook.1

<!-- #### activestudents.dbpl
```SQL
CREATE VIEW activestudents (NAME, LOGIN, CLUB, SINCE) AS
SELECT
    T1.SNAME,   -- SNAME 对应 NAME
    T1.LOGIN,
    T2.CNAME,   -- CNAME 对应 CLUB
    T2.JYEAR    -- JYEAR 对应 SINCE
FROM
    students AS T1
INNER JOIN
    clubs AS T2 ON T1.SNAME = T2.MNAME
WHERE
    T1.GPA > 3.0;
``` -->

#### goodstudents.dbpl
```SQL
CREATE VIEW goodstudents (SID, GPA) AS
SELECT T1.SID, T1.GPA
FROM students AS T1
WHERE T1.GPA > 3.0;
```

#### bstudents.dbpl
```SQL
CREATE VIEW bstudents (NAME, SID, COURSE) AS
SELECT
    T1.SNAME,
    T1.SID,
    T2.CID
FROM
    students AS T1
INNER JOIN
    enrolled AS T2 ON T1.SID = T2.SID
WHERE
    T2.GRADE = 'B';
```

### Folder BIRDS-benchmark/textbook.2
#### paramountmovies.dbpl
```SQL
CREATE VIEW paramountmovies (TITLE, YEAR) AS
SELECT T1.TITLE, T1.YEAR
FROM movies AS T1
WHERE T1.STUDIONAME = 'Paramount';
```

### Folder BIRDS-benchmark/textbook.3
#### newpc.dbpl
```SQL
CREATE VIEW newpc (MAKER, MODEL, SPEED, RAM, HD, PRICE) AS
SELECT
    T1.MAKER,
    T1.MODEL,
    T2.SPEED,
    T2.RAM,
    T2.HD,
    T2.PRICE
FROM
    product AS T1
INNER JOIN
    pc AS T2 ON T1.MODEL = T2.MODEL
WHERE
    T1.TYPE = 'pc';
```

### Folder BIRDS-benchmark/oracle-tutorial.2
#### vw_customers.*.dbpl
```SQL
CREATE VIEW vw_customers (NAME, ADDRESS, WEBSITE, CREDIT_LIMIT, FIRST_NAME, LAST_NAME, EMAIL, PHONE) AS
SELECT
    T1.NAME,
    T1.ADDRESS,
    T1.WEBSITE,
    T1.CREDIT_LIMIT,
    T2.FIRST_NAME,
    T2.LAST_NAME,
    T2.EMAIL,
    T2.PHONE
FROM
    customers AS T1
INNER JOIN
    contacts AS T2 ON T1.CUSTOMER_ID = T2.CUSTOMER_ID;
```

<!-- ### Folder BIRDS-benchmark/stackexchange.2
#### purchaseview.*.dbpl
```SQL
CREATE VIEW purchaseview (PURCHASE_ID, PRODUCT_NAME, WHEN_BOUGHT) AS
SELECT
    T1.PURCHASE_ID,
    T2.PRODUCT_NAME,
    T1.WHEN_BOUGHT
FROM
    purchase AS T1
INNER JOIN
    product AS T2 ON T1.PRODUCT_ID = T2.PRODUCT_ID;
``` -->

<!-- 这几个例子记得补上

stackexchange.2/purchaseview:把join的属性project掉了
stackoverflow.2/vehicleview:同上

textbook.1/activestudents:project掉的属性不能退化为常量

stackexchange.6/poi_view:同上

运行实验：load ini - fwd_diff_time/bwd_diff_time -->