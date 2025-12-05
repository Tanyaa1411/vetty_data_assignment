SQL Test – My Solution

This repository contains my attempt at the SQL test that was shared with me.
I have tried to keep the queries simple, readable, and well-commented so the reviewer can easily understand how I approached each question.

I am still learning SQL, but I enjoy working with data, and this test helped me practice concepts like window functions, date handling, filtering, and ranking.

Files in This Repository
1. vetty_assignment.sql

This file contains all the SQL queries for the eight questions.
I added short comments inside the code to explain why I wrote each step and what the logic behind the query is.


2. screenshots/

This folder contains screenshots that show the output after running the queries on my system.

My Approach

Before writing queries, I understood the tables properly:

The transactions table includes buyer information, timestamps, store details, and refund data.

The items table includes item names and their respective categories.

Most questions required identifying first or second purchases, calculating time differences, or grouping data.
For these, I mainly used window functions like ROW_NUMBER(), and for time calculations, I used functions like DATE_TRUNC and EXTRACT.

For the “refund within 72 hours” condition, I calculated the time gap in hours and compared it against 72.

For the October 2020 question, I noticed that the dataset does not contain any transactions from that month, so the answer naturally comes out as zero.

What I Learned

How to use window functions to find first and second transactions

How to calculate time intervals using timestamps

The importance of breaking questions into smaller parts

Why readable SQL formatting matters

How to validate assumptions based on the dataset.

Final Note

I tried to clearly show my thought process and keep the queries as understandable as possible. If any part of the solution needs clarification, I would be happy to explain it further.
