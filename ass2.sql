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



--Section 4: Advanced SQL Concepts
--Inline Table-Valued Function (iTVF)
--1. Create an inline table-valued function that returns the total sales amount for each book and use it in a query to display the results.

Go
create Function dbo.GetTotalSalesAmtEachBook(@title nvarchar(50))
returns table
As
Return(
select books.book_id, title, total_amount
from authors
    join books on authors.author_id=books.author_id
    join sales on books.book_id=sales.book_id
group by books.book_id,title,total_amount
having title=@title
)
Go

select *
from dbo.GetTotalSalesAmtEachBook('1984');

--Multi-Statement Table-Valued Function (MTVF)

--2. Create a multi-statement table-valued function that returns the total quantity sold for each genre and use it in a query to display the results.

GO
alter Function dbo.GetBookCountByGenre()
Returns @CountBooks Table(genre nvarchar(30) ,
    CountOfBooks int)
As
Begin
    Insert Into @CountBooks
    select b.genre , sum(s.quantity) as CountOfBooks
    from sales s
        join books b on s.book_id=b.book_id
    group by genre
    Return;
End
GO

select *
from dbo.GetBookCountByGenre();

--Scalar Function
--3. Create a scalar function that returns the average price of books for a given author and use it in a query to display the average price for 'Jane Austen'.

go
alter function dbo.AvgPriceOfBooksPerAuthor(@authorname nvarchar(50))
returns int
as
Begin
    DECLARE @res int
    select @res=avg(price)
    from books
    where books.author_id=(select author_id
    from authors
    where [name]=@authorname)
    group by author_id
    return @res
end
go

select dbo.AvgPriceOfBooksPerAuthor('George Orwell')

--Stored Procedure for Books with Minimum Sales
--4. Create a stored procedure that returns books with total sales above a specified amount and use it to display books with total sales above $40.

go
create PROCEDURE TopTotalSales
    @MinAmount int
AS
BEGIN
    Select sales.book_id, title , total_amount
    from sales
        join books on sales.book_id=books.book_id
    where total_amount > @MinAmount
END
go

exec TopTotalSales @MinAmount=40

--5.Indexing for Performance Improvement
--Create an index on the sales table to improve query performance for queries filtering by book_id.
CREATE INDEX  IX_BOOK_ID
    ON sales (book_id);
--Export Data as XML
--6. Write a query to export the authors and their books as XML.
select [name], title
from authors
    join books on authors.author_id=books.book_id
for xml path('Author'),root('Authors')
    --Export Data as JSON
    --7.Write a query to export the authors and their books as JSON.
    select [name], title
    from authors
        join books on authors.author_id=books.book_id
    for json path,root('Authors')

--Scalar Function for Total Sales in a Year
--8. Create a scalar function that returns the total sales amount in a given year and use it in a query to display the total sales for 2024.
go
        create function  dbo.TotalSalesInYear(@year int)
returns int
as
begin
            declare @totalsales decimal(10,2)
            select @totalsales=sum(total_amount)
            from sales
            where datepart(year,sale_date)=@year
            return @totalsales
        end
go

        select dbo.TotalSalesInYear(2024)

--9.Stored Procedure for Genre Sales Report
--Create a stored procedure that returns a sales report for a specific genre, including total sales and average sales, and use it to display the report for 'Fiction'.
go
        alter procedure SalesReport
            @genre nvarchar(30)
        as
begin
            declare @totalsales int
            declare @avgtotalsales int
            select @totalsales =sum(total_amount), @avgtotalsales=avg(total_amount)
            from books
                join sales on books.book_id=sales.book_id
            where genre=@genre

            select @genre , @totalsales as TotalSales , @avgtotalsales as AvgTotalSales

        end
