CREATE DATABASE quanlybanhang;
USE quanlybanhang;

CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    address VARCHAR(255)
);

CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    category VARCHAR(50) NOT NULL
);

CREATE TABLE Employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    birthday date,
    position VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    revenue DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    employee_id INT,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

CREATE TABLE OrderDetails (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
-- 3.1 chèn thêm cột email
ALTER TABLE Customers ADD COLUMN email varchar(100) not null unique;
-- 3.2 xoá cột ngày sinh
alter table Employees drop column birthday;
-- 4 chèn giữ liệu
INSERT INTO Customers (customer_name, phone, email, address) 
	VALUES 
		('John Doe', '1234567890', 'john@example.com', '123 Main St'),
		('Jane Smith', '0987654321', 'jane@example.com', '456 Elm St');

INSERT INTO Products (product_name, price, quantity, category) 
	VALUES 
		('Laptop Dell XPS', 99.99, 50, 'Electronics'),
		('Desk Lamp', 29.99, 100, 'Furniture');

INSERT INTO Employees (employee_name, position, salary) 
	VALUES 
		('Alice', 'Manager', 70000),
		('Bob', 'Salesperson', 45000);

INSERT INTO Orders (customer_id, employee_id, total_amount)
	VALUES
		(1, 1, 99.99),
		(2, 2, 29.99);

INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price)
	VALUES
		(1, 1, 1, 99.99),
		(1, 2, 2, 29.99);

-- 5.1
select * from Customers;
-- 5.2
update products 
	set product_name = 'Laptop Dell XPS' ,
		price = 99.99
	where product_id = 1;
-- 5.3
select o.order_id, c.customer_name, e.employee_name, o.total_amount, o.order_date 
from Orders o
	join Customers c on c.customer_id = o.customer_id 
	join Employees e on e.employee_id = o.employee_id;
-- 6.1
select c.customer_id, c.customer_name, COUNT(o.order_id) 
from Customers c join Orders o on c.customer_id = o.customer_id 
group by c.customer_id, c.customer_name;
-- 6.2
select e.employee_id, e.employee_name, SUM(od.unit_price * od.quantity)
from Employees e 
	join Orders o on e.employee_id = o.employee_id 
	join OrderDetails od on o.order_id = od.order_id 
where year(o.order_date) = year(CURDATE()) 
group by e.employee_id;
-- 6.3
select p.product_id, p.product_name, COUNT(od.quantity) as total_orders
from OrderDetails od
	join Products p  on p.product_id = od.product_id 
    join Orders o on  od.order_id = o.order_id
where month(o.order_date) = month(CURDATE()) 
group by p.product_id 
having COUNT(od.quantity) > 100 
order by total_orders desc;
-- 7.1
select c.customer_id, c.customer_name 
from Customers c join Orders o on c.customer_id = o.customer_id 
where o.order_id is null;
-- 7.2
select p.product_id, p.product_name, p.price 
from Products p where p.price > (select avg(price) from Products);
-- 7.3
select c.customer_id, c.customer_name, SUM(od.unit_price * od.quantity) as total_spending 
from Customers c 
	join Orders o on c.customer_id = o.customer_id 
	join OrderDetails od on o.order_id = od.order_id 
group by c.customer_id 
order by total_spending desc;
-- 8.1
create view view_order_list as 
select o.order_id, c.customer_name, e.employee_name, o.total_amount, o.order_date 
from Orders o 
	join Customers c on o.customer_id = c.customer_id 
	join Employees e on o.employee_id = e.employee_id 
order by o.order_date desc;
-- 8.2
create view view_order_detail_product as 
select od.order_detail_id, p.product_name, od.quantity, od.unit_price 
from OrderDetails od join Products p on od.product_id = p.product_id 
order by od.quantity desc;
-- 9.1
DELIMITER //
create procedure proc_insert_employee(
    in p_employee_name varchar(100),
    in p_position varchar(50),
    in p_salary decimal(10, 2)
) 
begin
    insert into Employees (employee_name, position, salary) value (p_employee_name, p_position, p_salary);
    set @last_id = LAST_INSERT_ID();
end //
DELIMITER ;
-- 9.2
DELIMITER //
create procedure proc_get_orderdetails(
    in p_order_id int,
    out o_order_detail_ids varchar(255),
    out o_product_names varchar(255),
    out o_quantities varchar(255),
    out o_unit_prices varchar(255)
) 
begin
    set @o_order_detail_ids = '';
    set @o_product_names = '';
    set @o_quantities = '';
    set @o_unit_prices = '';

    select GROUP_CONCAT(od.order_detail_id), GROUP_CONCAT(p.product_name), GROUP_CONCAT(od.quantity), GROUP_CONCAT(od.unit_price) 
    into @o_order_detail_ids, @o_product_names, @o_quantities, @o_unit_prices
    from OrderDetails od join Products p on od.product_id = p.product_id where od.order_id = p_order_id;
end //
DELIMITER ;
-- 9.3
DELIMITER //
create procedure proc_cal_total_amount_by_order(
    in p_order_id int,
    out o_total_amount decimal(10, 2)
) 
begin
    select SUM(od.unit_price * od.quantity) into o_total_amount 
    from OrderDetails od where od.order_id = p_order_id;
end //
DELIMITER ;
-- 10
DELIMITER //
create trigger trigger_after_insert_order_details 
before insert on OrderDetails for each row
begin
    declare v_quantity_available int;

    select quantity into v_quantity_available from Products where product_id = new.product_id;
    if v_quantity_available < new.quantity then
        signal sqlstate '45000' set message_text = 'Số lượng sản phẩm trong kho không đủ';
        rollback;
    end if;
end //
DELIMITER ;
-- 11
DELIMITER //
create procedure proc_insert_order_details(
    in p_order_id int,
    in p_product_id int,
    in p_quantity int,
    in p_unit_price decimal(10,2)
) 
begin
    declare exit handler for sqlexception
    begin
        rollback;
    end;

    start transaction;

    if not exists (select 1 from Orders where order_id = p_order_id) then
        signal sqlstate '45001' set message_text = 'Không tồn tại mã hóa đơn';
    else
        insert into OrderDetails(order_id, product_id, quantity, unit_price)
        values(p_order_id, p_product_id, p_quantity, p_unit_price);

        update Orders 
        set total_amount = total_amount + (p_quantity * p_unit_price) 
        where order_id = p_order_id;

        commit;
    end if;
end //
DELIMITER ;




