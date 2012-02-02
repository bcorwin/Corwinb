clear all

use "/dnc/data/ACS/acs_issue_models.dta"

set more off

*Creating the Response variables
gen undergrad = 0
	replace undergrad = 1 if gradeatt == 6
gen grad = 0
	replace grad = 1 if gradeatt == 7

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

**Fix effects by age for young students
tab age if age < 30 & vote_eligible == 1, gen(age_d)

**Interactions
gen married_female = 0
	replace married_female = 1 if gender_female == 1 & consumer_smarstat_m == 1

*Model building (break undergrad into two groups, young and old students, cut at age 30)
logit undergrad age_d2-age_d12 ///
	gender_female married_female consumer_smarstat_m ///
	hispanic_general race_black ///
	urban ///
	[fw = perwt] if vote_eligible == 1 & year == 2010 & oos == 0 & age < 30
