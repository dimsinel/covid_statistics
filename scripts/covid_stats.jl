using DrWatson
@quickactivate "covid_statistics"

using Revise
using Statistics
using CSV, XLSX, HTTP, DataFrames, Dates
using  PyCall, Parquet;
using PlotUtils: optimize_ticks

using GLMakie
#GLMakie.activate!()
include(srcdir("functions.jl"))
include(srcdir("pyget_owid_data.jl"))

downl = false #true
if downl
    get_owid_excess_mortality()
    get_owid_pop_data()
end

#df_mort = read_owid_excess_mortality()
#describe(df_mort)

df_pop = read_owid_pop_data()
describe(df_pop)

# human mortality database  Short-Term Mortality Fluctuations
downl=false
df_hmd = get_hmd_stmd(downl)
describe(df_hmd)

#df_pop2021 = datadir("exp_raw/populationUpTo2021.csv") |> CSV.File |> DataFrame
#describe(df_pop2021)

# we should probably download these, there should be new data here
downl = true
if downl
    get_owid_covid_data()
end
df_cov = read_owid_covid_data()
# missing values ind deat cols may be a nuiscance
for nam in [:new_deaths, :new_deaths_per_million]
    replace!(df_cov[!, nam],missing => 0) #
end
describe(df_cov)


 titl = "new_deaths_smoothed"
f  = Figure()
ax = Axis(f[1, 1], title=titl)
p1 = plot_country(ax, "Greece")
p2 = plot_country(ax, "Sweden") 

titl="total_deaths_per_million"
titl2="total_vaccinations_per_hundred" 

f1  = Figure()
ax1 = Axis(f1[2, 1],  title=titl, xlabelrotation=30, xticklabelrotation=deg2rad(30))
ax2 = Axis(f1[1, 1], title=titl2)
linkxaxes!(ax1, ax2)
hidexdecorations!(ax2, grid = false)

plot_country(ax1, "OWID_WRL",titl)
plot_country(ax2, "OWID_WRL",titl2)

# titl="total_vaccinations_per_hundred" # "total_vaccinations"
# gui(plot(title=titl))
# p1 = plot_country("Greece",titl)
# p2 = plot_country("Sweden",titl)
# p2 = plot_country("USA",titl)

titl = "DTotal" #excess_mortality_cumulative_per_million" # "total_vaccinations"
titl2 =  "RTotal"
f2  = Figure()
axs1 = Axis(f2[2, 1], title=titl, xlabelrotation=30, xticklabelrotation=deg2rad(30))
axs2 = Axis(f2[1, 1], title=titl2, xlabelrotation=30, xticklabelrotation=deg2rad(30))
#
p = plot_countrymortality(axs1, "grc", titl)
p2 = plot_countrymortality(axs2, "grc",titl2)




country2iso=Dict()
iso2country=Dict()
iso2continent=Dict()
owid_codes = Dict()

for cod in unique(df_cov.iso_code)
    g = df_cov[findfirst(==(cod), df_cov.iso_code),:]
    country2iso[g[4]] = g[1]
    iso2country[g[1]] = g[4]
    iso2continent[g[1]] = g[3]
    if occursin("owid",lowercase(cod) ) 
        println("$(g[1])  $(g[2])  $(g[3])  $(g[4]) $(g.population) " )
        owid_codes[g[4]] = g[1]
    end
end

continents =  df_cov.continent |> unique 
# remove missing elements. (Check out that deleteat and findall have opposite syntax)
deleteat!(continents, findall(ismissing, continents))

condict=Dict()
for i in continents
    condict[i] = (Vector{Integer}())
end

data_per_year = yr -> groupby( filter([:date, :population] => (x,y)-> year(x) == yr && y>(1), df_cov),  :iso_code)

dfgry2021 = data_per_year(2021) 
dfgry2022 = data_per_year(2022) 

for (i, (key, subdf)) in enumerate(pairs(dfgry2021))
    #dfgry_continents[]
    println("$(i) $(key.iso_code)   new_cases: $(mean(subdf.new_cases)) $(subdf.continent[begin])" )
    if !ismissing(subdf.continent[begin] )
        push!( condict[subdf.continent[begin] ], i)
    end
end

condict
dfgry2021[condict["Asia"] ]


function comb_dead(grp_dframe) 
    return combine(grp_dframe,
                [:new_deaths_per_million, :new_deaths,  :continent] =>
                ((p,q, t) -> (tot_dead_permillion=sum(p), tot_dead=sum(q), cont = first(t)) ) =>    
                AsTable) # multiple columns are passed as arguments
end

comb2021 = comb_dead(dfgry2021)
comb2022 = comb_dead(dfgry2022)

function get_cont_data(continent, df)
    aa = filter(:cont => ==(continent), dropmissing(df) )
    @show sum(aa.tot_dead)
    df[findfirst(==(owid_codes[continent]), df.iso_code),:]
end

get_cont_data("Oceania", comb2021)

#using Meshes

function scatterdata2122(ax1, ax2, df21, df22)
    for cont in continents
        scx = filter(:cont => ==(cont), dropmissing(df21) )
        scy = filter(:cont => ==(cont), dropmissing(df22) )
        # use innerjoin becouse somtimes 21 an 22 give different size matrices
        xx = innerjoin(scx[:,Not(:cont)], scy[:,Not(:cont)], on = :iso_code,makeunique=true, renamecols = "_21" => "_22")

        #deadp = Points()
        scdead = scatter!(ax1, xx.tot_dead_21, xx.tot_dead_22, alpha=.2)
        scpermil = scatter!(ax2, xx.tot_dead_permillion_21, xx.tot_dead_permillion_22)
      end