go

        exec SalesReport @genre='Fiction'

        --Ranking Books by Average Rating (assuming a ratings table)
        --10.Write a query to rank books by their average rating and display the top 3 books. Assume a ratings table with book_id and rating columns.
        CREATE TABLE ratings
        (
            rating_id INT PRIMARY KEY,
            book_id INT NOT NULL,
            rating DECIMAL(3, 1) NOT NULL,
            CONSTRAINT FK_ratings_books FOREIGN KEY (book_id) REFERENCES books(book_id)
        );

        INSERT INTO ratings
            (rating_id, book_id, rating)
        VALUES
            (1, 1, 4.5),
            (2, 2, 4.0),
            (3, 3, 4.8),
            (4, 4, 3.7),
            (5, 5, 4.2);

        with
            CTE_TopRatedBooks
            as
            (
                select books.book_id, title, rating, DENSE_RANK() OVER(ORDER BY rating desc) as TopRatings
                from books
                    join ratings on books.book_id=ratings.book_id
            )

        select *
        from CTE_TopRatedBooks
        where TopRatings<=3

        --Section 5: Questions for Running Total and Running Average with OVER Clause
        --1. Running Total of Sales Amount by Book
        --Create a view that displays each sale for a book along with the running total of the sales amount using the OVER clause.
        select * ,
            sum(total_amount) over(order by total_amount) as running_total
        from sales

        --Running Total of Sales Quantity by Author
        --2. Create a view that displays each sale for an author along with the running total of the sales quantity using the OVER clause.
        create view RunningTotalOfSalesQuant
        as
            select authors.author_id, [title], sale_id , quantity, sum(quantity) over(order by quantity) as CountOfQuantity
            from authors
                join books on authors.author_id=books.author_id
                join sales on books.book_id=sales.book_id

        select *
        from RunningTotalOfSalesQuant

        --Running Total and Running Average of Sales Amount by Genre
        --3. Create a view that displays each sale for a genre along with both the running total and the running average of the sales amount using the OVER clause.
        create view RunningTotalByGenre
        as
            select books.book_id , title , genre , sale_id , total_amount , sum(total_amount) over (order by total_amount) as Running_total 
, avg(total_amount) over (order by total_amount) as Running_avg
            from books
                join sales on books.book_id=sales.sale_id

        select *
        from RunningTotalByGenre

--Section 6: Triggers
--Trigger to Update Total Sales After Insert on Sales Table
--Create a trigger that updates the total sales for a book in the books table after a new record is inserted into the sales table.
go
        create trigger trg_UpdateSales
on sales
after insert
as 
begin

            update sales
set
        end
go

        --Trigger to Log Deletions from the Sales Table
        --2. Create a trigger that logs deletions from the sales table into a sales_log table with the sale_id, book_id, and the delete_date.

        CREATE TABLE sales_log
        (
            log_id INT PRIMARY KEY identity(201,1),
            sale_id INT NOT NULL,
            book_id INT NOT NULL,
            delete_date DATE NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales(sale_id),
            FOREIGN KEY (book_id) REFERENCES books(book_id)
        );


go
        create Trigger trg_SalesLog
on sales -- SQL listens to this table
After delete -- Before/after (I,U,D) -- Action
As
Begin

            Insert into sales_log
            select deleted.sale_id, deleted.book_id, deleted.sale_date
            FROM deleted
        End
go

        select *
        from sales_log


        delete from sales
where sale_id=3

        delete from books
where title='Adventures of Huckleberry Finn'

        delete from authors 
where author_id=3

        insert into authors

--Trigger to Prevent Negative Quantity on Update
--3. Create a trigger that prevents updates to the sales table if the new quantity is negative.
go
        create trigger trg_PreventsUpdate
ON sales
after UPDATE
as
begin
            if exists( select inserted.quantity
            from inserted
            where inserted.quantity<0)
  throw 60000, 'Quantity value is negative!!!', 1;
        end
go

        UPDATE sales
SET quantity = -1
WHERE sale_id = 1;

        select *
        from authors
        select *
        from books
        select *
        from sales

        --Section 3: Stored Procedures with Transactions and Validations
        --task 1
        --Add New Book and Update Author's Average Price
        --Create a stored procedure that adds a new book and updates the average price of books for the author. Ensure the price is positive, use transactions to ensure data integrity, and return the new average price.


        SELECT *
        FROM authors
        SELECT *
        FROM books
GO
        create Procedure AddBookAndUpdateAvgPrice(
            @book_id Int,
            @title varchar(30),
            @author_id Int,
            @genre varchar(30),
            @price Int
        )
        AS
        Begin

            if @price<=0  
throw 60000, 'Price should be positive value', 1;
            DECLARE @currentAvg DECIMAL(10,2);
            DECLARE @AvgPrice DECIMAL(10,2);


            Begin Transaction
            Insert Into books
                (book_id,title,author_id,genre,price)
            values
                (@book_id, @title , @author_id , @genre, @price )

            select avg(price)
            from books
            where author_id=@author_id;


            commit


        End
        GO
        EXEC AddBookAndUpdateAvgPrice @book_id=9, @title ='book',@author_id=2,@genre ='fantasy',@price =15
