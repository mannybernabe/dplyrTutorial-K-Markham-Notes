####
####Notes on dplyr tutorial by Kevin Markham
#### 

# https://www.youtube.com/watch?v=jWjqLW-u3hc
# Source doc: http://rpubs.com/justmarkham/dplyr-tutorial

#verbs: filter, select, arrange, mutate, summarise
#dplyr works with databases (i.e. sql)
#joins: inner join, left join, semi-join, anti-join
#window functions

remove(list=ls())

library(dplyr)
library(hflights)

data(hflights)
head(hflights)

#convert to "local data frame" tbl_df()
flights<-tbl_df(hflights)

#to see more of the top rows
print(flights,n=30)

##
##Verb Filter
##

#base r
flights[flights$Month==1 & flights$DayofMonth==1,]
flights[which(flights$Month==1 & flights$DayofMonth==1),]
subset(flights,flights$Month==1 & flights$DayofMonth==1)

#dplyr
filter(flights, Month==1, DayofMonth==1)
#use pipe for OR condition
filter(flights, UniqueCarrier=="AA"|UniqueCarrier=="UA")
filter(flights, UniqueCarrier %in% c("AA","UA"))


##
## Verb Select
##
names(flights)
flights[,c("DepTime","ArrTime","FlightNum")]
flights[,c(5,6,8)]

#dplyr
select(flights,DepTime, ArrTime, FlightNum)

#may use ":" and contains(),starts_with(),ends_with,
#matches()

select(flights, Year:DayofMonth,contains("Taxi"),contains("Delay"))


##
##Chaining/Piping, rather than nesting
##

#nesting
filter(select(flights, UniqueCarrier, DepDelay),DepDelay>60)

#piping/chaining
flights%>%
  select(UniqueCarrier, DepDelay)%>%
  filter(DepDelay>60)

#can also use %>% outside of dplyr
x<-1:10; y<-11:20
#nesting
sqrt(sum((y-x)^2))

#piping/chaining
(y-x)^2%>%sum()%>%sqrt()

sqrt(sum((y-x)^2)) == (y-x)^2%>%sum()%>%sqrt()




##
##Verb Arrange
##


#base 

flights[order(flights$DepDelay),c("UniqueCarrier","DepDelay")]

#dplyer with piping

flights%>%
  select(UniqueCarrier, DepDelay)%>%
  arrange(DepDelay)

#for descending wrapp with desc()

flights%>%
  select(UniqueCarrier, DepDelay)%>%
  arrange(desc(DepDelay))




##
##Verb Mutate
##

#base R
flights$Speed<-flights$Distance/flights$AirTime*60
flights[,c("Distance","AirTime","Speed")]

flights%>%
  select(Distance, AirTime)%>%
  mutate(Speed=Distance/AirTime*60)

## quickley create and store new variable

flights<-flights%>%mutate(Speed=Distance/AirTime*60)



##
##Summarise
##

#quite helpful when combined with group_by

#base R
head(with(flights,tapply(ArrDelay,Dest,mean,na.rm=T)))
head(aggregate(ArrDelay~Dest,flights,mean))

flights%>%
  group_by(Dest)%>%
  summarise(Avg=mean(ArrDelay,na.rm=T))

#summarise_each and mutate_each allow for application of same function 
#over many variables
flights%>%
  group_by(UniqueCarrier)%>%
  summarise_each(funs(mean(., na.rm = TRUE)),ArrDelay,Cancelled,Diverted)

#note that variables Cancelled and Diverted are binary, thus averge= percent



#for each carier, calculate the max and min arrival and depature delays

flights%>%
  group_by(UniqueCarrier)%>%
  summarise_each(funs(max(.,na.rm=T),min(.,na.rm=T)),matches("Delay"))
#note the usage of matches() for variable selection


# for each day of the year, count the total number
# of flights and sort in descending order

flights%>%
  group_by(Month,DayofMonth)%>%
  summarise(count=n())%>%
  arrange(desc(count))

#same as above, but with tally()
flights%>%
  group_by(Month, DayofMonth)%>%
  tally(sort=T)

# for each destination, count the total number of flights 
# and the number of distinct planes that flew there

flights%>%
  group_by(Dest)%>%
  summarise(count=n(),countTail=n_distinct(TailNum))



# for each destination, show the number of cancelled 
# and not cancelled flights

flights%>%
  group_by(Dest)%>%
  select(Cancelled)%>%
  table()%>%
  head()


##
##Windows
##

# For each carrier, calculate which two days of the year 
# they had their longest departure delays
# note: smallest (not largest) value is ranked as 1, 
# so you have to use `desc` to rank by largest value

flights%>%
  group_by(UniqueCarrier)%>%
  select(Month, DayofMonth,DepDelay)%>%
  filter(min_rank(desc(DepDelay)) <= 5) %>%
  arrange(UniqueCarrier,DepDelay) 
#above bring in top 5

#rewrite with top_n() usage

flights%>%
  group_by(UniqueCarrier)%>%
  select(Month, DayofMonth,DepDelay)%>%
  top_n(5)%>%
  arrange(UniqueCarrier,DepDelay) 


# for each month, calculate the number of flights and the 
# change from the previous month

flights%>%
  group_by(Month)%>%
  summarise(n=n())%>%
  mutate(change=n-lag(n))

#rewrite with tally
flights%>%
  group_by(Month)%>%
  tally()%>%
  mutate(change=n-lag(n))


##
##Other Useful Convenience Functions
##

#sample
flights %>% sample_n(5)
#or
sample_n(flights,3)

#random selection of percent of rows
flights %>% sample_frac(0.25, replace=TRUE) #or
sample_frac(flights,.25,replace=T)

#quick structure survey
#base R
str(flights)

#dplyr
glimpse(flights)



##
##Databases
##

#to be reviewed at later time, however, an excerpt:

# -dplyr can connect to a database as if the data was loaded into a data frame
# -Use the same syntax for local data frames and databases
# -Only generates SELECT statements
# -Currently supports SQLite, PostgreSQL/Redshift, MySQL/MariaDB, BigQuery, MonetDB
# -Example below is based upon an SQLite database containing the hflights data
# -Instructions for creating this database are in the databases vignette







