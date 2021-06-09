//+------------------------------------------------------------------+
//|                                                CTradeHistory.mqh |
//|                                Copyright 2020, Chamal Abayaratne |
//|                                      https://github.com/ChamalAB |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Chamal Abayaratne"
#property link      "https://github.com/ChamalAB"
#property strict



enum CTRADE_HISTORY_MODES
  {
   CTRADE_LOAD_LIVE, // From account
   CTRADE_LOAD_FILE, // From data file
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTradeHistory
  {
   /*
   This class is used to replicate all Order reading functions
   1. Order selects by pos or ticket
   2. Get order details
   3. Dump data to disk with given filename

   There is a data load limit - currently set 10000 trades!!
   make sure to limit trade size to that number

   This class is set either live mode or file readmode
   Live mode - Class will act as a proxy for above standard orders
   History mode - Class will read data from file and behave just like live mode

   This class does not
   1. Open Trades
   2. Manupulate trades
   */

private:
   CTRADE_HISTORY_MODES accessMode;

   int               orderPointer,ordersTotal,arraySize;

   int               tickets[],oTypes[],magicNums[],openT[],closeT[];
   string            symbols[],comments[],dataFile,separator;
   double            lots[],openP[],closeP[],sls[],tps[],commissions[],swaps[],profits[];

   void              _initializeArrays(void);
   void              _loadFromFile(void);


public:
                     CTradeHistory(CTRADE_HISTORY_MODES mode=CTRADE_LOAD_FILE,
                 string data_file="historyData.csv",
                 string sep=",",
                 int array_size=10000);
   void              dumpToFile(void);

   // proxies
   int               iOrdersHistoryTotal(void);
   bool              iOrderSelect(int index,int select, int pool=MODE_TRADES);
   int               iOrderTicket(void);
   datetime          iOrderOpenTime(void);
   int               iOrderType(void);
   double            iOrderLots(void);
   string            iOrderSymbol(void);
   double            iOrderOpenPrice(void);
   double            iOrderStopLoss(void);
   double            iOrderTakeProfit(void);
   datetime          iOrderCloseTime(void);
   double            iOrderClosePrice(void);
   double            iOrderCommission(void);
   double            iOrderSwap(void);
   double            iOrderProfit(void);
   string            iOrderComment(void);
   int               iOrderMagicNumber(void);
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTradeHistory::CTradeHistory(CTRADE_HISTORY_MODES mode=CTRADE_LOAD_FILE,
                             string data_file="historyData.csv",
                             string sep=",",
                             int array_size=10000)
  {
   accessMode = mode;
   dataFile = data_file;
   arraySize = array_size;
   separator = ",";

   if(accessMode==CTRADE_LOAD_FILE)
     {
      // resize arrays
      _initializeArrays();

      // load data and set ordersTotal
      _loadFromFile();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeHistory::_initializeArrays(void)
  {
   ArrayResize(tickets,arraySize);
   ArrayResize(openT,arraySize);
   ArrayResize(oTypes,arraySize);
   ArrayResize(lots,arraySize);
   ArrayResize(symbols,arraySize);
   ArrayResize(openP,arraySize);
   ArrayResize(sls,arraySize);
   ArrayResize(tps,arraySize);
   ArrayResize(closeT,arraySize);
   ArrayResize(closeP,arraySize);
   ArrayResize(commissions,arraySize);
   ArrayResize(swaps,arraySize);
   ArrayResize(profits,arraySize);
   ArrayResize(comments,arraySize);
   ArrayResize(magicNums,arraySize);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeHistory::_loadFromFile(void)
  {
   int filehandle = FileOpen(dataFile,FILE_READ|FILE_CSV|FILE_ANSI,separator,CP_UTF8);

   if(filehandle==INVALID_HANDLE)
     {
      MessageBox(StringFormat("File %s open failed. LE %d",dataFile,GetLastError()));
      return;
     }
   else
     {
      ordersTotal = 0;
      orderPointer = -1; // default value for invalid selection
      int lastError;
      ResetLastError();

      while(!FileIsEnding(filehandle))
        {
         // read sep to sep
         tickets[ordersTotal] = (int)FileReadNumber(filehandle);
         openT[ordersTotal] = (int)FileReadNumber(filehandle);
         oTypes[ordersTotal] = (int)FileReadNumber(filehandle);
         lots[ordersTotal] = FileReadNumber(filehandle);
         symbols[ordersTotal] = FileReadString(filehandle);
         openP[ordersTotal] = FileReadNumber(filehandle);
         sls[ordersTotal] = FileReadNumber(filehandle);
         tps[ordersTotal] = FileReadNumber(filehandle);
         closeT[ordersTotal] = (int)FileReadNumber(filehandle);
         closeP[ordersTotal] = FileReadNumber(filehandle);
         commissions[ordersTotal] = FileReadNumber(filehandle);
         swaps[ordersTotal] = FileReadNumber(filehandle);
         profits[ordersTotal] = FileReadNumber(filehandle);
         comments[ordersTotal] = FileReadString(filehandle);
         magicNums[ordersTotal] = (int)FileReadNumber(filehandle);

         // increment total counter
         ordersTotal += 1;

         // break if max number s reached
         if(ordersTotal==arraySize)
           {
            MessageBox(StringFormat("Trade limit %d is reached. You may lose some data if you have more than this",arraySize));
            break;
           }

         // check for last errors (if error and break)
         lastError = GetLastError();
         if(lastError!=0)
           {
            MessageBox(StringFormat("File read error %d",lastError));
            ordersTotal = 0;
            break;
           }

         // check if FileIsLineEnding (if not error and break)
         if(!FileIsLineEnding(filehandle))
           {
            MessageBox("File read error DATA_CORRUPT");
            ordersTotal = 0;
            break;
           }
        }
      FileClose(filehandle);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeHistory::dumpToFile(void)
  {
// file dump is disabled in LOAD_FILE mode for obvious reasons!!
   if(accessMode==CTRADE_LOAD_FILE)
      return;

   int histTot = OrdersHistoryTotal();

   if(histTot>0)
     {
      // open file
      int filehandle = FileOpen(dataFile,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI,',',CP_UTF8);
      if(filehandle==INVALID_HANDLE)
        {
         PrintFormat("File %s open failed. LE %d",dataFile,GetLastError());
        }
      else
        {
         int lastError;
         string format = "%d,%d,%d,%.8f,%s,%.8f,%.8f,%.8f,%d,%.8f,%.8f,%.8f,%.8f,%s,%d\r\n";
         StringReplace(format,",",separator);

         for(int i=0; i<histTot; i++)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
              {
               ResetLastError();
               FileWriteString(filehandle,StringFormat(format,
                                                       OrderTicket(),
                                                       (int)OrderOpenTime(),
                                                       OrderType(),
                                                       OrderLots(),
                                                       OrderSymbol(),
                                                       OrderOpenPrice(),
                                                       OrderStopLoss(),
                                                       OrderTakeProfit(),
                                                       (int)OrderCloseTime(),
                                                       OrderClosePrice(),
                                                       OrderCommission(),
                                                       OrderSwap(),
                                                       OrderProfit(),
                                                       OrderComment(),
                                                       OrderMagicNumber()
                                                      ));
               lastError = GetLastError();
               if(lastError!=0)
                 {
                  PrintFormat("Data write error. Order: %d LE: %d",OrderTicket(),lastError);
                 }

              }
            else
              {
               PrintFormat("Order select failed at index %d",i);
              }
           }
         FileClose(filehandle);
        }
     }
   else
     {
      Print("No trades to dump");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CTradeHistory::iOrdersHistoryTotal(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrdersHistoryTotal();
     }

   return ordersTotal;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeHistory::iOrderSelect(int index,int select, int pool=MODE_TRADES)
  {
   /*
   CTRADE_LOAD_FILE mode notes
   If order select return false selected order will not be changed.
   It will remain at last successful order select.
   */
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderSelect(index,select,pool);
     }


// CTRADE_LOAD_FILE mode
   if(pool==MODE_TRADES)
     {
      // in FILE MODE open trades are not supported
      return false;
     }

// If SELECT_BY_TICKET do array search
   if(select==SELECT_BY_TICKET)
     {
      for(int i=0; i<ordersTotal; i++)
        {
         if(tickets[i]==index)
           {
            // search value found
            orderPointer = i;
            return true;
           }
        }
      // search value not found
      return false;
     }
   else
     {
      // SELECT_BY_POS select order pointer
      if(index<ordersTotal)
        {
         orderPointer = index;
         return true;
        }
      else
        {
         return false;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CTradeHistory::iOrderTicket(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderTicket();
     }

   if(orderPointer==-1)
      return -1;
   else
      return tickets[orderPointer];
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CTradeHistory::iOrderOpenTime(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderOpenTime();
     }

   if(orderPointer==-1)
      return 0;
   else
      return openT[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CTradeHistory::iOrderType(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderType();
     }

   if(orderPointer==-1)
      return -1;
   else
      return oTypes[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderLots(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderLots();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return lots[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CTradeHistory::iOrderSymbol(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderSymbol();
     }

   if(orderPointer==-1)
      return "";
   else
      return symbols[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderOpenPrice(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderOpenPrice();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return openP[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderStopLoss(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderStopLoss();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return sls[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderTakeProfit(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderTakeProfit();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return tps[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CTradeHistory::iOrderCloseTime(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderCloseTime();
     }

   if(orderPointer==-1)
      return 0;
   else
      return closeT[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderClosePrice(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderClosePrice();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return closeP[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderCommission(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderCommission();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return commissions[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderSwap(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderSwap();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return swaps[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTradeHistory::iOrderProfit(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderProfit();
     }

   if(orderPointer==-1)
      return 0.00;
   else
      return profits[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CTradeHistory::iOrderComment(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderComment();
     }

   if(orderPointer==-1)
      return "";
   else
      return comments[orderPointer];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CTradeHistory::iOrderMagicNumber(void)
  {
   if(accessMode==CTRADE_LOAD_LIVE)
     {
      // standard function here
      return OrderMagicNumber();
     }

   if(orderPointer==-1)
      return -1;
   else
      return magicNums[orderPointer];
  }
//+------------------------------------------------------------------+
