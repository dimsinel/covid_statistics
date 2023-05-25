import PyCall

function get_owid_excess_cortality()

    py"""

    from owid import catalog
    import pandas as pd

    def get_owid_excess_cortality():
        df = catalog.find('excess_mortality', namespace='excess_mortality').load()
        return df

        
    """
    return  py"get_owid_excess_cortality"()
end