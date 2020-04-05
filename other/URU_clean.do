*** Clean ECH and O*NET

* directories

global dir = "/Users/rafaelguntin/Dropbox/PhD - Year IV/covid19/employment"

global ECH = "$dir/DBF"

* ECH hogar

u "$ECH/H_2019_Terceros.dta", clear

decode NUMERO, gen(id)
decode ANIO, gen(year)
decode SECC, gen(sec)
decode NOMDPTO, gen(nomdpto)
decode SEGM, gen(segm)
decode LOC_AGR_13, gen(loc_agr_13)
decode NOMLOC13, gen(nomloc13)
decode NOMBARRIO, gen(nombarrio)
rename MES month 
drop NUMERO ANIO SECC NOMDPTO SEGM NOMLOC13 LOC_AGR_13 NOMBARRIO NOMLOC13
destring year, replace

* income relativo a linea de pobreza

gen income = HT11
replace income = HT11- HT13 if REGION_4==4

gen hpobre=0
replace hpobre=1 if income<=LP_06

gen check = hpobre - POBRE06
sum check 

gen ing_rel = income/LP_06

save "$dir/ECH_hogares_2019.dta", replace

* ECH personas

u "$ECH/P1_2019_Terceros.dta", clear

decode F71_2, gen(F_71_2_)
decode F72_2, gen(F_72_2_)
decode F76_2, gen(F_76_2_)
decode NUMERO, gen(id)
decode ANIO, gen(year)
decode SECC, gen(sec)
decode NOMDPTO, gen(nomdpto)
decode SEGM, gen(segm)
decode LOC_AGR_13, gen(loc_agr_13)
decode NOMLOC13, gen(nomloc13)
decode NOMBARRIO, gen(nombarrio)
rename MES month 
drop NUMERO ANIO SECC NOMDPTO SEGM NOMLOC13 LOC_AGR_13 NOMBARRIO NOMLOC13 F71_2 F72_2 F76_2
rename F_76_2_ sec2_1
rename F_72_2_ sec_1
rename F_71_2_ ocup_1

destring year, replace

tempfile p1
save `p1', replace

u "$ECH/P2_2019_Terceros.dta", clear

decode NUMERO, gen(id)
decode F90_2, gen(F90_2_)
decode F91_2, gen(F91_2_)
decode F119_2, gen(F119_2_)
decode F120_2, gen(F120_2_)
drop NUMERO F90_2 F91_2 F119_2 F120_2
rename F90_2_ ocup_2
rename F91_2_ sec_2
rename F119_2_ ocup_u
rename F120_2_ sec_u

merge 1:1 id NPER using `p1' , nogenerate
merge m:1 id using "$dir/ECH_hogares_2019.dta"

save "$dir/ECH_personas_2019.dta", replace

* tareas trabajo principal considered - O*NET

* working activities

import excel "$dir/Work Activities.xlsx", sheet("Work Activities") firstrow clear

keep if ScaleID == "IM"

