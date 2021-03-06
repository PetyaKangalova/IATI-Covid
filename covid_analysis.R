list.of.packages <- c("data.table", "anytime", "Hmisc","reshape2","splitstackshape", "stringdist")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "/home/alex/git/IATI-Covid/output/"
setwd(wd)

comm = c("C", "2")
disb = c("E", "D", "3", "4")
incom = c("11")

agg <- fread("iati_unfiltered_agg.csv",na.strings="")
agg = subset(agg, secondary_reporter %in% c("0","false"))

agg$glide_narr_dist = stringdist("EP-2020-000012-001",agg$humanitarian_scope_narrative)
agg$glide_code_dist = stringdist("EP-2020-000012-001",agg$humanitarian_scope_code)

covid_related = subset(
  agg,
  grepl("covid-19", activity_title, ignore.case=T) |
    grepl("covid-19", activity_description, ignore.case=T) |
    grepl("covid-19", transaction_description_narrative, ignore.case=T) |
    humanitarian_scope_code == "EP-2020-000012-001" |
    humanitarian_scope_code == "HCOVD20" |
    tag_code == "COVID-19"
)
covid_related_activities = unique(covid_related$iati_identifier)
dportal = fread("dportal.csv")
names(dportal) = make.names(names(dportal))
dportal$iati.identifier = sapply(dportal$iati.identifier,URLdecode)
dportal_activities = unique(dportal$iati.identifier)
new_in_dportal = setdiff(dportal_activities,covid_related_activities)
new_in_registry = setdiff(covid_related_activities,dportal_activities)
new.d = subset(dportal,iati.identifier %in% new_in_dportal)
new.r = subset(covid_related,iati_identifier %in% new_in_registry)

near_covid = subset(
  agg,
  grepl("covid", activity_title, ignore.case=T) |
    grepl("covid", activity_description, ignore.case=T) |
    grepl("covid", transaction_description_narrative, ignore.case=T) |
    grepl("corona", activity_title, ignore.case=T) |
    grepl("corona", activity_description, ignore.case=T) |
    grepl("corona", transaction_description_narrative, ignore.case=T) |
    grepl("cov19", activity_title, ignore.case=T) |
    grepl("cov19", activity_description, ignore.case=T) |
    grepl("cov19", transaction_description_narrative, ignore.case=T) |
    grepl("covid", humanitarian_scope_code, ignore.case=T) |
    grepl("covid", humanitarian_scope_narrative, ignore.case=T) |
    grepl("covid", tag_code, ignore.case=T) |
    grepl("covid", tag_narrative, ignore.case=T) |
    grepl("corona", humanitarian_scope_code, ignore.case=T) |
    grepl("corona", humanitarian_scope_narrative, ignore.case=T) |
    grepl("corona", tag_code, ignore.case=T) |
    grepl("corona", tag_narrative, ignore.case=T) |
    grepl("cov19", humanitarian_scope_code, ignore.case=T) |
    grepl("cov19", humanitarian_scope_narrative, ignore.case=T) |
    grepl("cov19", tag_code, ignore.case=T) |
    grepl("cov19", tag_narrative, ignore.case=T) |
    glide_code_dist==1
)
near_covid_activities = unique(near_covid$iati_identifier)
new_ids = setdiff(near_covid_activities,covid_related_activities)
length(new_ids)
keep = c("iati_identifier","reporting_org_name","year","transaction_date","activity_title","activity_description","transaction_description_narrative",
         "humanitarian_scope_code", "humanitarian_scope_narrative","tag_code","tag_narrative"
         )
keep.act = c("iati_identifier","reporting_org_name","activity_title","activity_description",
             "humanitarian_scope_code", "humanitarian_scope_narrative","tag_code","tag_narrative"
)
keep.act.trans = c("iati_identifier","transaction_type","usd_disbursement"
)
fwrite(unique(near_covid[which(near_covid$iati_identifier %in% new_ids),keep,with=F]),"near_covid.csv")

covid_related_activities = unique(covid_related[,keep.act,with=F])
covid_related_act_trans = covid_related[,keep.act.trans,with=F]
covid_related_act_trans$usd_disbursement = as.numeric(covid_related_act_trans$usd_disbursement)
covid_related_act_tab = covid_related_act_trans[,.(
  sum_commitments=sum(.SD$usd_disbursement[which(.SD$transaction_type %in% comm)],na.rm=T),
  sum_disbursements=sum(.SD$usd_disbursement[which(.SD$transaction_type %in% disb)],na.rm=T)
  ),by=.(iati_identifier)]
