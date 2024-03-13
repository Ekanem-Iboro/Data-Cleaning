use portfolio;
SELECT * FROM portfolio.nashville_housing;
-- DATA CLEANING
-- standeredlizing date format
SELECT saledate ,
 convert(saledate,date) 
 as converted FROM portfolio.nashville_housing; 
 
 -- ways to update all data in a column
 update nashville_housing set saledate = convert(saledate,date) ;
 
 -- another way is to alter the table and add a column
 alter table nashville_housing add newsalesDate date after saledate;
 
  update nashville_housing set newsalesDate = convert(saledate,date) ;
  
  -- to delete a column in a table
 alter table nashville_housing drop newsalesDate;
 
 -- populate property address data
 SELECT PropertyAddress 
 FROM portfolio.nashville_housing
-- where PropertyAddress is null
where PropertyAddress ='' ; 
 
  SELECT *
 FROM portfolio.nashville_housing
-- where PropertyAddress is null
-- where PropertyAddress ='' ; 
-- the parcelid idis the same as the propertyaddress
order by parcelid;

--   SELECT  a.ParcelID , a.PropertyAddress, 
--   b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress,b.PropertyAddress)
--  FROM portfolio.nashville_housing a
--  join portfolio.nashville_housing b
--  on a.ParcelID = b.ParcelID
--  and a.UniqueID <> b.UniqueID
--  where a.PropertyAddress ='' ; microsoft sql
 
 SELECT 
    a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,
    COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress)
FROM portfolio.nashville_housing a
JOIN portfolio.nashville_housing b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress = '';

-- now lets update the new adress we p[opulated
-- update a
-- set PropertyAddress = COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress)
-- FROM portfolio.nashville_housing a
-- JOIN portfolio.nashville_housing b
-- ON a.ParcelID = b.ParcelID 
-- AND a.UniqueID <> b.UniqueID
-- WHERE a.PropertyAddress = ''; microsoft sql

UPDATE portfolio.nashville_housing a
JOIN portfolio.nashville_housing b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress)
WHERE a.PropertyAddress = '';


-- breaking out address in to individual columns(Address, city, State)
 SELECT * 
 FROM portfolio.nashville_housing;

SELECT SUBSTRING_INDEX(PropertyAddress, ',', 1) AS address,
SUBSTRING_INDEX(PropertyAddress, ',',-1) City
FROM portfolio.nashville_housing;

 alter table nashville_housing add PropertySpitAddress varchar(255) after PropertyAddress;
 UPDATE nashville_housing set PropertySpitAddress =SUBSTRING_INDEX(PropertyAddress, ',', 1);
 
  alter table nashville_housing add PropertySpitCity varchar(255) after PropertySpitAddress;
 UPDATE nashville_housing set PropertySpitCity =SUBSTRING_INDEX(PropertyAddress, ',', -1);
 
 -- breaking out ownwer address in to individual columns(Address, city, State)
 
  SELECT *
 FROM portfolio.nashville_housing;
 
--  select
--  parsename(replace(owneraddress, ',', '.'),1) microsoft sql

-- SELECT 
--     SUBSTRING(owneraddress, 1, LOCATE(',', owneraddress) - 1) AS address_before_first_comma,
--     SUBSTRING(owneraddress, LOCATE(',', owneraddress) + 1, 
--     LOCATE(',', owneraddress, LOCATE(',', owneraddress) + 1) 
--     - LOCATE(',', owneraddress) - 1) AS address_between_commas,
--     SUBSTRING(owneraddress, LOCATE(',', owneraddress, 
--     LOCATE(',', owneraddress) + 1) + 1) AS address_after_second_comma
-- FROM 
--     portfolio.nashville_housing;

SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 1), ',', -1) AS first_word,
     SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1) AS second_word,
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', -1), ',', 1) AS third_word
FROM 
    portfolio.nashville_housing;


alter table nashville_housing add owneraddressSplit varchar(255) after owneraddress;
 UPDATE nashville_housing set owneraddressSplit =
 SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 1), ',', -1); 
 
  alter table nashville_housing add ownerCity varchar(255) after owneraddressSplit;
 UPDATE nashville_housing set ownerCity =
 SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1);
 
   alter table nashville_housing add ownerState varchar(255) after ownerCity;
 UPDATE nashville_housing set ownerState =
 SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', -1), ',', 1);
 
 -- change y and n to yes and no in sold as vacant column
 
 select  distinct(soldasvacant) 
 ,count(soldasvacant) from nashville_housing
 group by soldasvacant
 order by 2;
 
 select soldasvacant,
 case when soldasvacant = "Y" then "Yes"
		when soldasvacant = "N" Then "No"
			else soldasvacant
            end
 from nashville_housing;
 
 update nashville_housing
 set soldasvacant =case when soldasvacant = "Y" then "Yes"
		when soldasvacant = "N" Then "No"
			else soldasvacant
            end;
 
-- remove duplicates
-- write cte and use window function to find where there are duplicate
WITH dupliCte AS(
select *,
row_number() over (partition by
parcelid,
propertyaddress,
saleprice,
newsalesdate,
LegalReference
order by
uniqueid) row_num
 from  nashville_housing
)
select * from  dupliCte
 where row_num > 1
;

-- 1 using  subqueries
DELETE FROM nashville_housing
WHERE uniqueid IN (
    SELECT uniqueid
    FROM (
        SELECT uniqueid,
               ROW_NUMBER() OVER (PARTITION BY parcelid, propertyaddress, 
               saleprice, newsalesdate, LegalReference 
               ORDER BY uniqueid) AS row_num
        FROM nashville_housing
    ) AS dupliCte
    WHERE row_num > 1
);

-- 3 ctes
WITH dupliCte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY parcelid, propertyaddress,
           saleprice, newsalesdate, LegalReference 
           ORDER BY uniqueid) AS row_num
    FROM nashville_housing
)
DELETE nashville_housing
FROM nashville_housing
JOIN dupliCte ON nashville_housing.uniqueid = dupliCte.uniqueid
WHERE dupliCte.row_num > 1;

 
 -- DELETE UNWANTED COLUMNS (propertyaddress, owneraddress, taxdistrict,saledate)
 SELECT * FROM nashville_housing;
 ALTER TABLE nashville_housing DROP saledate