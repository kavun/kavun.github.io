---
comments: true
date: "2023-09-08"
layout: "post"
slug: "updating-rows-with-window-functions-in-postgres"
title: "Updating Rows with Window Functions in Postgres"
summary: "How to use window functions to update more than 1 row per grouping."
tags: ["SQL", "Postgres"]
---

## Limits of `DISTINCT ON`

I had a problem recently where I needed to modify a script that would update 1 row per distinct values of a column to instead update 2 rows per grouping. The data in the table looked something like this.

| Id | TypeA | TypeB | Flag |
| --- | --- | --- | --- |
| 1 | A1 | B1 | |
| 2 | A1 | B1 | |
| 3 | A2 | B1 | |
| 4 | A2 | B1 | |
| 5 | A3 | B1 | |
| 6 | A3 | B1 | |
| 7 | A1 | B2 | |
| 8 | A1 | B2 | |
| 9 | A2 | B2 | |
| 10 | A2 | B2 | |
| 11 | A3 | B2 | |
| 12 | A3 | B2 | |

This meant that the `DISTINCT ON` in the following SQL was too limiting, and I would have to do something more creative.

```sql
UPDATE "Table"
SET "Flag" = '✔️'
WHERE "Id" IN (
    SELECT DISTINCT ON (s."TypeB") s."Id"
    FROM "Table" s
    WHERE s."TypeA" = 'A1'
);

UPDATE "Table"
SET "Flag" = '✔️'
WHERE "Id" IN (
    SELECT DISTINCT ON (s."TypeB") s."Id"
    FROM "Table" s
    WHERE s."TypeA" = 'A2'
);
```

This would update the table to look like this

| Id | TypeA | TypeB | Flag |
| --- | --- | --- | --- |
| 1 | A1 | B1 | ✔️ |
| 2 | A1 | B1 | |
| 3 | A2 | B1 | ✔️ |
| 4 | A2 | B1 | |
| 5 | A3 | B1 | |
| 6 | A3 | B1 | |
| 7 | A1 | B2 | ✔️ |
| 8 | A1 | B2 | |
| 9 | A2 | B2 | ✔️ |
| 10 | A2 | B2 | |
| 11 | A3 | B2 | |
| 12 | A3 | B2 | |

But what I really wanted was to update 2 rows per `TypeB` grouping, so that the table would look like this. Notice we don't want to touch the `A3` rows, nor any other `TypeA` values other than `A1` and `A2`.

| Id | TypeA | TypeB | Flag |
| --- | --- | --- | --- |
| 1 | A1 | B1 | ✔️ |
| 2 | A1 | B1 | ✔️ |
| 3 | A2 | B1 | ✔️ |
| 4 | A2 | B1 | ✔️ |
| 5 | A3 | B1 | |
| 6 | A3 | B1 | |
| 7 | A1 | B2 | ✔️ |
| 8 | A1 | B2 | ✔️ |
| 9 | A2 | B2 | ✔️ |
| 10 | A2 | B2 | ✔️ |
| 11 | A3 | B2 | |
| 12 | A3 | B2 | |

