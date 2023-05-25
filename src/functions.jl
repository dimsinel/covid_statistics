"""
    dummy_project_function(x, y) → z
Dummy function for illustration purposes.
Performs operation:
```math
z = x + y
```
"""

function plot_country(ax, country::String, typeOfdead="new_deaths_smoothed")
    dd = filter(:location => n -> n == country, df_cov)
    if size(dd)[1] == 0
        dd = filter(:iso_code => n -> n == country, df_cov)
    end
    dateticks = optimize_ticks(dd.date[1], dd.date[end])[1]
    p = lines!(ax, datetime2rata.(dd.date), dd[!, typeOfdead]) #, label = country)
    ax.xticks[] = (datetime2rata.(dateticks) , Dates.format.(dateticks, "mm/dd/yyyy"));
    return p
end


function plot_countrymortality(ax, country::String, typeofdead::String="RTotal",df=df_hmd)
    country = uppercase(country)
    # @show names(df)
    dd  = filter([:Sex, :CountryCode] => (x, y) ->  x==("b") && y==(country), df)
    dates = @. Dates.Date(dd.Year) + Dates.Week(dd.Week)
    
    dateticks = optimize_ticks(dates[1], dates[end])[1]
    p = lines!(ax,  datetime2rata.(dates), dd[!, typeofdead]) # label = country)
    ax.xticks[] = (datetime2rata.(dateticks) , Dates.format.(dateticks, "mm/dd/yyyy"));
    return p
end

#####################################


# df11 = DataFrame(dates=Date(2020, 1, 1) : Day(1) : Date(2020, 1, 31), values=1:31);
# #df = DataFrame(dates=Date(2020, 1, 1) : Day(1) : Date(2020, 1, 31), values=1:31);
# dateticks = optimize_ticks(df11.dates[1], df11.dates[end])[1]
# size(dateticks)
# fig11 = Figure()

# ax1 = Axis(fig11[1,1],xlabelrotation=30)g
# plt = lines!(ax1, datetime2rata.(df11.dates), df11.values)
# lines!(ax1, range(37429, 737455,31) ,df11.values)
# ax1.xticks[] = (datetime2rata.(dateticks) , Dates.format.(dateticks, "mm/dd/yyyy"));
# #datetime2rata.(df11.dates


function interp_pop(date::Date,df_pop)
    nothing
end


# function choice(loc, tim)::Bool
#     country = loc == cod 
#     timefrom = myyear <= tim <= myyear + period 
#     return country &&  timefrom
# end

function get_cov_bycountry_byperiod(cod::String, myyear::Date,period=Year(1); df=df_cov )
    function choice(loc, tim)::Bool
        country = loc == cod 
        timefrom = myyear <= tim <= myyear + period 
        return country &&  timefrom
    end
    g = filter([:iso_code, :date] => choice, df)  
end
