### Folder case-study
#### ced.dbpl
```SQL
CREATE VIEW ced AS
SELECT ed.EMP_NAME, ed.DEPT_NAME FROM ed
WHERE NOT EXISTS (
    SELECT 1 FROM eed
    WHERE eed.EMP_NAME = ed.EMP_NAME AND eed.DEPT_NAME = ed.DEPT_NAME
);
```

#### all_items.dbpl
```SQL
CREATE VIEW all_items AS
SELECT ITEM FROM on_sale
UNION
SELECT ITEM FROM in_stock;
```

#### courses.dbpl
```SQL
CREATE VIEW courses AS
SELECT DISTINCT CNAME
FROM enrollment;
```

#### book_info.dbpl
```SQL
CREATE VIEW book_info AS
SELECT A.BOOK, A.AUTHOR, COALESCE(V.VER, 'NULL') FROM author AS A
LEFT OUTER JOIN version AS V ON A.BOOK = V.BOOK;
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
#### employees.dbpl
```SQL
CREATE VIEW employees AS
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
CREATE VIEW researchers AS
SELECT T1.EMP_NAME
FROM residents AS T1
INNER JOIN ced AS T2 ON T1.EMP_NAME = T2.EMP_NAME
WHERE T2.DEPT_NAME = 'Research';
```

#### residents.dbpl
```SQL
CREATE VIEW residents AS
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
CREATE VIEW retired AS
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
CREATE VIEW officeinfo AS
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