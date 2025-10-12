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