setwd("...")
list.files("...")

bike = data.table::fread("train.csv")
test = data.table::fread("test.csv")

df <- rbind(bike, test)

head(df, 4)

In [1]:
library(dplyr, quietly = T, warn.conflicts = F)
library(data.table, quietly = T, warn.conflicts = F)
library(fasttime, quietly = T, warn.conflicts = F)
library(lubridate, quietly = T, warn.conflicts = F)
library(xgboost, quietly = T, warn.conflicts = F)
library(ggplot2, quietly = T, warn.conflicts = F)
library(ggthemes, quietly = T, warn.conflicts = F)
library(corrgram, quietly = T, warn.conflicts = F)
library(plotly, quietly = T, warn.conflicts = F)
Sys.setenv("plotly_username"="...")
Sys.setenv("plotly_api_key"="...")
Sys.setenv("plotly_domain"="...")


bike$count = log1p(bike$count)


bike %>% 
    mutate(datetime = fastPOSIXct(datetime, "GMT")) %>% 
    mutate(hour = hour(datetime),
           month = month(datetime),
           year = year(datetime),
           wday = wday(datetime)) -> bike

test %>% 
    mutate(datetime = fastPOSIXct(datetime, "GMT")) %>% 
    mutate(hour = hour(datetime),
           month = month(datetime),
           year = year(datetime),
           wday = wday(datetime)) -> test

X_train = bike %>% select(-count, - datetime, -registered, - casual) %>% as.matrix()
y_train = bike$count

dtrain = xgb.DMatrix(X_train, label = y_train)
model = xgb.train(data = dtrain, nround = 150, max_depth = 5, eta = 0.1, subsample = 0.9)

xgb.importance(feature_names = colnames(X_train), model) %>% xgb.plot.importance()


p1 <- corrgram(df, order = TRUE, lower.panel = panel.shade, upper.panel = panel.pie, text.panel = panel.txt)

ggplot(df, aes(x=temp, y=count)) + geom_point(aes(colour = temp),alpha=0.5) 

#covert date "2013-03-11 07:00" to POSIXct format "2013-03" 
df$datetime <- as.POSIXct(df$datetime)
ggplot(df, aes(x=datetime, y=count)) + geom_point(aes(colour=temp),alpha=0.5,position=position_jitter(w=2, h=0)) + scale_color_continuous(low='#55D8CE',high='#FF6E2E') 

col.tem.count <- cor(df[,c('temp', 'count')])
col.tem.count

ggplot(df, aes(x=factor(season), y=count)) + geom_boxplot(aes(colour=factor(season)))

df$hour <- format(df$datetime,"%H")

workday.bike <- df %>%
  filter(workingday == 1)
#color selection was from http://www.color-hex.com/color-wheel/, I use color 1 combination.
ggplot(workday.bike, aes(x=hour, y=count)) + geom_point(aes(color=temp),position=position_jitter(w=1.5, h=0.5), alpha=0.5) + scale_color_gradientn(colors = c("#161c64","#1827e2",'#983cec','#ad3cec', '#ea3cec','#ec3c6c','#ec613c','#ec863c','#eca33c','#ecd13c'))+
  geom_smooth(aes(colour = temp, fill = temp))

NotWork.day <- df %>%
  filter(workingday == 0)
ggplot(NotWork.day, aes(x=hour, y=count)) + geom_point(aes(color=temp),position=position_jitter(w=1.5, h=0.5), alpha=0.5) + scale_color_gradientn(colors = c("#161c64","#1827e2",'#983cec','#ad3cec', '#ea3cec','#ec3c6c','#ec613c','#ec863c','#eca33c','#ecd13c'))

temp.model <- lm(count ~ temp, data = df)
summary(temp.model)

#make prediction using the linear regression model
print("How many bikes do we need when the temprature is 30?")
temp.test <- data.frame(temp=30)
predict(temp.model,temp.test)

df$hour <- sapply(df$hour, as.numeric)
P.bike <- select(df, season : hour)
#bike.num <- lapply(P.bike, as.numeric)
str(P.bike)

bike.model <- lm(count ~., data =P.bike)
summary(bike.model)

bike.test <- data.frame(season=3, holiday =1, workingday = 0, weather = 1, temp=30, atemp = 42, humidity = 10, windspeed = 2, hour =16, casual =0, registered = 689)
predict(bike.model, bike.test)
