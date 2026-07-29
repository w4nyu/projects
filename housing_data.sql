#loading of data 
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/users/wanyu/downloads/NashvilleHousing_fixed.csv'
INTO TABLE nashvilleHousing_fixed
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT COUNT(*) FROM nashvillehousing_fixed;

##### 

SELECT * FROM housing_data.nashvillehousing_fixed;

#SaleDate
SELECT SaleDate, CONVERT(SaleDate, DATE) AS SaleDateConverted FROM housing_data.nashvillehousing_fixed;

ALTER TABLE housing_data.nashvillehousing_fixed ADD SaleDateConverted DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE housing_data.nashvillehousing_fixed
SET SaleDateConverted = DATE(SaleDate);

#populate property address data 
select * from housing_data.nashvillehousing_fixed where PropertyAddress is null;

select a.parcelid, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.propertyaddress, b.propertyaddress)
from housing_data.nashvillehousing_fixed a join housing_data.nashvillehousing_fixed b 
on a.ParcelID = b.ParcelID and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

update housing_data.nashvillehousing_fixed a 
join housing_data.nashvillehousing_fixed b 
on a.ParcelID = b.ParcelID and a.UniqueID <> b.UniqueID
set a.PropertyAddress = ifnull(a.PropertyAddress, b.PropertyAddress)
where a.PropertyAddress is null;

#breaking down address 
select PropertyAddress from housing_data.nashvillehousing_fixed;

select substring(propertyaddress, 1, locate(",", propertyaddress) -1) as address, 
substring(propertyaddress, locate(",", propertyaddress) + 1) as city 
from housing_data.nashvillehousing_fixed;

alter table nashvillehousing_fixed add propertysplitaddress nvarchar(255); 
update nashvillehousing_fixed set propertysplitaddress = substring(propertyaddress, 1, locate(",", propertyaddress) -1); 

alter table nashvillehousing_fixed add propertysplitcity nvarchar(255); 
update nashvillehousing_fixed set propertysplitcity = substring(propertyaddress, locate(",", propertyaddress) + 1); 

#select * from housing_data.nashvillehousing_fixed;


select OwnerAddress from housing_data.nashvillehousing_fixed;

select
trim(substring_index(OwnerAddress, ',', 1)) as Address,
trim(substring_index(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) as City,
trim(substring_index(OwnerAddress, ',', -1)) as State
from housing_data.nashvillehousing_fixed;

alter table nashvillehousing_fixed add ownersplitaddress nvarchar(255); 
update nashvillehousing_fixed set ownersplitaddress = trim(substring_index(OwnerAddress, ',', 1));

alter table nashvillehousing_fixed add ownersplitcity nvarchar(255); 
update nashvillehousing_fixed set ownersplitcity = trim(substring_index(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1));

alter table nashvillehousing_fixed add ownersplitstate nvarchar(255); 
update nashvillehousing_fixed set ownersplitstate = trim(substring_index(OwnerAddress, ',', -1));

#select * from housing_data.nashvillehousing_fixed;

#change all to 'yes' and 'no' (sold as vacant column)
select distinct(SoldAsVacant), count(SoldAsVacant) from housing_data.nashvillehousing_fixed
group by soldasvacant;
    
update nashvillehousing_fixed 
set soldasvacant = CASE
        WHEN soldasvacant = 'Y' THEN 'Yes'
        WHEN soldasvacant = 'N' THEN 'No'
        ELSE soldasvacant
    END; 
    

#remove duplicates 
with rownumCTE as(
select *, row_number() over(
partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
order by UniqueID) row_num
from housing_data.nashvillehousing_fixed)
delete n
from housing_data.nashvillehousing_fixed n
join rownumCTE r on n.UniqueID = r.UniqueID
where r.row_num > 1;

#delete unused col 
alter table nashvillehousing_fixed 
drop column propertyaddress, 
drop column owneraddress, 
drop column taxdistrict, 
drop column saledate; 


