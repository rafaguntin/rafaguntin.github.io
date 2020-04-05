**** baseline ****

* directories

global dir = "/Users/rafaelguntin/Dropbox/PhD - Year IV/covid19/employment"

global ECH = "$dir/DBF"

***** create indicators *****

u "$dir/work_context.dta", clear

append using "$dir/work_activities.dta"

replace DataValue = 6 - DataValue if ElementName == "Electronic Mail"
drop if ElementName == "Physical Proximity"

gen cod_1aux = substr(ONETSOCCode,1,2)
gen cod_2aux = substr(ONETSOCCode,4,7)
gen cod_3aux = substr(cod_2aux,1,4)

gen soc10 = cod_1aux + cod_3aux
destring soc10, replace
drop cod_1aux cod_2aux cod_3aux

*** work from home indicator

* Step 1: average activities across SOC

collapse(mean) DataValue, by(soc10)

* Step 2: use indicator if high chance of distance work

gen i_workhome = (DataValue<=2)

* Step 3: aggregate from SOC to ISCO categories (mean, max, min)

merge 1:m soc10 using "$dir/onetsoc_to_isco_cws_ibs/soc10_isco08.dta"
keep if _merge == 3
drop _merge

collapse(mean) workhome = DataValue (mean) i_workhome_mean = i_workhome  (max) i_workhome_max =i_workhome (min) i_workhome_min=i_workhome, by(isco08)

save "$dir/index_home.dta", replace

u "$dir/work_context.dta", clear

append using "$dir/work_activities.dta"

replace DataValue = 6 - DataValue if ElementName == "Electronic Mail"

gen cod_1aux = substr(ONETSOCCode,1,2)
gen cod_2aux = substr(ONETSOCCode,4,7)
gen cod_3aux = substr(cod_2aux,1,4)

gen soc10 = cod_1aux + cod_3aux
destring soc10, replace
drop cod_1aux cod_2aux cod_3aux

*** work from proximity

keep if ElementName == "Physical Proximity"

* Step 1: average activities across SOC

collapse(mean) DataValue, by(soc10)

* Step 2: use indicator if high proximity

gen i_prox = (DataValue>=4)

* Step 3: aggregate from SOC to ISCO categories (mean, max, min)

merge 1:m soc10 using "$dir/onetsoc_to_isco_cws_ibs/soc10_isco08.dta"
keep if _merge == 3
drop _merge

collapse(mean) prox = DataValue (mean) i_prox_mean = i_prox (max) i_prox_max =i_prox (min) i_prox_min=i_prox, by(isco08)

save "$dir/index_prox.dta", replace

***** characteristicas ECH *****

u "$dir/ECH_personas_2019.dta", clear
drop _merge
merge m:1 month year using "$dir/CPI.dta"
keep if _merge == 3
drop _merge

rename F73 pos_trabajo

tab pos_trabajo [fw=PESOANO]

drop if pos_trabajo == 0
drop if pos_trabajo == 2
drop if pos_trabajo == 3
drop if pos_trabajo == 7
drop if pos_trabajo == 8

rename PT2 ingreso
*rename PT4 ingreso
replace ingreso = ingreso*CPI

gen isco08 = ocup_1
destring isco08, replace

merge m:1 isco08 using  "$dir/index_home.dta"
keep if _merge == 3
drop _merge

merge m:1 isco08 using  "$dir/index_prox.dta"
keep if _merge == 3
drop _merge

** caracteristicas

local vars = "mean"
foreach x of local vars {

gen both_`x' = (i_prox_`x' == 1 & i_workhome_`x' == 0)

sum i_workhome_`x' i_prox_`x' both_`x' [fw=PESOANO]

sum i_workhome_`x' i_prox_`x' both_`x' if hpobre == 1 [fw=PESOANO]
sum i_workhome_`x' i_prox_`x' both_`x' if F82 == 2 [fw=PESOANO]
sum i_workhome_`x' i_prox_`x' both_`x' if F82 == 2 & hpobre == 1 [fw=PESOANO]

sum i_workhome_`x' i_prox_`x' both_`x' if E27>=55 & E27!=. [fw=PESOANO]
sum i_workhome_`x' i_prox_`x' both_`x' if E27<55 & E27>=30 & E27!=. [fw=PESOANO]
sum i_workhome_`x' i_prox_`x' both_`x' if E27<30 & E27!=. [fw=PESOANO]

sum i_workhome_`x' i_prox_`x' both_`x' if D8_1==5 [fw=PESOANO]