covid_related_activities = merge(covid_related_activities,covid_related_act_tab,by="iati_identifier",all.x=T)

fwrite(covid_related_activities,"covid_related_activities.csv")

# BASIC QUESTIONS
# Which IATI publishers are currently publishing COVID-19 related activities/transactions? Which elements are they using?
iati_publishers = fread("../iati_publishers_list.csv")
iati_publishers = unique(iati_publishers[,c("publisher","IATI Organisation Identifier")])
setnames(iati_publishers,"IATI Organisation Identifier","reporting_org_ref")
covid_publishers = unique(covid_related$reporting_org_name)
covid_publishers = covid_publishers[order(covid_publishers)]
covid_publishers
#   Free text - activity title
# Free text - activity description
# Free text - transaction description
# Hum scope codes- GLIDE and HRP
# Tag element for development activities- vocab 99 with code= COVID-19
covid_related$using_title = grepl("covid-19", covid_related$activity_title, ignore.case=T)
covid_related$using_description = grepl("covid-19", covid_related$activity_description, ignore.case=T)
covid_related$using_transaction_description = grepl("covid-19", covid_related$transaction_description_narrative, ignore.case=T)
covid_related$using_glide = covid_related$humanitarian_scope_narrative == "EP-2020-000012-001" | covid_related$humanitarian_scope_code == "EP-2020-000012-001"
covid_related$using_appeal = covid_related$humanitarian_scope_narrative == "HCOVD20" | covid_related$humanitarian_scope_code == "HCOVD20"
covid_related$using_tag = covid_related$tag_code == "COVID-19" | covid_related$tag_narrative == "COVID-19"

covid_related$using_title[which(is.na(covid_related$using_title))] = FALSE
covid_related$using_description[which(is.na(covid_related$using_description))] = FALSE
covid_related$using_transaction_description[which(is.na(covid_related$using_transaction_description))] = FALSE
covid_related$using_glide[which(is.na(covid_related$using_glide))] = FALSE
covid_related$using_appeal[which(is.na(covid_related$using_appeal))] = FALSE
covid_related$using_tag[which(is.na(covid_related$using_tag))] = FALSE

using_tab = covid_related[,.(
  using_title = any(using_title),
  using_description = any(using_description),
  using_transaction_description = any(using_transaction_description),
  using_glide = any(using_glide),
  using_appeal = any(using_appeal),
  using_tag = any(using_tag)
),by=.(reporting_org_ref)]
using_tab$using_any = T
using_tab = merge(iati_publishers,using_tab,by="reporting_org_ref",all.y=T,sort=F)
fwrite(using_tab,"using_tab.csv")
# Which countries is COVID-19 funding going to? (assess number of activities per recipient country)
countries_tab = covid_related[,.(activity_count=length(unique(.SD$iati_identifier))),by=.(recipient_country_codes)]
fwrite(countries_tab,"countries_tab.csv",na="")
# From all IATI members, how many are publishing vs not publishing? Which members are publishing vs not publishing?
members = fread("../members.csv")
members = subset(members,publisher!="")
members = members[,c("Name","publisher")]
members = merge(iati_publishers,members,by="publisher",sort=F)
members$reporting_org_ref = NULL
setnames(members,"Name","publisher_name")
members = merge(members,using_tab,all.x=T)
members$using_title[which(is.na(members$using_title))] = FALSE
members$using_description[which(is.na(members$using_description))] = FALSE
members$using_transaction_description[which(is.na(members$using_transaction_description))] = FALSE
members$using_glide[which(is.na(members$using_glide))] = FALSE
members$using_appeal[which(is.na(members$using_appeal))] = FALSE
members$using_tag[which(is.na(members$using_tag))] = FALSE
members$using_any[which(is.na(members$using_any))] = FALSE
fwrite(members,"members_using.csv",na="")

#   Pick one specific member. Use as an example of publishing good data?
#   Can we track progress over time for publishers? Run a query to show increase of publishers and activities over time.
# Number of activities by reporting organization type
org_type_tab = covid_related[,.(activity_count=length(unique(.SD$iati_identifier)), org_count=length(unique(.SD$reporting_org_name))),by=.(reporting_org_type)]
org_types = fread("../OrganisationType.csv")
org_types = org_types[,c("code","name")]
names(org_types) = c("reporting_org_type","reporting_org_type_name")
org_type_tab$reporting_org_type = as.numeric(org_type_tab$reporting_org_type)
org_type_tab = merge(org_type_tab,org_types)
fwrite(org_type_tab,"org_type_tab.csv")

