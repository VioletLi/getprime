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

```