sum i_workhome_`x' i_prox_`x' both_`x' if nomdpto=="MONTEVIDEO" [fw=PESOANO]
sum i_workhome_`x' i_prox_`x' both_`x' if nomdpto!="MONTEVIDEO" [fw=PESOANO]

gen low_p_nothome = (i_prox_`x' == 0 & i_workhome_`x' == 0)

}

table i_prox_max i_workhome_max [fweight = PESOANO], contents(freq)
table i_prox_min i_workhome_min [fweight = PESOANO], contents(freq)
table i_prox_min i_workhome_max [fweight = PESOANO], contents(freq)
table i_prox_max i_workhome_min [fweight = PESOANO], contents(freq)

tempfile data
save `data', replace

xtile perc = ingreso [fw=PESOANO], nq(100)

collapse(mean) i_workhome_mean i_prox_mean i_workhome_min i_workhome_max i_prox_min i_prox_max [fw=PESOANO], by(perc)

gen i_lprox_nothome_mean = (1-i_workhome_mean)*(1-i_prox_mean)
gen i_lprox_nothome_max = (1-i_workhome_max)*(1-i_prox_max)
gen i_lprox_nothome_min = (1-i_workhome_min)*(1-i_prox_min)

twoway ///
(scatter i_workhome_mean i_prox_mean perc, msize(1 1) mcolor(black*.7 orange*.3) ) ///
(lowess i_workhome_mean perc, lw(1) lcolor(black) ) ///
(lowess i_prox_mean perc, lw(1) lcolor(orange) ) ///
, graphregion(color(white)) ///
xtitle("percentiles income main job") ytitle("share of workers") ///
xlabel(0(10)100,grid) ylabel(0(.25)1,grid) legend(order(3 "work from home" 4 "work close to others") region(color(white)) row(1)) name(c, replace)

twoway ///
(rarea i_prox_min i_prox_max perc, color(orange*.4)) ///
(rarea i_workhome_min i_workhome_max perc, color(gray*.4)) ///
(scatter i_workhome_mean i_prox_mean perc, msize(1 1) mcolor(black*.8 orange*.9) ) ///
, graphregion(color(white)) ///
xtitle("percentiles income main job") ytitle("share of workers") ///
xlabel(0(10)100,grid) ylabel(0(.25).75,grid) legend(order(3 "work from home" 4 "work close to others") region(color(white)) row(1)) name(d, replace)
graph export "$dir/fig1.pdf", replace

twoway ///
(rarea i_lprox_nothome_min i_lprox_nothome_max perc, color(emerald*.3)) ///
(scatter i_lprox_nothome_mean perc, msize(1 1) mcolor(emerald) ) ///
, graphregion(color(white)) ///
xtitle("percentiles income main job") ytitle("share of workers") ///
xlabel(0(10)100,grid) ylabel(0(.25)1,grid) name(e, replace) legend(off)
graph export "$dir/fig2.pdf", replace

** sectores

u `data', clear

destring sec_1, replace

gen sectors = "."
replace sectors = "A" if sec_1 >= 111 & sec_1 <= 240
replace sectors = "A" if sec_1 == 320
replace sectors = "A" if sec_1 == 321
replace sectors = "A" if sec_1 == 322
replace sectors = "B" if sec_1 == 311
replace sectors = "B" if sec_1 == 312
replace sectors = "C" if sec_1 >= 510 & sec_1 <= 990
replace sectors = "C" if sec_1 == 1920
replace sectors = "A" if sec_1 >= 1011 & sec_1<=1030
replace sectors = "D" if sec_1 >= 1031 & sec_1 <= 1919
replace sectors = "D" if sec_1 >= 2011 & sec_1 <= 3320
replace sectors = "E" if sec_1 >= 3510 & sec_1 <= 3900
replace sectors = "F" if sec_1 >= 4100 & sec_1 <= 4390
replace sectors = "G" if sec_1 >= 4510 & sec_1 <= 4799
replace sectors = "I" if sec_1 >= 4911 & sec_1 <= 5320

replace sectors = "H" if sec_1 >= 5510 & sec_1 <= 5630

replace sectors = "D" if sec_1 >= 5811 & sec_1 <= 5819

replace sectors = "K" if sec_1 == 5820
replace sectors = "O" if sec_1 >= 5911 & sec_1 <= 5914

replace sectors = "D" if sec_1 == 5920
replace sectors = "K" if sec_1 == 6010
replace sectors = "K" if sec_1 == 6020
replace sectors = "I" if sec_1 >= 6100 & sec_1 <= 6190
replace sectors = "K" if sec_1 >= 6201 & sec_1 <= 6312

replace sectors = "O" if sec_1 == 6391 
replace sectors = "K" if sec_1 == 6399

