clear all

use "/dnc/data/ACS/acs_issue_models.dta"

set more off

*Creating the Response variable -- 1 if there is a non-citizen in the household (including self), 0 if not.
gen temp1 = 0
	replace temp1 = 1 if citizen == 3 //Not a citizen
egen temp2 = sum(temp1), by(serial) //Number of non-citizens in household
gen hh_noncit = 0
	replace hh_noncit = 1 if temp2 > 0 //Indicator var, 1 if a non-citizen is present in the household
drop temp1 temp2

*Creating other variables

**Out of sample
gen oos = 1
	replace oos = 0 if uniform() <= .3

**Vote Eligibility
gen vote_eligible = 0
	replace vote_eligible = 1 if age >=18 & citizen != 3

**Age
gen age_sq = age^2

gen age_1824 = 0
	replace age_1824 = 1 if age >=18 & age < 25
gen age_2534 = 0
	replace age_2534 = 1 if age >=25 & age < 35
gen age_3544 = 0
	replace age_3544 = 1 if age >=35 & age < 45
gen age_4554 = 0
	replace age_4554 = 1 if age >=45 & age < 55
gen age_5564 = 0
	replace age_5564 = 1 if age >=55 & age < 65
gen age_6574 = 0
	replace age_6574 = 1 if age >=65 & age < 75
gen age_75plus = 0
	replace age_75plus = 1 if age >=75

**Gender
gen gender_female = 0
	replace gender_female = 1 if sex == 2
gen gender_male = 0
	replace gender_male = 1 if sex == 1

**Marital status
***Married includes marriage with spouse present, marriage with spouse absent, exludes missing
gen consumer_smarstat_m = 0
	replace consumer_smarstat_m = 1 if marst == 1 | marst == 2
	
***Single includes widowed, divorced, seperated, never married, exclues missing
gen consumer_smarstat_s = 0
	replace consumer_smarstat_s = 1 if marst == 3 | marst == 4 | marst == 5 | marst == 6
	
**Race - In voter file there's multiple options to name this variable (race_black_m, race_black_h, and ethnicity_black_infousa), not sure which to use so I made a new name
gen race_black = 0
	replace race_black = 1 if racblk == 2

**Hispanic see above
gen hispanic_general = 0
	replace hispanic_general = 1 if hispan != 0
	
**Urban (if in metro area), check to make sure this is compatable with urban in the voter file, which is based on ruca score (< 4)
gen urban = 0
	replace urban = 1 if metro >= 2

**Fix effects by states
tab statefip, gen(state_d)

*Model building
logit hh_noncit age_1824 age_2534 age_3544 age_5564 age_6574 age_75plus ///
	state_d1-state_d5 state_d7-state_d51 ///
	hispanic_general ///
	poverty_rate_puma urban ///
	[weight = perwt] if vote_eligible == 1 & year == 2010 & oos == 0

drop hh_noncit_prob
predict hh_noncit_prob, pr

*Validation
drop hh_noncit_dec
xtile hh_noncit_dec = hh_noncit_prob if vote_eligible == 1 & year == 2010, n(10)
tabstat hh_noncit_prob hh_noncit if oos == 1, by(hh_noncit_dec) statistics(mean, count)
hist hh_noncit_prob if vote_eligible == 1 & year == 2010, bin(100) freq ///
	title(Non-citizen in HH) name(hh_noncit_hist)
drop hh_noncit_100 hh_noncit_prob_100
gen hh_noncit_100 = hh_noncit*100
gen hh_noncit_prob_100 = hh_noncit_prob*100
graph bar (mean) hh_noncit_prob_100 hh_noncit_100, over(hh_noncit_dec) ///
	title(Non-citizen in HH) name(hh_noncit_bar)
