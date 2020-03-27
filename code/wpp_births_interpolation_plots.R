
library(tidyverse)

ggplot(data = wpp2019_india2005to2020) +
  geom_step(aes(x=Year, y=Per.year.ave.interpolation)) +
  geom_path(aes(x=Year, y=Linear.interpolation.between.year.2.ave), color="blue") +
  geom_path(aes(x=Year, y=Linear.in.logs.interpolation.between.year.2.ave), color="red")

ggplot(data = wpp2019_india2005to2020) +
  geom_step(aes(x=Year, y=Per.year.ave.interpolation)) +
  geom_path(aes(x=Year, y=Linear.interpolation.between.year.3.ave), color="blue") +
  geom_path(aes(x=Year, y=Linear.in.logs.interpolation.between.year.3.ave), color="red")

