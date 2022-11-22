-- create tables queries

CREATE TABLE Users (
userId  int NOT NULL  PRIMARY KEY,
State varchar(10),
createdDate DATETIME ,
lastLogin DATETIME  ,
activeflag  int NOT NULL, -- "active = 1 & Inactive = 0" ,
role  varchar(10) -- consumer,
);

select * from Users

-- ************************************

CREATE TABLE BrandData (
brandId int NOT NULL  PRIMARY KEY,
barcode varchar(255),
brandCode varchar(255),
category varchar(255),
categoryCode varchar(255),
cpg varchar(255),
topBrand  int NOT NULL, -- "active = 1 - yes top brand & Inactive = 0 -“ not a top brand , 
name varchar (255)
);

select * from BrandData

-- ************************************

CREATE TABLE ReceiptData (
receiptId  int NOT NULL PRIMARY KEY,
bonusPointsEarned int,
bonusPointsEarnedReason varchar (255),
createDate DATETIME,
dateScanned DATETIME,
finishedDate DATETIME,
modifyDate DATETIME, 
pointsAwardedDate DATETIME,
pointsEarned int,
purchaseDate DATETIME,
purchasedItemCount int,
rewardsReceiptStatus varchar(255),
totalSpent int,
userId int not null,
FOREIGN KEY (userId) REFERENCES Users(userId)
);


select * from ReceiptData

-- ************************************

CREATE TABLE OrderItemsData (
userId  int NOT NULL,
receiptId  int NOT NULL,
barcode int not null,
brandId int not null,
description varchar (255),
finalPrice decimal (7,2),
itemPrice decimal (7,2),
needsFetchReview int NOT NULL, -- "active = t or f , 
partnerItemId int, 
pointsNotAwardedReason varchar (255),
pointsPayerId varchar (255),
preventTargetGapPoints  int NOT NULL, -- "active = t or f, 
quantityPurchased int, 
rewardsGroup varchar (255),
rewardsProductPartnerId varchar(255),
userFlaggedBarcode  varchar(255),
userFlaggedDescription varchar (255),
userFlaggedNewItem int NOT NULL, -- "active = 1 - yes top brand & Inactive = 0 -“ not a top brand , 
userFlaggedPrice decimal (7,2), 
userFlaggedQuantity int,
CONSTRAINT receipt_items_user_ID PRIMARY KEY (userId,receiptId, barcode),
FOREIGN KEY (receiptId) REFERENCES ReceiptData(receiptId),
FOREIGN KEY (brandId) REFERENCES BrandData(brandId)
);


select * from OrderItemsData

-- ************************************

-- insert data from json files in this format, I didnt insert all the rows, I just mentioned a way how we can insert json into SQL tables
-- ref - https://database.guide/how-to-insert-json-into-a-table-in-sql-server/

DECLARE @json NVARCHAR(4000) = N'{ 
    "person" : {
            "users" : [
                        {"_id":{"$oid":"5ff1e194b6a9d73a3a9f1052"},"active":true,"createdDate":{"$date":1609687444800},"lastLogin":{"$date":1609687537858},"role":"consumer","signUpSource":"Email","state":"WI"},
                        {"_id":{"$oid":"5ff1e194b6a9d73a3a9f1052"},"active":true,"createdDate":{"$date":1609687444800},"lastLogin":{"$date":1609687537858},"role":"consumer","signUpSource":"Email","state":"WI"}
        ],
            "fetch-staff" : [
                    {"_id":{"$oid":"5ff1e1eacfcf6c399c274ae6"},"active":true,"createdDate":{"$date":1609687530554},"lastLogin":{"$date":1609687530597},"role":"fetch-staff","signUpSource":"Email","state":"WI"},
                    {"_id":{"$oid":"5ff1e194b6a9d73a3a9f1052"},"active":true,"createdDate":{"$date":1609687444800},"lastLogin":{"$date":1609687537858},"role":"etch-staff","signUpSource":"Email","state":"WI"}   
        ]
    }
}';

SELECT * INTO Users
FROM OPENJSON(@json, '$.person.users')
WITH  (
        userId int '$._id',  
        State   varchar(100) '$.state', 
        createdDate Datetime '$.createdDate.$date', 
        lastLogin Datetime '$.lastLogin.$date',
        activeFlag int '1',
        role varchar(10) '$.role'
    AS JSON   
    );

-- ************************************

-- What are the top 5 brands by receipts scanned for most recent month?

-- most recent month, for example, If we are in November right now, so October 2022 data

Select top 5 BrandName as TopBrands from 
(
select b.name as BrandName, count(distinct r.receiptId) as ReceiptCount from 
BrandData b
join OrderItemsData o on b.brandId = o.brandId
join ReceiptData r on r.receiptId = o.receiptId
where datediff(month, r.dateScanned, getdate()) = 1
group by b.name
) as Group1
from Group1
order by ReceiptCount desc

-- How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?

-- most recent month, for example, If we are in November right now, so October 2022 data
Select top 5 BrandName as TopBrands from 
(
select b.name as BrandName, count(distinct r.receiptId) as ReceiptCount from 
BrandData b
join OrderItemsData o on b.brandId = o.brandId
join ReceiptData r on r.receiptId = o.receiptId
where datediff(month, r.dateScanned, getdate()) = 1
group by b.name
) as Group1
from Group1
order by ReceiptCount desc

-- previous month

-- previous month, for example, If we are in November right now, so Septemeber 2022 data

Select top 5 BrandName as TopBrands from 
(
select b.name as BrandName, count(distinct r.receiptId) as ReceiptCount from 
BrandData b
join OrderItemsData o on b.brandId = o.brandId
join ReceiptData r on r.receiptId = o.receiptId
where datediff(month, r.dateScanned, getdate()) = 2
group by b.name
) as Group1
from Group1
order by ReceiptCount desc

-- thus by running above two queries, we can compare the top brands for October and September.

-- When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

select r.rewardsReceiptStatus , avg(totalSpent) from 
ReceiptData r
group by r.rewardsReceiptStatus

-- thus we can compare the average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, to check which is greater


-- When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

select r.rewardsReceiptStatus , sum(purchasedItemCount) from 
ReceiptData r
group by r.rewardsReceiptStatus


-- Which brand has the most spend among users who were created within the past 6 months?
-- past 6 months refers to may - october if considering from Nov, 2022
Select top 1 BrandName as TopBrand from 
(
select b.name as BrandName, sum(distinct r.totalSpent) as TotalSpent from 
BrandData b
join OrderItemsData o on b.brandId = o.brandId
join ReceiptData r on r.receiptId = o.receiptId
where r.dateScanned >= Dateadd(Month, Datediff(Month, 0, DATEADD(m, -6, current_timestamp)), 0)
group by b.name
) as Group1
from Group1
order by TotalSpent desc

-- Which brand has the most transactions among users who were created within the past 6 months?
-- past 6 months refers to may - october if considering from Nov, 2022
Select top 1 BrandName as TopBrand from 
(
select b.name as BrandName, count(distinct r.receiptId) as ReceiptCount from 
BrandData b
join OrderItemsData o on b.brandId = o.brandId
join ReceiptData r on r.receiptId = o.receiptId
where r.dateScanned >= Dateadd(Month, Datediff(Month, 0, DATEADD(m, -6, current_timestamp)), 0)
group by b.name
) as Group1
from Group1
order by ReceiptCount desc