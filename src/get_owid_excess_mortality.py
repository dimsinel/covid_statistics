from owid import catalog
import pandas as pd

def get_covid_excess_cortality():
    df = catalog.find('excess_mortality', namespace='excess_mortality').load()
    return df

def get_owid_covid_data():
    df = catalog.find('covid', namespace='owid').load()
    # for some reason sometimes the index is multileveled beyond recognition
    if type(df.index) == pd.core.indexes.multi.MultiIndex :
        df.reset_index(inplace=True)
    # julia cannot yet read correctly date format from parquet 
    df['date'].dt.strftime("%Y%m%d").astype(int)

    try:
        df.to_parquet('data/exp_raw/owid-covid-data.parquet')
        print('Saved file data/exp_raw/owid-covid-data.parquet')
    except:
        print("An exception occurred while downloading owid covid data.")

    return 
