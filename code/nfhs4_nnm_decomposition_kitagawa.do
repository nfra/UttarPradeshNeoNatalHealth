* Name: nfhs4_nnm_decomposition_kitagawa
* Written by: Nathan Franz
* Description: Kitagawa decomposition of neo-natal mortality rates between Uttar
*			   Pradesh and the rest of India by mother's height
* Last edited: 4/5/2020

use ".\UttarPradeshNeoNatalHealth\data\nfhs4_files\IABR74FL.DTA"

* Keep only births in period of interest: Apr 2014 - Mar 2015
* In CMCs, this is 1372 - 1383
keep if b3 >=1372 & b3<=1383

* Remove the outliers below 4.5 ft (137.2 cm) and above 6 ft (182.9)
keep if v438 >= 1372 & v438 <= 1829

* Divide height by 10 because v438 is stored with units of tenths of centimeters
generate mother_height_cm = v438/10




* Create table of deciles for mother's heights, with count and mean
_pctile mother_height_cm, p(10(10)90)
 ret li
 gen decile = 10 if mother_height_cm < .
 qui forval i = 9(-1)1 {
         replace decile = `i' if mother_height_cm <= r(r`i')
 }
 tabstat mother_height_cm, by(decile) s(n mean)

* Create table of centiles for mother's height, with count and mean
_pctile mother_height_cm, p(1(1)99)
 ret li
 gen centile = 100 if mother_height_cm < .
 qui forval i = 99(-1)1 {
         replace centile = `i' if mother_height_cm <= r(r`i')
 }
 tabstat mother_height_cm, by(centile) s(n mean)
