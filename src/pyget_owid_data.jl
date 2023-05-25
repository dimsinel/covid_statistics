import PyCall

function get_owid_excess_mortality()

    py"""
    from owid import catalog
    import pandas as pd

    def get_owid_excess_mortality():
        df = catalog.find('excess_mortality', namespace='excess_mortality').load()
        # julia cannot yet read correctly date format from parquet 
        df['date'] = df['date'].dt.strftime("%Y%m%d").astype(int)
        try:
            df.to_parquet('data/exp_raw/owid_excess_mortality.parquet')
            print('Saved file data/exp_raw/owid_excess_mortality')
        except:
            print("An exception occurred while downloading owid mortality data.")
        return

        
    """
    py"get_owid_excess_mortality"()
 
end
 
function read_owid_excess_mortality()
    df = datadir("exp_raw/owid_excess_mortality.parquet") |> Parquet.read_parquet |> DataFrame
    # the fuckedup date...
    df.date  = @. Date( string(df.date), dateformat"yyyymmdd" )
    return df
end


######################################33
function get_owid_pop_data()
# 
    py"""
    from owid import catalog
    import pandas as pd

    def get_owid_pop_data():
        df = catalog.find('population', namespace='owid').iloc[0].load()
        
        try:
            df.to_parquet('data/exp_raw/owid-pop-data.parquet')
            print('Saved file data/exp_raw/owid-pop-data.parquet')
        except:
            print("An exception occurred while downloading owid population data.")

        return 

        
    """
    py"get_owid_pop_data"()

    #df = Parquet.read_parquet(datadir("exp_raw/owid-pop-data.parquet")) |> DataFrame

end

function read_owid_pop_data()

    df = datadir("exp_raw/owid-pop-data.parquet") |> Parquet.read_parquet |> DataFrame ;
    # this contains a LOT of years. Only keep a few 
    filter!(:year => x-> 2019 <= x <= 2023, df)
    return df

end

###############################################################
# we can get them over csv but it is slow
# url_megadatafile = "https://covid.ourworldindata.org/data/owid-covid-data.csv"
# df_cov = HTTP.get(url_megadatafile).body |> CSV.File  |> DataFrame
# CSV.write( datadir("exp_raw/owid-covid-data.csv"), df_cov )

function get_owid_covid_data()
# there is a problem w/ the pandas dataframe of owid dont use
    py"""
    from owid import catalog
    import pandas as pd

    def get_owid_covid_data():
        df = catalog.find('covid', namespace='owid').load()
        # for some reason sometimes the index is multileveled beyond recognition
        if type(df.index) == pd.core.indexes.multi.MultiIndex :
            df.reset_index(inplace=True)
        # julia cannot yet read correctly date format from parquet 
        df['date'] = df['date'].dt.strftime("%Y%m%d").astype(int)
        
        try:
            df.to_parquet('data/exp_raw/owid-covid-data.parquet')
            print('Saved file data/exp_raw/owid-covid-data.parquet')
        except:
            print("An exception occurred while downloading owid covid data.")

        return 

        
    """
    py"get_owid_covid_data"()
 
end
    
    
    
function read_owid_covid_data()
  
    df = Parquet.read_parquet(datadir("exp_raw/owid-covid-data.parquet")) |> DataFrame
    # the fuckedup date...
    df.date  = @. Date( string(df.date), dateformat"yyyymmdd" ) # Year( div(df.date,10000) ), Month( div(df.date,100)%100 ), Day( df.date%100 ) )
    return df
 
end
####################################################33

function get_hmd_stmd(downl::Bool)

    url = "https://www.mortality.org/File/GetDocument/Public/STMF/Outputs/stmf.csv"
    if downl
        try
            #url = "https://www.mortality.org/File/GetDocument/Public/STMF/Outputs/stmf.xlsx"
            df_hmd = CSV.File(HTTP.get(url).body ; header=2) |> DataFrame
            # "Column whose `eltype` is String7 is not supported at this stage" by parquet.
            df_hmd.Sex = convert.(Char, df_hmd.Sex)
            df_hmd.CountryCode = convert.(String, df_hmd.CountryCode)
            parquet_file = joinpath( "exp_raw","df_hmd.parquet")
            write_parquet(datadir( parquet_file ), df_hmd )
            println("downloaded and wrote to file hdm stfm data in $(datadir( parquet_file ) ) ")
            return df_hmd
        catch
            println("Could not read hdm stfm dat from inet. Reverting to locally saved file")
        end
    end
    df_hmd = datadir( joinpath( "exp_raw","df_hmd.parquet" ) ) |> read_parquet |> DataFrame
    return df_hmd
end