gen work_act = .
replace work_act = 0 if ElementName =="Getting Information"
replace work_act = 0 if ElementName =="Monitor Processes, Materials, or Surroundings"
replace work_act = 0 if ElementName =="Identifying Objects, Actions, and Events"
replace work_act = 1 if ElementName =="Inspecting Equipment, Structures, or Material"
replace work_act = 0 if ElementName =="Estimating the Quantifiable Characteristics of Products, Events, or Information"
replace work_act = 0 if ElementName =="Judging the Qualities of Things, Services, or People"
replace work_act = 0 if ElementName =="Processing Information"
replace work_act = 0 if ElementName =="Evaluating Information to Determine Compliance with Standards"
replace work_act = 0 if ElementName =="Analyzing Data or Information"
replace work_act = 0 if ElementName =="Making Decisions and Solving Problems"
replace work_act = 0 if ElementName =="Thinking Creatively"
replace work_act = 0 if ElementName =="Updating and Using Relevant Knowledge"
replace work_act = 0 if ElementName =="Developing Objectives and Strategies"
replace work_act = 0 if ElementName =="Scheduling Work and Activities"
replace work_act = 0 if ElementName =="Organizing, Planning, and Prioritizing Work"
replace work_act = 1 if ElementName =="Performing General Physical Activities"
replace work_act = 1 if ElementName =="Handling and Moving Objects"
replace work_act = 1 if ElementName =="Controlling Machines and Processes"
replace work_act = 1 if ElementName =="Operating Vehicles, Mechanized Devices, or Equipment"
replace work_act = 0 if ElementName =="Interacting With Computers"
replace work_act = 0 if ElementName =="Drafting, Laying Out, and Specifying Technical Devices, Parts, and Equipment"
replace work_act = 1 if ElementName =="Repairing and Maintaining Mechanical Equipment"
replace work_act = 1 if ElementName =="Repairing and Maintaining Electronic Equipment"
replace work_act = 0 if ElementName =="Documenting/Recording Information"
replace work_act = 0 if ElementName =="Interpreting the Meaning of Information for Others"
replace work_act = 0 if ElementName =="Communicating with Supervisors, Peers, or Subordinates"
replace work_act = 0 if ElementName =="Communicating with Persons Outside Organization"
replace work_act = 0 if ElementName =="Establishing and Maintaining Interpersonal Relationships"
replace work_act = 0 if ElementName =="Assisting and Caring for Others"
replace work_act = 0 if ElementName =="Selling or Influencing Others"
replace work_act = 0 if ElementName =="Resolving Conflicts and Negotiating with Others"
replace work_act = 1 if ElementName =="Performing for or Working Directly with the Public"
replace work_act = 0 if ElementName =="Coordinating the Work and Activities of Others"
replace work_act = 0 if ElementName =="Developing and Building Teams"
replace work_act = 0 if ElementName =="Training and Teaching Others"
replace work_act = 0 if ElementName =="Guiding, Directing, and Motivating Subordinates"
replace work_act = 0 if ElementName =="Coaching and Developing Others"
replace work_act = 0 if ElementName =="Provide Consultation and Advice to Others"
replace work_act = 0 if ElementName =="Performing Administrative Activities"
replace work_act = 0 if ElementName =="Staffing Organizational Units"
replace work_act = 0 if ElementName =="Monitoring and Controlling Resources"

keep if work_act == 1

keep ONETSOCCode Title ElementName ScaleID ScaleName DataValue

save "$dir/work_activities.dta", replace

* working context

import excel "$dir/Work Context.xlsx", sheet("Work Context") firstrow clear

keep if ScaleID == "CX"