## Using Window Functions
To update more than 1 row per `TypeB` grouping, we'll need both of these Postgres functions
- `ROW_NUMBER()` (see [Window Functions Docs](https://www.postgresql.org/docs/current/functions-window.html) docs)
- `PARTIION BY` (see [Window Functions Tutorial](https://www.postgresql.org/docs/current/tutorial-window.html) tutorial)

To start we can number each row by `TypeB` like this

```sql
SELECT ROW_NUMBER() OVER (PARTITION BY "TypeB"), "TypeB"
FROM "Table"
```

This returns something like

| ROW_NUMBER | TypeB |
| --- | --- |
| 1 | B1 |
| 2 | B1 |
| ... | B1 |
| 1 | B2 |
| 2 | B2 |
| ... | B2 |

Knowing that `PARTITION BY` creates subsets of each group, and that `ROW_NUMBER()` can index each row in each group starting with `1`, then we can do this in our update statement

```sql
UPDATE "Table"
SET "Flag" = '✔️'
WHERE "Id" IN (
    SELECT t."Id"
    FROM (
        SELECT "Id", ROW_NUMBER() OVER (PARTITION BY "TypeB") AS row_number
        FROM "Table"
        WHERE "TypeA" = 'A1'
    ) t
    WHERE t.row_number < 3
);

UPDATE "Table"
SET "Flag" = '✔️'
WHERE "Id" IN (
    SELECT t."Id"
    FROM (
        SELECT "Id", ROW_NUMBER() OVER (PARTITION BY "TypeB") AS row_number
        FROM "Table"
        WHERE "TypeA" = 'A2'
    ) t
    WHERE t.row_number < 3
);
```

This does it!
## Reducing Repetition
How can I combine the two `UPDATE` statements for both `A1` and `A2`? Postgres does have a `FOR` loop that looks like this:

```sql
FOR i IN 1..10 LOOP
	-- ...
END LOOP;
```

The `FOR` loop does work, but using it is not as simple as you would hope. Postgres can run the `FOR` inside of a `DO` block that runs code for a given language. In the following snippet, the language is `plpgsql` which is Postgres' own procedural language. The `DECLARE` block is where we can declare variables, and the `BEGIN` block is where we can run our `FOR` loop.

- [`DECLARE`](https://www.postgresql.org/docs/current/plpgsql-declarations.html)
- [`$$` (dollar quoted strings)](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-DOLLAR-QUOTING)
- [`FOR` (integer variant)](https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-INTEGER-FOR)
- [`DO`](https://www.postgresql.org/docs/current/sql-do.html)

```sql
DO $$
DECLARE a_idx integer;
BEGIN 
    FOR a_idx IN 1..2 LOOP 
        UPDATE "Table"
        SET "Flag" = '✔️'
        WHERE "Id" IN (
            SELECT s."Id"
            FROM (
                SELECT "Id", ROW_NUMBER() OVER (PARTITION BY "TypeB") AS row_number
                FROM "Table"
                WHERE "TypeA" = 'A' || a_idx
            ) s
            WHERE s.row_number < 6
        );
    END LOOP;
END $$;
```

This is much better than having to write out the `UPDATE` statement twice, and it's also more flexible. If we wanted to update more rows per grouping, we could just change the `WHERE` clause to `WHERE s.row_number < 6` and so on. And if we wanted to update more `TypeA` values, we could just change the `FOR` loop to `FOR a_idx IN 1..3 LOOP` and so on. If we wanted to loop over a list of strings instead of integers we could do that too, though, counterintuitively it does require a bit more verbosity.

```sql
DO $$
DECLARE
    a_arr text[] := ARRAY['A1', 'A2'];
    a text;
BEGIN
    FOREACH a IN ARRAY a_arr LOOP
        UPDATE "Table"
        SET "Flag" = '✔️'
        WHERE "Id" IN (
            SELECT s."Id"
            FROM (
                SELECT "Id", ROW_NUMBER() OVER (PARTITION BY "TypeB") AS row_number
                FROM "Table"
                WHERE "TypeA" = a
            ) s
            WHERE s.row_number < 6
        );
    END LOOP;
END $$;
```

## Conclusion

- `DISTINCT ON` can be used to select 1 row per distinct values of a column
- `ROW_NUMBER()` is a window function that can index rows in a given group
- `PARTITION BY` can be used to create groups of rows
- `FOR` loops can be used to run the same code multiple times
- `DO $$` can be used to run code in a given language
- `DECLARE` blocks can be used to declare variables
- `FOR ... IN ... LOOP` can be used to iterate over a range of values
- `FOREACH ... IN ARRAY ... LOOP` can be used to iterate over an array of values
- `||` can be used to concatenate strings
- `text[] := ARRAY[...]` can be used to declare and create an array of strings