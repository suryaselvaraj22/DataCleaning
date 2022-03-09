/* 
SQL Cleaning
*/

-- Look at the data

SELECT * 
FROM PortfolioProject..NashvilleHousing;

-- Standardize the date format 

SELECT SaleDate
FROM PortfolioProject..NashvilleHousing;

-- Timestamp doesn't really help here, so we can remove it => Make it short date format 

SELECT SaleDate, CONVERT(Date, SaleDate) 
FROM PortfolioProject..NashvilleHousing;

-- UPDATE doesn't alter table structure, ALTER does 

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate); 

-- ALTER table is used to change table structure 

ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate Date NOT NULL;

-- Check now 

SELECT SaleDate
FROM PortfolioProject..NashvilleHousing;

-- Populate property address data 

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;

-- Check if there are NULL values 

SELECT COUNT(*)
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Check if property address can be populated from some other record, since it doesn't change. Owner address might change but property address is the same. We have two IDs. 

SELECT * 
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;

-- Use a SELF JOIN

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress 
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
ON a.ParcelID = b.ParcelID 
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Use ISNULL() to populate null values 

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
ON a.ParcelID = b.ParcelID 
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Use UPDATE statement to update values in a table 

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
ON a.ParcelID = b.ParcelID 
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Check for NULL values now 

SELECT COUNT(*)
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Break out address into individual columns (Address, City, State) 

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;

-- Property address has the following format => Address, City => Split this with delimiter , 

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS PropAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS PropCity
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropAddress nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropCity nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

UPDATE PortfolioProject..NashvilleHousing
SET PropCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

-- Check Now 

SELECT PropertyAddress, PropAddress, PropCity
FROM PortfolioProject..NashvilleHousing;

-- Now for Owner Address

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing;

-- Owner Address format => Address, City, State => Split to 3 columns 

-- PARSENAME() => splits with delimiter . 

SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'),1) AS OwnState,
PARSENAME(REPLACE(OwnerAddress,',', '.'),2) AS OwnCity,
PARSENAME(REPLACE(OwnerAddress,',', '.'),3) AS OwnAddress
FROM PortfolioProject..NashvilleHousing;

-- Use ALTER and UPDATE to make the changes 

ALTER TABLE PortfolioProject..NashvilleHousing 
ADD OwnState nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing 
ADD OwnCity nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing 
ADD OwnAddress nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnState = PARSENAME(REPLACE(OwnerAddress,',', '.'),1);

UPDATE PortfolioProject..NashvilleHousing
SET OwnCity = PARSENAME(REPLACE(OwnerAddress,',', '.'),2);

UPDATE PortfolioProject..NashvilleHousing
SET OwnAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'),3);

-- Check Now 

SELECT OwnerAddress, OwnAddress, OwnCity, OwnState
FROM PortfolioProject..NashvilleHousing;

-- Change Y and N to Yes and No in "SoldAsVacant" column 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- There are 4 types of values => N, No, Y, Yes => Make it consistent as Yes & No 

-- Use CASE statements to do this 

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No' 
	 ELSE SoldAsVacant
END
FROM PortfolioProject..NashvilleHousing;

-- Use UPDATE to make changes to values

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No' 
	 ELSE SoldAsVacant
END;

-- Check Now

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Remove Duplicates 

-- Partition Row number by differentiating columns 

SELECT * 
FROM PortfolioProject..NashvilleHousing;

SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID, 
			 PropertyAddress, 
			 SaleDate, 
			 SalePrice, 
			 LegalReference
ORDER BY ParcelID, 
			 PropertyAddress, 
			 SaleDate, 
			 SalePrice, 
			 LegalReference) AS RowNum
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;

-- Put this in a CTE 

WITH RemoveDups AS
(
SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID, 
			 PropertyAddress, 
			 SaleDate, 
			 SalePrice, 
			 LegalReference
ORDER BY ParcelID, 
			 PropertyAddress, 
			 SaleDate, 
			 SalePrice, 
			 LegalReference) AS RowNum
FROM PortfolioProject..NashvilleHousing
)
SELECT * 
FROM RemoveDups
WHERE RowNum > 1
ORDER BY ParcelID;

-- Best practice is to not delete the data 
-- RowNum = 1 => unique values => move to Table A 
-- RowNum != 1 => duplicate values => move to Table B 
-- Just add the unique rows into another temp table, table or view 

-- Creating a temp table for unique values 

-- Create a temp table #NashvilleHousingNoDups with same structure as NashvilleHousing. But if you plan on creating views => make this as a table and not a temp table. 

SELECT * INTO #NashvilleHousingNoDups FROM NashvilleHousing WHERE 1 = 2;

-- Check Now 

SELECT * FROM #NashvilleHousingNoDups;

-- Alter this to include RowNum as a column, so it is easy to add the unique rows here

ALTER TABLE #NashvilleHousingNoDups 
ADD RowNumber int;

-- CTE

WITH RemoveDups AS
(
SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID, 
			 PropertyAddress, 
			 SaleDate, 
			 SalePrice, 
			 LegalReference
ORDER BY ParcelID, 
			 PropertyAddress, 
			 SaleDate, 
			 SalePrice, 
			 LegalReference) AS RowNum
FROM PortfolioProject..NashvilleHousing
)
INSERT INTO #NashvilleHousingNoDups 
SELECT * FROM RemoveDups
WHERE RowNum = '1';

-- Check Now 

SELECT COUNT(*) FROM PortfolioProject..NashvilleHousing;

SELECT COUNT(*) FROM PortfolioProject..#NashvilleHousingNoDups;

-- Handling unused columns 
-- Create Views or Temp tables for relevant stuff 

SELECT * FROM PortfolioProject..#NashvilleHousingNoDups;

CREATE VIEW NashvilleHousingBasics 
AS
SELECT [UniqueID ], ParcelID, PropAddress, PropCity, SaleDate, SalePrice, LegalReference, OwnerName, OwnAddress, OwnCity, OwnState
FROM PortfolioProject..NashvilleHousing;

SELECT * FROM NashvilleHousingBasics;