all_org_type_tab = agg[,.(activity_count=length(unique(.SD$iati_identifier)), org_count=length(unique(.SD$reporting_org_name))),by=.(reporting_org_type)]
all_org_type_tab$reporting_org_type = as.numeric(all_org_type_tab$reporting_org_type)
all_org_type_tab = merge(all_org_type_tab,org_types)
fwrite(all_org_type_tab,"all_org_type_tab.csv")
# 
# MORE DETAILED QUESTIONS
# How much money has been allocated to COVID-19 up to now? Track progress over the year.
covid_related_trans = covid_related
covid_related_trans$transaction_date = anydate(covid_related_trans$transaction_date)
covid_related_trans$using_transaction_description = grepl("covid-19", covid_related_trans$transaction_description_narrative, ignore.case=T)
covid_related_trans = subset(covid_related_trans,using_transaction_description)
covid_related_trans$usd_disbursement = as.numeric(covid_related_trans$usd_disbursement)
sum(subset(covid_related_trans, transaction_type %in% comm)$usd_disbursement,na.rm=T)
sum(subset(covid_related_trans, transaction_type %in% disb)$usd_disbursement,na.rm=T)
fwrite(covid_related_trans,"covid_related_transactions.csv")
# Money allocated to COVID-19 = the money in transactions that are identified as COVID-19-related (can’t be assume that all transactions within an activity are COVID-19-related)
# Could assess total commitments/disbursements in COVID-19-related activities and transactions vs total commitments/disbursement for the transactions we can definitively say are COVID-19-related (because the specific transactions are identified as COVID-19-related)
covid_related$usd_disbursement = as.numeric(covid_related$usd_disbursement)
sum(subset(covid_related, transaction_type %in% comm)$usd_disbursement,na.rm=T)
sum(subset(covid_related, transaction_type %in% disb)$usd_disbursement,na.rm=T)
# Which activities and who is involved? 
covid_participants = covid_related
covid_participants$transaction.id = c(1:nrow(covid_participants))
names(covid_participants) = gsub("_",".",names(covid_participants))
original_names = names(covid_participants)
covid_participants.split = cSplit(covid_participants,c("participating.org.ref","participating.org.type","participating.org.role","participating.org.name"),",")
new_names = setdiff(names(covid_participants.split),original_names)
covid_participants.split.long = reshape(covid_participants.split, varying=new_names, direction="long", sep="_")
covid_participants.split.long[ , `:=`( max_count = .N , count = 1:.N ) , by = transaction.id ]
covid_participants.split.long=subset(covid_participants.split.long, !is.na(participating.org.role) | max_count==1 | count==1)
covid_participants.split.long[,c("max_count", "count", "transaction.id", "id", "time")] = NULL
covid_participants_unique = unique(covid_participants.split.long[,c("iati.identifier","participating.org.ref","participating.org.type","participating.org.role","participating.org.name")])
org_roles = fread("../OrganisationRole.csv")
org_roles = org_roles[,c("code","name")]
names(org_roles) = c("participating.org.role","participating.org.role.name")
covid_participants_unique$participating.org.role = as.numeric(covid_participants_unique$participating.org.role)
covid_participants_unique = merge(covid_participants_unique,org_roles)
fwrite(covid_participants_unique,"whos_involved.csv")
# What are the implementing agencies and how many activities are being implemented by each? 
implementing = subset(covid_participants_unique,participating.org.role.name=="Implementing")
implementing$participating.org.name = as.character(implementing$participating.org.name)
implementing$participating.org.name[which(is.na(implementing$participating.org.name))] = implementing$participating.org.ref[which(is.na(implementing$participating.org.name))]
implementing_tab = implementing[,.(activity_count=length(unique(.SD$iati.identifier))),by=.(participating.org.name)]
implementing_tab = implementing_tab[order(-implementing_tab$activity_count),]
fwrite(implementing_tab,"implementing_activity_count.csv")
# What are the implementing agencies by recipient country?
#   Which sectors are COVID-19-related activities/transactions targeting?
#   Qualitative analysis comparing the activities!
#   Try to assess which activities appear to be 100% COVID-19-related and which are clearly not (e.g. UNHCR activities)
# What transaction types have been used? 
#   Do COVID-19-related activities activities already have disbursements?
#   Are the COVID-19-related activities newly reported/published activities or were they previously reported and now the COVID-19-related values have been added? Or can we get a breakdown of each of these? 
#   Are there old activities which are now being included as having COVID-19-specifc values but had been published previously?
#   Who are the key receiver orgs? Run the check by identifying covid-19 transactions and the searching for provider and receiver-org.
