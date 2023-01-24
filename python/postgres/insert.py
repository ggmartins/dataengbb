import psycopg2 as pg
import csv

file = r'data.csv'
sql_insert_speedtest = """INSERT INTO speedtest(time, deviceid, tool, direction,
                       protocol, target, zip, isp, value)
                       VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s)"""
try:
    conn = pg.connect(user="postgres",
        password="",
        host="",
        port="5432",
        database="")
    cursor = conn.cursor()
    with open(file, 'r') as f:
        reader = csv.reader(f)
        next(reader) # This skips the 1st row which is the header.
        for record in reader:
            cursor.execute(sql_insert_speedtest, record)
            conn.commit()
except (Exception, pg.Error) as e:
    print(e)
finally:
    if (conn):
        cursor.close()
        conn.close()
        print("Connection closed.")