replace sectors = "J" if sec_1 > 6399 & sec_1 <= 6630

replace sectors = "K" if sec_1 >= 6810 & sec_1 <= 7490

replace sectors = "N" if sec_1 == 7500
replace sectors = "K" if sec_1 >= 7710 & sec_1 <= 7730

replace sectors = "J" if sec_1 == 7740
replace sectors = "K" if sec_1 >= 7810 & sec_1 <= 7830

replace sectors = "I" if sec_1 >= 7911 & sec_1 <= 7990

replace sectors = "K" if sec_1 >= 8010 & sec_1 <= 8129

replace sectors = "K" if sec_1 == 8130

replace sectors = "K" if sec_1 == 8211
replace sectors = "I" if sec_1 == 8219 
replace sectors = "K" if sec_1 >= 8220 & sec_1 <= 8299

replace sectors = "L" if sec_1 >= 8411 & sec_1 <= 8430

replace sectors = "M" if sec_1 >= 8510 & sec_1 <= 8550

replace sectors = "N" if sec_1 >= 8610 & sec_1 <= 8890

replace sectors = "O" if sec_1 >= 9000 & sec_1 <= 9492

replace sectors = "A" if sec_1 == 9499
replace sectors = "K" if sec_1 == 9511
replace sectors = "D" if sec_1 == 9512
replace sectors = "D" if sec_1 == 9521
replace sectors = "G" if sec_1 == 9522
replace sectors = "G" if sec_1 == 9523
replace sectors = "D" if sec_1 == 9524
replace sectors = "G" if sec_1 == 9529
replace sectors = "O" if sec_1 >= 9601 & sec_1 <= 9609

replace sectors = "P" if sec_1 == 9700 | sec_1 == 9820 | sec_1 == 9810

replace sectors = "Q" if sec_1 == 9900

gen sectores = "."
replace sectores = "Agricultura" if sectors == "A" | sectors == "B"
replace sectores = "Manufactura" if sectors == "D"
replace sectores = "Explotacion + Suministro de Energia" if sectors == "C" | sectors == "E"
replace sectores = "Construccion" if sectors == "F"
replace sectores = "Comercio" if sectors == "G"
replace sectores = "Restaurantes + Hoteles" if sectors == "H"
replace sectores = "Transporte + Comun." if sectors == "I"
replace sectores = "Serv. profesional + inmob." if sectors == "J" | sectors == "K"
replace sectores = "Publicos" if sectors == "L"
replace sectores = "Educacion" if sectors == "M"
replace sectores = "Salud" if sectors == "N"
replace sectores = "Otros servicios" if sectors == "O"
replace sectores = "Serv Domestico" if sectors == "P"

collapse(mean) i_workhome_mean i_prox_mean i_workhome_min i_workhome_max i_prox_min i_prox_max [fw=PESOANO], by(sectores)
drop if sectores == "."

twoway ///
(scatter i_workhome_mean i_prox_mean, mlabel(sectores) msize(2) mcolor(dknavy)) ///
, graphregion(color(white)) ///
xtitle("share work close to others") ytitle("share can work from home") ///
xlabel(0(.25)1,grid) ylabel(0(.25)1,grid) ///
xline(.5, lw(.7) lp(dash) lc(black)) yline(.5, lw(.7) lp(dash) lc(black)) name(b, replace)

** examples

u "$dir/ECH_personas_2019.dta", clear
drop _merge
merge m:1 month year using "$dir/CPI.dta"
keep if _merge == 3
drop _merge

rename F73 pos_trabajo

tab pos_trabajo [fw=PESOANO]

drop if pos_trabajo == 0
drop if pos_trabajo == 2
drop if pos_trabajo == 3
drop if pos_trabajo == 7
drop if pos_trabajo == 8

rename PT2 ingreso
*rename PT4 ingreso
replace ingreso = ingreso*CPI

gen isco08 = ocup_1
destring isco08, replace

merge m:1 isco08 using  "$dir/index_home.dta"
keep if _merge == 3
drop _merge

merge m:1 isco08 using  "$dir/index_prox.dta"
keep if _merge == 3
drop _merge

replace ingreso = ingreso*PESOANO
replace i_workhome_mean = i_workhome_mean*PESOANO
replace i_prox_mean = i_prox_mean*PESOANO

collapse(sum) PESOANO i_workhome_mean i_prox_mean ingreso, by(isco08)

replace ingreso = ingreso/PESOANO
replace i_workhome_mean = i_workhome_mean/PESOANO
replace i_prox_mean = i_prox_mean/PESOANO

sort PESOANO