end

f = Figure()
ax1 = Axis(f[1,1] ,xlabel="2021",ylabel="2022", title="Dead")
ax2 = Axis(f[2,1], xlabel="2021",ylabel="2022", title="Dead per million")
scatterdata2122(ax1, ax2, comb2021, comb2022)

#axislegend()
#[] n for n in aa.iso_code if occursin("OWI", n)]

#= 
####  A Test!!!
isoid = "D_AS"
cont = "Asia"
for d in Date(2021,1,1):Date(2021,12,31)
    try
        a = df_cov[findall(x->occursin(isoid,x), df_cov.iso_code) ∩ findall(x-> x==(d), df_cov.date),:].new_deaths[1]
        b = filter([:date, :continent, :total_deaths] => (x,y,z) -> x == d && !ismissing(y) && y == cont && !ismissing(z), df_cov).new_deaths |> sum
    
    if a != b 
        @show d, a, b
    end
    if day(d) == 1
        @show d
    end

    catch TypeError
        println("Date ---> $(d)" )
    end
end
=#

    #= 
function complex_filter(date, population)::Bool
    thedates = year(date) == 2022 
    thepop = population > 1e6
    thedates && thepop
end

filtfd = filter([:date, :population] => complex_filter, df_cov)
dfgry202120212 = groupby(filtfd,  :iso_code)

=#

i=0
notfound= true
while notfound
    global i += 1
    notfound = dfgry2021[i][1,:iso_code] != "GRC"
end
dfgry2021[i]



[n for n in names(df_cov) if occursin("dea",n)]

############################################################
# Example from https://dataframes.juliadata.org/stable/man/split_apply_combine/
# this may have missing values ---> skipmissing usage?
f = Figure()
ax = Axis(f[1, 1], title="2021/2022 dead", xlabelrotation=30, xticklabelrotation=deg2rad(30))


sc = scatter!(ax, d2021.new_deaths_per_million_sum_skipmissing,d2022.new_deaths_per_million_sum_skipmissing)
combine(dfgry2021, nrow, proprow, groupindices)



combine(dfgry2021,
    [:new_deaths_per_million, :cardiovasc_death_rate] =>
    ((p, s) -> (a=mean(p)/mean(s), b=sum(p))) =>
    AsTable) # multiple columns are passed as arguments



combine(x -> std(x.new_deaths_per_million) / std(x.cardiovasc_death_rate), dfgry2021) # passing a SubDataFrame

combine(dfgry2021, :new_deaths_per_million => (x -> [extrema(x)]) => [:min, :max])
## To get row number for each observation within each group use the eachindex function:
combine(dfgry2021, eachindex)

# Contrary to combine, the select and transform functions always return a data frame with the same number and order of rows as the source.
select(dfgry2021, [6,8] => cor)
#!!!!!!!!!!!!!!!!!! combine results from previous year or obesity eg 
combine(dfgry2021, :excess_mortality_cumulative_per_million => mean)
#(but this is missing)

# To apply a function to each non-grouping column of a GroupedDataFrame you can write:
# combine(dfgry2021, valuecols(dfgry2021) .=> mean)
# (fails due to strings)


############################################################



function count_dead_byyear()

    dead=DataFrame(iso=[], continent = [],time_from= [],period =[], dead =[], dead_permil = [])
    for cod  in unique(df_cov.iso_code), year in (Date(2021), Date(2022)) #unique(df_cov.iso_code)
        g = get_cov_bycountry_byperiod(cod, year)[!,[:new_deaths, :new_deaths_per_million]] # :population]]
        # the sum of new deaths is over the given time period, so 
        tmp = describe(g, :mean, sum => :sum).sum
        # ... tmp[1] is the sum of dead for the period and tmp[2] is dhte dead per million in the period
        insert!(dead, nrow(dead)+1, [cod iso2continent[cod] year Year(1) tmp[1] tmp[2] ])
    end
    return dead
end


 dead = count_dead_byyear()

function sc_dead(continent = nothing; dead=dead)
    
    if continent == nothing
        d2022 = filter(:time_from => ==(Date(2022) ) , dead).dead_permil;
        d2021 = filter(:time_from => ==(Date(2021) ) , dead).dead_permil;
        leg = "all"
    else
        mydate=Date(2021)
        function choice(year,ipiros)
            tf = year == mydate
            cont = !ismissing(ipiros) && ipiros == continent 
            return tf && cont
        end
        d2021 = filter([:time_from, :continent] => choice , dead).dead_permil;
        mydate=Date(2022)
        d2022 = filter([:time_from, :continent] => choice , dead).dead_permil;
        #d2021 = filter([:time_from, :continent] => (x,y) -> x==Date(2021) && ( y==(continent) && !smissing(y) ) , dead).dead_permil;
        leg=continent
    end
    return Real.(d2022), Real.(d2021), leg
end

d2022,d2021,leg =  sc_dead()

f=Figure(backgroundcolor = RGBf(0.98, 0.98, 0.98))
ax=Axis(f[1,1],  xlabel="2021",ylabel="2022", title="Scatter") #,label=leg)
sc = scatter!(d2022,d2021, label=leg)
axislegend()


describe(d2021, :min, sum => :sum)

describe(dead)
unique(dead.continent)

ddf = DataFrame(grp=repeat(1:2, 3), x=6:-1:1, y=4:9, z=[3:7; missing], id='a':'f')
df2 = DataFrame(grp=[1, 3], w=[10, 11])
combine(ddf, :z => mean ∘ skipmissing)