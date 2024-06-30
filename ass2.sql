CREATE TABLE books
(
    book_id INT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    genre VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE authors
(
    author_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    birth_year INT NOT NULL
);

CREATE TABLE sales
(
    sale_id INT PRIMARY KEY,
    book_id INT NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

INSERT INTO authors
    (author_id, name, country, birth_year)
VALUES
    (1, 'George Orwell', 'UK', 1903),
    (2, 'J.K. Rowling', 'UK', 1965),
    (3, 'Mark Twain', 'USA', 1835),
    (4, 'Jane Austen', 'UK', 1775),
    (5, 'Ernest Hemingway', 'USA', 1899);

INSERT INTO books
    (book_id, title, author_id, genre, price)
VALUES
    (1, '1984', 1, 'Dystopian', 15.99),
    (2, 'Harry Potter and the Philosophers Stone', 2, 'Fantasy', 20.00),
    (3, 'Adventures of Huckleberry Finn', 3, 'Fiction', 10.00),
    (4, 'Pride and Prejudice', 4, 'Romance', 12.00),
    (5, 'The Old Man and the Sea', 5, 'Fiction', 8.99);

INSERT INTO sales
    (sale_id, book_id, sale_date, quantity, total_amount)
VALUES
    (1, 1, '2024-01-15', 3, 47.97),
    (2, 2, '2024-02-10', 2, 40.00),
    (3, 3, '2024-03-05', 5, 50.00),
    (4, 4, '2024-04-20', 1, 12.00),
    (5, 5, '2024-05-25', 4, 35.96);

SELECT *
FROM authors
SELECT *
FROM books
SELECT *
FROM sales

--Task 1
--Write a query to display authors who have written books in multiple genres and group the results by author name.

SELECT a."name" AS author_name, COUNT(DISTINCT b.genre) AS genre_count
FROM authors a
    JOIN books b ON a.author_id = b.author_id
GROUP BY a."name"
HAVING COUNT(DISTINCT b.genre) > 1;



--Task 2
--Write a query to find the books that have the highest sale total for each genre and group the results by genre.

with
    title_cte
    as
    (
        SELECT title , genre,
            DENSE_RANK() OVER (PARTITION BY genre ORDER BY sum(price) desc) as rank
        from books
        group by genre,title
    )
SELECT *
FROM title_cte
where rank=1


--Task 3
--Write a query to find the average price of books for each author and group the results by author name, only including authors whose average book price is higher than the overall average book price.

with
    cte_author
    as
    (
        SELECT authors.author_id, avg(price) as avg_price
        FROM books
            JOIN authors
            ON books.author_id=authors.author_id
        group by authors.author_id
        having avg(price)>(select avg(price)
        from books)
    )
SELECT authors."name"
FROM cte_author
    JOIN authors
    ON cte_author.author_id=authors.author_id


--Task 4
--Write a query to find authors who have sold more books than the average number of books sold per author and group the results by country.

SELECT "name", country, count(sales.book_id) as books_sold
FROM authors
    left JOIN books ON authors.author_id=books.author_id
    JOIN sales ON books.book_id=sales.book_id
GROUP BY country,"name"
having count(sales.sale_id) >(


--Task 5
--Write a query to find the top 2 highest-priced books and the total quantity sold for each, grouped by book title.

With
    cte_top2
    as
    (
        SELECT top 2
            price, title, book_id
        from books
        group by title,price,book_id
        order by price desc
    )
SELECT title, quantity
from cte_top2
    JOIN sales ON cte_top2.book_id=sales.book_id

--Task 6
--Write a query to display authors whose birth year is earlier than the average birth year of authors from their country and rank them within their country.

SELECT country, "name",
    rank() over (partition by country order by birth_year)
FROM authors a
where birth_year < All(SELECT avg(birth_year)
from authors
where country=a.country)



--Task 7
--Write a query to find the authors who have written books in both 'Fiction' and 'Romance' genres and group the results by author name.


    SELECT books.author_id, authors."name"
    FROM books
        JOIN authors ON books.author_id=authors.author_id
    where genre='Fiction'
    group by books.author_id,authors."name"
INTERSECT
    SELECT books.author_id, authors."name"
    FROM books
        JOIN authors ON books.author_id=authors.author_id
    where genre='Romance'
    group by books.author_id,authors."name"


--Task 8
--Write a query to find authors who have never written a book in the 'Fantasy' genre and group the results by country.


SELECT authors."name" , country, books.author_id
from authors
    JOIN books ON authors.author_id=books.author_id
where genre!='Fantasy'
group by country, authors."name",books.author_id


--Task 9
--Write a query to find the books that have been sold in both January and February 2024 and group the results by book title.

    SELECT title
    FROM sales
        JOIN books ON sales.book_id=books.book_id
    where DATEPART(MONTH,sales.sale_date)=1
UNION
    SELECT title
    FROM sales
        JOIN books ON sales.book_id=books.book_id
    where DATEPART(MONTH,sales.sale_date)=2


--Task 10
--Write a query to display the authors whose average book price is higher than every book price in the 'Fiction' genre and group the results by author name.


SELECT books.author_id, "name"
from books
    JOIN authors ON books.author_id=authors.author_id
group by books.author_id,"name"
having avg(price) > All(SELECT price
from books
where genre='Fiction')


--Section 2: Questions

--Task 1: Stored Procedure for Total Sales by Author
--Create a stored procedure to get the total sales amount for a specific author and write a query to call the procedure for 'J.K. Rowling'.

GO
CREATE Procedure sp_TotalAmntforAuthor
    @author_name nvarchar(30)
As
Begin
    Declare @author_id_val Int

    SELECT books.author_id, Sum(total_amount) as total
    from sales s
        JOIN books ON s.book_id=books.book_id
        JOIN authors ON books.author_id=authors.author_id
    where "name"=@author_name
    group by books.author_id
End
GO
EXEC sp_TotalAmntforAuthor @author_name='J.K. Rowling'


--Task 2: Function to Calculate Total Quantity Sold for a Book
--Create a function to calculate the total quantity sold for a given book title and write a query to use this function for '1984'.


go
CREATE FUNCTION dbo.totalquant (@book_title nvarchar(max))
	returns int
AS
Begin
    declare @total_quant Int
    SELECT @total_quant=sum(quantity)
    FROM sales
        JOIN books On sales.book_id=books.book_id
    where title=@book_title
    return @total_quant
end
go
SELECT dbo.totalquant ('1984')

--Task 3: View for Best-Selling Books
--Create a view to show the best-selling books (those with total sales amount above $30) and write a query to select from this view.
GO
CREATE VIEW vw_bestsellingbooks
as
    (
    SELECT books.title
    from sales
        JOIN books ON sales.book_id=books.book_id
    where sales.total_amount>30.0
)
GO
SELECT *
FROM vw_bestsellingbooks


--Task 4: Stored Procedure for Average Book Price by Author
--Create a stored procedure to get the average price of books for a specific author and write a query to call the procedure for 'Mark Twain'.

GO
CREATE PROCEDURE sp_avgpriceofbook
    @author_name nvarchar(max)
AS
Begin
    (
SELECT avg(price) as avg_price
    FROM books
        JOIN authors ON books.author_id=authors.author_id
    where "name"=@author_name
)
End
GO
EXEC sp_avgpriceofbook @author_name='Mark Twain'

--Task 5: Function to Calculate Total Sales in a Month
--Create a function to calculate the total sales amount in a given month and year, and write a query to use this function for January 2024.
GO
CREATE FUNCTION dbo.totalsalesamnt(@month Int,@year Int)
returns decimal(10,2)
AS
BEGIN
    declare @total_amnt decimal(10,2)
    SELECT @total_amnt=total_amount
    FROM sales
    where month(sale_date)=@month and year(sale_date)=@year
    return @total_amnt
end
GO
SELECT dbo.totalsalesamnt(1,2024)


--Task 6: View for Authors with Multiple Genres
--Create a view to show authors who have written books in multiple genres and write a query to select from this view.

GO
CREATE VIEW vw_booksofmultiplegenres
as
    (
    SELECT "name", books.author_id
    from books
        JOIN authors ON books.author_id=authors.author_id
    group by books.author_id,"name"
    having count(distinct genre)>1
)
GO
SELECT *
FROM vw_booksofmultiplegenres

--Task 7: Ranking Authors by Total Sales
--Write a query to rank authors by their total sales amount and display the top 3 authors.

SELECT TOP (3)
    "name" ,
    rank() over (order by total_amount desc) as ranking
from sales
    JOIN books ON sales.book_id=books.book_id
    JOIN authors ON books.author_id=authors.author_id


--Task 8: Stored Procedure for Top-Selling Book in a Genre
--Create a stored procedure to get the top-selling book in a specific genre and write a query to call the procedure for 'Fantasy'.

GO
CREATE PROCEDURE sp_topsellingbook
    @genre nvarchar(30)
AS
BEGIN
    (
SELECT top(1)
        title,
        rank() over (partition by genre order by total_amount desc) as ranking
    from books
        JOIN sales ON books.book_id=sales.book_id
    where genre=@genre
)
END
GO
EXEC sp_topsellingbook @genre='Fantasy'

--Task 9: Function to Calculate Average Sales Per Genre
--Create a function to calculate the average sales amount for books in a given genre and write a query to use this function for 'Romance'.

GO
CREATE FUNCTION dbo.avgsalesamnt(@genre nvarchar(30))
returns decimal(10,2)
AS
BEGIN
    DECLARE @avg_amnt decimal(10,2)
    SELECT @avg_amnt=avg(total_amount)
    from sales
        JOIN books ON sales.book_id=books.book_id
    where genre=@genre
    group by books.genre
    return @avg_amnt
end
GO
SELECT dbo.avgsalesamnt('Romance')