gen work_cont = .
replace work_cont = 0 if ElementName =="Public Speaking"
replace work_cont = 0 if ElementName =="Telephone"
replace work_cont = 1 if ElementName =="Electronic Mail"
replace work_cont = 0 if ElementName =="Letters and Memos"
replace work_cont = 0 if ElementName =="Face-to-Face Discussions"
replace work_cont = 0 if ElementName =="Contact With Others"
replace work_cont = 0 if ElementName =="Work With Work Group or Team"
replace work_cont = 0 if ElementName =="Deal With External Customers"
replace work_cont = 0 if ElementName =="Coordinate or Lead Others"
replace work_cont = 0 if ElementName =="Responsible for Others' Health and Safety"
replace work_cont = 0 if ElementName =="Responsibility for Outcomes and Results"
replace work_cont = 0 if ElementName =="Frequency of Conflict Situations"
replace work_cont = 0 if ElementName =="Deal With Unpleasant or Angry People"
replace work_cont = 1 if ElementName =="Deal With Physically Aggressive People"
replace work_cont = 0 if ElementName =="Indoors, Environmentally Controlled"
replace work_cont = 0 if ElementName =="Indoors, Not Environmentally Controlled"
replace work_cont = 1 if ElementName =="Outdoors, Exposed to Weather"
replace work_cont = 1 if ElementName =="Outdoors, Under Cover"
replace work_cont = 0 if ElementName =="In an Open Vehicle or Equipment"
replace work_cont = 0 if ElementName =="In an Enclosed Vehicle or Equipment"
replace work_cont = 1 if ElementName =="Physical Proximity"
replace work_cont = 0 if ElementName =="Sounds, Noise Levels Are Distracting or Uncomfortable"
replace work_cont = 0 if ElementName =="Very Hot or Cold Temperatures"
replace work_cont = 0 if ElementName =="Extremely Bright or Inadequate Lighting"
replace work_cont = 0 if ElementName =="Exposed to Contaminants"
replace work_cont = 0 if ElementName =="Cramped Work Space, Awkward Positions"
replace work_cont = 0 if ElementName =="Exposed to Whole Body Vibration"
replace work_cont = 0 if ElementName =="Exposed to Radiation"
replace work_cont = 1 if ElementName =="Exposed to Disease or Infections"
replace work_cont = 0 if ElementName =="Exposed to High Places"
replace work_cont = 0 if ElementName =="Exposed to Hazardous Conditions"
replace work_cont = 0 if ElementName =="Exposed to Hazardous Equipment"
replace work_cont = 1 if ElementName =="Exposed to Minor Burns, Cuts, Bites, or Stings"
replace work_cont = 0 if ElementName =="Spend Time Sitting"
replace work_cont = 0 if ElementName =="Spend Time Standing"
replace work_cont = 0 if ElementName =="Spend Time Climbing Ladders, Scaffolds, or Poles"
replace work_cont = 1 if ElementName =="Spend Time Walking and Running"
replace work_cont = 0 if ElementName =="Spend Time Kneeling, Crouching, Stooping, or Crawling"
replace work_cont = 0 if ElementName =="Spend Time Keeping or Regaining Balance"
replace work_cont = 0 if ElementName =="Spend Time Using Your Hands to Handle, Control, or Feel Objects, Tools, or Controls"
replace work_cont = 0 if ElementName =="Spend Time Bending or Twisting the Body"
replace work_cont = 0 if ElementName =="Spend Time Making Repetitive Motions"
replace work_cont = 1 if ElementName =="Wear Common Protective or Safety Equipment such as Safety Shoes, Glasses, Gloves, Hearing Protection, Hard Hats, or Life Jackets"
replace work_cont = 1 if ElementName =="Wear Specialized Protective or Safety Equipment such as Breathing Apparatus, Safety Harness, Full Protection Suits, or Radiation Protection"
replace work_cont = 0 if ElementName =="Consequence of Error"
replace work_cont = 0 if ElementName =="Impact of Decisions on Co-workers or Company Results"
replace work_cont = 0 if ElementName =="Frequency of Decision Making"
replace work_cont = 0 if ElementName =="Freedom to Make Decisions"
replace work_cont = 0 if ElementName =="Degree of Automation"
replace work_cont = 0 if ElementName =="Importance of Being Exact or Accurate"
replace work_cont = 0 if ElementName =="Importance of Repeating Same Tasks"
replace work_cont = 0 if ElementName =="Structured versus Unstructured Work"
replace work_cont = 0 if ElementName =="Level of Competition"
replace work_cont = 0 if ElementName =="Time Pressure"
replace work_cont = 0 if ElementName =="Pace Determined by Speed of Equipment"
replace work_cont = 0 if ElementName =="Work Schedules"
replace work_cont = 0 if ElementName =="Duration of Typical Work Week"

keep if work_cont == 1

keep ONETSOCCode Title ElementName ScaleID ScaleName DataValue

save "$dir/work_context.dta", replace

* CPI index

import excel "$dir/IPC.xls", sheet("IPC_Cua 1") cellrange(A11:B1003) clear
gen year = year(A) 
gen month = month(A)
drop A
rename B CPI

sum CPI if year == 2020 & month == 2
replace CPI = r(mean)/CPI

save "$dir/CPI.dta", replace
