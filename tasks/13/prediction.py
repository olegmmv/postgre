import pandas as pd

from sqlalchemy import create_engine

base = 'localhost: 5432/db'
name_pass = 'login:password'
pref = 'postgresql'
engine = create_engine(f'{pref}://{name_pass}@{base}')

def moving_average(dateFrom: str, dateTo: str, window_size: int) -> pd.DataFrame:
    SQL = '''
        SELECT
           city.region,
           recept.ddate,
           SUM(goods.weight * recgoods.volume) AS s
        FROM city 
           JOIN client ON client.city = city.id 
           JOIN recept ON recept.client = client.id 
           JOIN recgoods ON recgoods.subid = recept.id 
           JOIN goods ON goods.id = recgoods.goods 
        WHERE
            recept.ddate >= %(mindate)s AND recept.ddate <= %(maxdate)s
        GROUP BY city.region, recept.ddate
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

    moving_average = df['s'].rolling(window=window_size).mean()
    names = ['region', 'date', 'sum']
    df.columns = names
    df['prediction'] = moving_average
    df.to_sql('prediction', engine, if_exists='replace')

    return df