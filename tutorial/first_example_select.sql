
SELECT 
   o.order_id, 
   s.name AS staff_name, 
   s.location AS staff_loc, 
   c.cust_name, 
   c.phone AS cust_phone, 
   p.product_name, 
   p.price,
   l.qty
 FROM bt_tutorial.t_order_line l
 JOIN bt_tutorial.t_order o ON o.order_id = l.order_id
 JOIN bt_tutorial.product p ON p.product_id = l.product_id
 JOIN bt_tutorial.staff s ON s.staff_id = o.staff_id
 JOIN bt_tutorial.cust c ON c.cust_id = o.cust_id;
   

UPDATE bt_tutorial.staff SET location = 'newlocation' WHERE staff_id = 1;	  
UPDATE bt_tutorial.cust SET phone = '+6281111111111' WHERE cust_id = 1;  
UPDATE bt_tutorial.product SET price = 300 WHERE product_id = 1; 

---select the same order

SELECT o.order_id,                                       
s.name AS staff_name,                            
s.location AS staff_loc,                         
c.cust_name,                                     
c.phone AS cust_phone,                           
p.product_name,                                  
p.price,                                         
l.qty                                            
    FROM bt_tutorial.t_order_line l                          
    JOIN bt_tutorial.t_order o ON o.order_id = l.order_id    
    JOIN bt_tutorial.product p ON p.product_id = l.product_id
    JOIN bt_tutorial.staff s ON s.staff_id = o.staff_id      
    JOIN bt_tutorial.cust c ON c.cust_id = o.cust_id;    
    
 ---incorrect result
 
     
