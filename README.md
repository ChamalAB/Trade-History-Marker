### Trade History Marker 1.10 - script for MT4
[download at mql5.com](https://www.mql5.com/en/code/29964)

**Version 1.10**

- Mark historical trades from your own MT4 account.
- Mark historical trades from another account. (Load CSV file).  
- Save historical data to share.
- Time filter
- Order type filter  
- Customizable visual elements by color and style.
- Tool-tip information (Loss or profit,Profit,lot size, order comment)  

**Instructions / examples**  

1. If you need to visualize your EURUSD past trades, simply execute the script on EURUSD chart(Any time frame).
2. In "From account" mode it will only mark trades which are visible in your "Account History" tab. To view all trades make sure to select "Show all" option in "Account History".
3. In "From data file"mode it will mark trades loaded from the csv file in "DATA_FOLDER\MQL4\historyData.csv" file.
4. To share your stats with someone else, set
Data source - From account
Save history to file ? - true
And share the script and the csv file with your friend !!.  
5. Only entries and exits are marked by default. SL and TP markings can be enabled in settings.
