import pandas as pd

from sqlalchemy import create_engine

base = 'localhost:5432/db'
name_pass = 'login:password'
pref = 'postgresql'
engine = create_engine(f'{pref}://{name_pass}@{base}')

def moving_average(dateFrom: str, dateTo: str, window_size: int) -> pd.DataFrame:
    SQL = '''
        SELECT
           city.region AS reg,
           recept.ddate AS dd,
           SUM(goods.weight * recgoods.volume) AS s
        FROM city 
           JOIN client ON client.city = city.id 
           JOIN recept ON recept.client = client.id 
           JOIN recgoods ON recgoods.subid = recept.id 
           JOIN goods ON goods.id = recgoods.goods 
        WHERE
            recept.ddate >= %(mindate)s AND recept.ddate <= %(maxdate)s
        GROUP BY city.region, recept.ddate
        ORDER BY city.region, recept.ddate
    '''

    df = pd.read_sql(
        SQL,
        engine,
        params={'mindate': dateFrom, 'maxdate': dateTo},
        parse_dates={'recept.ddate': dict(format='%Y%m%d')}
    )

    N = df.shape[0]
    if (N < window_size):
        raise ValueError(f'Invalid windows size > {N}')
    
    dfs = df.set_index('reg')
    dfs['s'] = dfs['s'].shift(1)
    dfs = dfs.groupby(level='reg').rolling(window=window_size).mean()
    dfs.reset_index(level=[1], inplace=True)
    dfs.reset_index(drop=True, inplace=True)
    names = ['region', 'date', 'sum']
    df.columns = names
    df['prediction'] = dfs['s']
    df.to_sql('prediction', engine, if_exists='replace')

    return df
