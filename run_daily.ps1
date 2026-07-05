Set-Location "D:\prix-carburant-France"
& "C:\Python313\python.exe" "ingestion\api\fetch_fuel_prices.py"
Set-Location "D:\prix-carburant-France\dbt"
& "C:\Users\Souleymane\AppData\Roaming\Python\Python313\Scripts\dbt.exe" run --select silver+
& "C:\Users\Souleymane\AppData\Roaming\Python\Python313\Scripts\dbt.exe" test