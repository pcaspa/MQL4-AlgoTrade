//+------------------------------------------------------------------+
//|                                                    Simple Copier |
//+------------------------------------------------------------------+
#property copyright   "Surmount AI"
#property link        ""
#property version     "0.12"
#property description "Disclaimer: Trading with this EA may result in a substantial or complete loss of funds.  These losses may even exceed your initial margin deposit."
#property description "\nBy using this EA, you agree to hold the publisher (seller) and everybody who is involved in the production, development, distribution free of any responsibility. Any live trading you do, you are doing at your own discretion and risk."
#property description "\nHistorical performance of a trading system or strategy cannot be indicative of future results."

#property strict
//+------------------------------------------------------------------+
//| Enumerator of working mode                                       |
//+------------------------------------------------------------------+
enum copier_mode
  {
   master,
   slave,
  };
  

input copier_mode mode=0;  // Working mode
input int slip=10;         // Slippage (in pips)
extern double Lots = 0;  // Lot size 
input double Multi=0;     // Multiplyer
extern double Risk = 0;  //Risk % 
input string authToken = "eyJhbGciOiJIUzI1NiJ9.NjBkMWY0ZDIxNjUzZjYzMmRjMDJhYzcw.VlraElqzBlvjqJCsdNlW942ocwKeqpIPxE-OuZF0NSs";
input string host =   "dev.surmountfinance.com";
input string CaptureSymbols = "EURUSD,GBPUSD,EURCHF";
//input int QuantModelPostPrefix = "SF1";
input string QuantModelID0 = "QMID702"; 
input string QuantModelID1 = "QMID712,4445555,4445555";
input string QuantModelID2 = "QMID722,4448000,4448000";
input string QuantModelID3 = "QMID732,445000,445000";
input string QuantModelID4 = "QMID742,10000,10010";
input string QuantModelID5 = "Name,Magic Number Start,Magic Number End";
input string QuantModelID6 = "Name,Magic Number Start,Magic Number End";
input string QuantModelID7 = "Name,Magic Number Start,Magic Number End";
input string QuantModelID8 = "Name,Magic Number Start,Magic Number End";
input string QuantModelID9 = "Name,Magic Number Start,Magic Number End";
input string QuantModelID10 = "Name,Magic Number Start,Magic Number End";

int
opened_list[500],
ticket,
type,
filehandle,
LoadedSymbols,
GETOrders,
bc,
breakcnt,
LastLostSig,
MaxAge=5000,
OpenPos;

string
TradeCmt,symbol,TradeCode="X3MA_EA2.0",
CaptureTFStr,LastHistPost,LastSignal,
GETresult[],CaptureSymb[500];

double
lot,
price,
sl,
tp;

ENUM_ORDER_TYPE eOrderType;
   

string GETOrderSymbol[100], GETOrderComment[100], GETOrderType[100], quantModelID[100];
int GETOrderTicket[100],GETOrderMagicNumber[100];
double GETOrderLots[100], GETOrderPrice[100], GETOrderTP[100], GETOrderSL[100], GETOrderTime[100], GETOriginBalance[100], GETOriginEquity[100];
string GET1stOrderType[100];
double GET1stOrderTime[100];

datetime prevTimeCurrent=TimeCurrent();

//+------------------------------------------------------------------+
//|Initialisation function                                           |
//+------------------------------------------------------------------+          
void init()
  {
   ObjectsDeleteAll();
   if(EnumToString(mode)=="master") EventSetTimer(20);
   if(EnumToString(mode)=="slave") EventSetTimer(15);
   
   
   //--- Load Symbols to Capture    ----------------------------
   
   int findComma=0;
   int findStart=0;
   
   do
     {
      findComma = StringFind(CaptureSymbols+",",",",findStart);
      if(findComma>0){
         LoadedSymbols=LoadedSymbols+1;
         CaptureSymb[LoadedSymbols]=StringSubstr(CaptureSymbols,findStart,findComma-findStart);
         findStart=findComma+1;         
      }
     }
   while(findComma>0);
       
   return;
   
   
   
  }
//+------------------------------------------------------------------+
//|Deinitialisation function                                         |
//+------------------------------------------------------------------+
void deinit()
  {
   ObjectsDeleteAll();
   EventKillTimer();
   Comment("");
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  OnTimer()  //OnTick() //
  {
   
   if (TimeCurrent() > prevTimeCurrent){
      prevTimeCurrent=TimeCurrent();
      
      MasterMode();
   
      if (isNewBar()==true){
         //PostSignal("QMID","EURUSD", 1543546656, 1, 220.94, 230,210, 1569470400, 10907, 10874, "Free Text for Comment", "444","MarketBuy");
         
         //GetSignal("qmid127?status=open"); //?status=open
         //CapturePriceHist();
         //PostPriceHist("EURUSD", "M1",100,101,98, 99, 1569470400,1, "quantModelID");
         
      }
      
      if(TradeCmt=="Market Closed")TradeCmt="";
      
      
   }else{
      TradeCmt="Market Closed";
   }
   
   ChartComment();

  }
  
void ChartComment()  
   {
   
      string cmt;
      
      cmt = "\n     --------------------------------------------------------------------------------";
      
      cmt=cmt+"\n        Surmount Finance Trade Copier and Data Capture";
      
      cmt=cmt+"\n     --------------------------------------------------------------------------------";
      cmt=cmt+"\n     Operating Mode  :  "+EnumToString(mode);
      cmt=cmt+"\n     GMT Time         :  "+TimeToStr(TimeGMT(),TIME_MINUTES)+"  Server Time: "+TimeToStr(TimeCurrent(),TIME_MINUTES);
      cmt=cmt+"\n     Spread               : "+DoubleToString((Ask-Bid)/Point,0);
      cmt=cmt+"\n     Last History Post : "+LastHistPost;
      cmt=cmt+"\n     Last Signal          : "+LastSignal;
      if(breakcnt>0) cmt=cmt+"\n     Lost Signal          : "+breakcnt+"   "+LastLostSig;
      cmt=cmt+"\n     Open Positions    : "+OpenPos;
      if(TradeCmt!="") cmt=cmt+"\n\n     Comment           : "+TradeCmt;
      

   
   
   
   for (int j=3;j<=30;j++)
      {
         drawFixedLbl("bg"+IntegerToString(j)+"_"+TradeCode, "  gggggggggggggggggggggggggggggggggggggg", 0, 1, j*6, 5, "Webdings",Navy, false);
         drawFixedLbl("bg2"+IntegerToString(j)+"_"+TradeCode, "  gggggggggggggggggggggggggggggggggggggg", 0, 1+5, j*6+5, 5, "Webdings",Gray, true);
      }
      
      Comment(cmt);

   }    
   
   
void CapturePriceHist()
{


for(int i=1; i<=LoadedSymbols; i++)
   {
      PostPriceHist(CaptureSymb[i], PERIOD_CURRENT,iClose(CaptureSymb[i],PERIOD_CURRENT,1),iHigh(CaptureSymb[i],PERIOD_CURRENT,1),iLow(CaptureSymb[i],PERIOD_CURRENT,1), iOpen(CaptureSymb[i],PERIOD_CURRENT,1), TimeGMT(),iVolume(CaptureSymb[i],PERIOD_CURRENT,1), "quantModelID");      
   }

}



  
void MasterMode()    
  {
   Print("Start-----------------------------------------------------------------------------------");
   int MNStart,MNEnd,Actioned;
   string QMID,QMP;
   OpenPos=0;
   
   for (int qm=0;qm<=10;qm++) {
   
      if(qm==0)QMP=QuantModelID0+",0,0";
      if(qm==1)QMP=QuantModelID1;
      if(qm==2)QMP=QuantModelID2;
      if(qm==3)QMP=QuantModelID3;
      if(qm==4)QMP=QuantModelID4;
      if(qm==5)QMP=QuantModelID5;
      if(qm==6)QMP=QuantModelID6;
      if(qm==7)QMP=QuantModelID7;
      if(qm==8)QMP=QuantModelID8;
      if(qm==9)QMP=QuantModelID9;
      if(qm==10)QMP=QuantModelID10;
      
      int findComma=0;
      int findStart=0;
      
      findComma = StringFind(QMP,",",0);
      QMID=StringSubstr(QMP,findStart,findComma);
      findStart=findComma+1;  
      findComma = StringFind(QMP,",",findStart);
      MNStart= StringToInteger(StringSubstr(QMP,findStart,findComma-findStart));
      findStart=findComma+1;  
      findComma = StringFind(QMP,",",findStart);
      MNEnd= StringToInteger(StringSubstr(QMP,findStart,findComma-findStart));
   
      //Print(qm,QMID,MNStart,MNEnd);
      if(QMID!="Name"){
      
         if(GetSignal(QMID+"?status=open")!=1) {breakcnt=breakcnt+1;LastLostSig=TimeToStr(TimeCurrent(),TIME_MINUTES);Print("Break ");break;} //+"?status=open"
         
         int OrderFound;
         for(int Orders=0;Orders<GETOrders;Orders++)
         {
            OrderFound=0; //else{OrderFound=1;}
            for (int trade = OrdersTotal() - 1; trade >= 0; trade--){
               
               if (OrderSelect(trade, SELECT_BY_POS, MODE_TRADES)) {
                  if( OrderMagicNumber() >= MNStart  && OrderMagicNumber() <= MNEnd){
                     if (EnumToString(mode)=="master" && OrderTicket()==GETOrderTicket[Orders]){
                        OrderFound=1;
                        if(OrderType() != GETOrderType[Orders]){
                           //FIX ME   if (OrderType() == OP_SELL) {}
                        }
                        if(OrderOpenPrice() != GETOrderPrice[Orders] || OrderTakeProfit() != GETOrderTP[Orders] || OrderStopLoss() != GETOrderSL[Orders]){
                           PostSignal(QMID,GETOrderSymbol[Orders], GETOrderTicket[Orders], 0, OrderOpenPrice(), OrderTakeProfit(),OrderStopLoss(), TimeGMT(), 0, 0, GETOrderComment[Orders], GETOrderMagicNumber[GETOrders],"ORDER-MODIFY");                        
                        }
                     }
                     if (EnumToString(mode)=="slave" && OrderComment()==QMID+"-"+GETOrderTicket[Orders]){
                        OrderFound=1;
                        if(GETOrderType[Orders]=="ORDER-MODIFY" && ( OrderTakeProfit() != GETOrderTP[Orders] || OrderStopLoss() != GETOrderSL[Orders])){
                           if(!OrderModify(OrderTicket(),GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],0)) Print(QMID+" "+GETOrderSymbol[Orders]+" Error: ",GetLastError()," during modification of the order. OP/SL/TP:",GETOrderPrice[Orders]+", "+GETOrderSL[Orders]+", "+GETOrderTP[Orders]); 
                        }
                      }
                                                                 
                   }
              }
               } 
           
              if(OrderFound==0){
                 Print("Not Found "+GETOrderSymbol[Orders]+" "+GETOrderType[Orders]);
                 if(EnumToString(mode)=="master" & GETOrderTime[Orders]-GET1stOrderTime[Orders]>60 ) PostSignal(QMID,GETOrderSymbol[Orders], GETOrderTicket[Orders], GETOrderLots[Orders], GETOrderPrice[Orders], GETOrderTP[Orders],GETOrderSL[Orders], TimeGMT(), 0, 0, GETOrderComment[Orders],GETOrderMagicNumber[GETOrders], "Closed");
                 if(EnumToString(mode)=="slave"){
                  Print(GETOrderType[Orders]);
                     if( TimeGMT()-GETOrderTime[Orders]<MaxAge ){
                        if(GETOrderType[Orders]=="ORDER-MODIFY" && TimeGMT()-GET1stOrderTime[Orders]<MaxAge) {
                           GETOrderTime[Orders]=GET1stOrderTime[Orders];
                           GETOrderType[Orders]=GET1stOrderType[Orders];
                           Print("ORDER-MODIFY Found without OPEN - Changed to OPEN");
                        }
                        Print("Not Found "+GETOrderSymbol[Orders]+" "+GETOrderType[Orders]);
                        if(GETOrderType[Orders]=="ORDER_TYPE_BUY") OpenMarketOrder(GETOrderTicket[Orders],GETOrderSymbol[Orders],0,GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],GETOrderLots[Orders],QMID,MNStart);
                        if(GETOrderType[Orders]=="ORDER_TYPE_SELL") OpenMarketOrder(GETOrderTicket[Orders],GETOrderSymbol[Orders],1,GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],GETOrderLots[Orders],QMID,MNStart);
                        if(GETOrderType[Orders]=="ORDER_TYPE_BUY_LIMIT") OpenPendingOrder(GETOrderTicket[Orders],GETOrderSymbol[Orders],2,GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],GETOrderLots[Orders],QMID,MNStart);
                        if(GETOrderType[Orders]=="ORDER_TYPE_SELL_LIMIT") OpenPendingOrder(GETOrderTicket[Orders],GETOrderSymbol[Orders],3,GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],GETOrderLots[Orders],QMID,MNStart);
                        if(GETOrderType[Orders]=="ORDER_TYPE_BUY_STOP") OpenPendingOrder(GETOrderTicket[Orders],GETOrderSymbol[Orders],2,GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],GETOrderLots[Orders],QMID,MNStart);
                        if(GETOrderType[Orders]=="ORDER_TYPE_SELL_STOP") OpenPendingOrder(GETOrderTicket[Orders],GETOrderSymbol[Orders],3,GETOrderPrice[Orders],GETOrderSL[Orders],GETOrderTP[Orders],GETOrderLots[Orders],QMID,MNStart);
                        Actioned=1;
                        if(GETOrderType[Orders]=="ORDER-MODIFY") {
                           Print("ORDER-MODIFY Found without OPEN");Actioned=0;
                        }else{
                           Print("Slave Order Sent");
                        }
                     }else{
                        Print(GETOrderSymbol[Orders] +" order too old");
                     }
                 }
               }
                         
          } 
          
          
          //************************************************************ 
          if(Actioned==0){
             for (int trade = OrdersTotal() - 1; trade >= 0; trade--){
                OrderFound=0;
                if (OrderSelect(trade, SELECT_BY_POS, MODE_TRADES)) {
                  //Print(OrderMagicNumber() , MNStart  , MNEnd);
                    if( OrderMagicNumber() >= MNStart  && OrderMagicNumber() <= MNEnd){
                        //Print(OrderMagicNumber() , MNStart  , MNEnd);
                        for(int Orders=0;Orders<GETOrders;Orders++) {
                           if (EnumToString(mode)=="master" && OrderTicket()==GETOrderTicket[Orders]) OrderFound=1;
                           if (EnumToString(mode)=="slave" && OrderComment()==QMID+"-"+GETOrderTicket[Orders]) OrderFound=1;
                        }
                        
                     }else{OrderFound=1;}   
                }
                if(OrderFound==0) {
                    eOrderType = OrderType();
                    if(EnumToString(mode)=="master")PostSignal(QMID,OrderSymbol(), OrderTicket(), OrderLots() , OrderOpenPrice(), OrderTakeProfit(),OrderStopLoss(), TimeGMT(), 0, 0, QMID, MNStart,EnumToString(eOrderType)); 
                    if(EnumToString(mode)=="slave"){
                        Print("Slave Order Close");
                         if(OrderType()==0)
                          {
                           if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),slip)) Print("Error: ",GetLastError()," during closing the order.");
                           LastSignal=TimeToStr(TimeCurrent(),TIME_MINUTES);
                          }
                        else if(OrderType()==1)
                          {
                           if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),slip))Print("Error: ",GetLastError()," during closing the order.");
                           LastSignal=TimeToStr(TimeCurrent(),TIME_MINUTES);
                          }
                        else if(OrderType()>1)
                          {
                           if(!OrderDelete(OrderTicket())) Print("Error: ",GetLastError()," during deleting the pending order.");
                           LastSignal=TimeToStr(TimeCurrent(),TIME_MINUTES);
                          }
                    
                                         
                    }
               }
             }
          }    
        }
      }
   }
   


  
//+------------------------------------------------------------------+
//|Checking list                                                     |
//+------------------------------------------------------------------+
int InList(int ticket_)
  {
   int h=0;

   while(opened_list[h]!=0)
     {
      if(opened_list[h]==ticket_) return(1);
      h++;
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|Open market execution orders                                      |
//+------------------------------------------------------------------+
void OpenMarketOrder(int ticket_,string symbol_,int type_,double price_,double SL_,double TP_,double lot_, string QMID, int Magic )
  {
   Print("OpenMarketOrder "+ticket_+","+symbol_+","+ type_+","+ price_+","+ SL_+","+ TP_+","+ lot_+","+ QMID+","+ Magic );
   
   double CalcLot=CalcLots(symbol_,lot_, type_, price_, SL_);
   
   LastSignal=TimeToStr(TimeCurrent(),TIME_MINUTES);
   double market_price=MarketInfo(symbol_,MODE_BID);
   if(type_==0) market_price=MarketInfo(symbol_,MODE_ASK);

   //double delta;

   //delta=MathAbs(market_price-price_)/MarketInfo(symbol_,MODE_POINT);
   //if(delta>slip) {Print("Excess Slippage - Market Order Not Openned");return;}

   if(!OrderSend(symbol_,type_,LotNormalize(CalcLot),market_price,slip,SL_,TP_,QMID+"-"+IntegerToString(ticket_),Magic )) Print("Error: ",GetLastError()," during opening the market order.");
   
   
   
   return;
  }
//+------------------------------------------------------------------+
//|Open pending orders                                               |
//+------------------------------------------------------------------+
void OpenPendingOrder(int ticket_,string symbol_,int type_,double price_,double SL_,double TP_,double lot_, string QMID , int Magic)
  {
  
   Print("OpenMarketOrder "+ticket_+","+symbol_+","+ type_+","+ price_+","+ SL_+","+ TP_+","+ lot_+","+ QMID+","+ Magic );
   
   LastSignal=TimeToStr(TimeCurrent(),TIME_MINUTES);
   double CalcLot=CalcLots(symbol_, lot_, type_, price_, SL_);
  
   
   if(!OrderSend(symbol_,type_,LotNormalize(CalcLot),price_,slip,SL_,TP_,QMID+"-"+IntegerToString(ticket_) ,Magic )) Print("Error: ",GetLastError()," during setting the pending order.");
   
   
   return;
  }
//+------------------------------------------------------------------+
//|Normalize lot size                                                |
//+------------------------------------------------------------------+
double LotNormalize(double lot_)
  {
   double minlot=MarketInfo(symbol,MODE_MINLOT);

   if(minlot==0.001)      return(NormalizeDouble(lot_,3));
   else if(minlot==0.01)  return(NormalizeDouble(lot_,2));
   else if(minlot==0.1)   return(NormalizeDouble(lot_,1));

   return(NormalizeDouble(lot_,0));
  }
//+------------------------------------------------------------------+

bool isNewBar()
  {
   static datetime TimeBar=0;
   bool flag=false;
    if(TimeBar!=Time[0])
       {
        TimeBar=Time[0];
        flag=true;
       } 
    return (flag);
  }

//+------------------------------------------------------------------+

void drawFixedLbl(string objname, string s, int Corner, int DX, int DY, int FSize, string Font, color c, bool bg)
{
   if (ObjectFind(objname) < 0) {ObjectCreate(objname, OBJ_LABEL, 0, 0, 0);}   
   ObjectSet(objname, OBJPROP_CORNER, Corner);
   ObjectSet(objname, OBJPROP_XDISTANCE, DX);
   ObjectSet(objname, OBJPROP_YDISTANCE, DY);
   ObjectSet(objname,OBJPROP_BACK, bg);      
   ObjectSetText(objname, s, FSize, Font, c);
}

//+------------------------------------------------------------------+


int PostSignal( string quantModelID, string feedSymbol, int feedOrderTicket,double feedOrderVolume, double feedOrderPrice, double feedOrderTP, double feedOrderSL, int feedOrderTime, double feedOriginBalance, double feedOriginEquity, string feedOrderComment , string feedrefId, string feedOrderType)
{
   
     
   double CalcLot;
      
   if(feedOrderType=="ORDER_TYPE_BUY" || feedOrderType=="OP_BUYLIMIT" || feedOrderType=="OP_BUYLIMIT")CalcLot=CalcLots(feedSymbol,feedOrderVolume, 0, feedOrderPrice, feedOrderSL);
   if(feedOrderType=="ORDER_TYPE_SELL" || feedOrderType=="OP_SELLIMIT" || feedOrderType=="OP_SELLIMIT")CalcLot=CalcLots(feedSymbol,feedOrderVolume, 0, feedOrderPrice, feedOrderSL);
  
    
   int digitsQty = 10;

   uchar   post[],result[];    
   string ResponseHeaders; 
   string protocol = "http://";
	string url = "dev.surmountfinance.com/api/v1/";
	string uri = "signals/"+quantModelID;
	
	Print("QMID:",quantModelID);
	
   string strPost = "{ \"symbol\": \"" + feedSymbol + "\", \"orderTicket\": " + IntegerToString(feedOrderTicket)  +     ", \"orderVolume\": " + DoubleToString(CalcLot, digitsQty) + ", \"orderPrice\": " + DoubleToString (feedOrderPrice, digitsQty) + ", \"orderTP\":" 
						+ DoubleToString(feedOrderTP, digitsQty) + 
                    ", \"orderSL\": "+ DoubleToString(feedOrderSL, digitsQty) + ", \"time\": " + IntegerToString(feedOrderTime) + ", \"originBalance\": " + DoubleToString(feedOriginBalance, digitsQty) + ", \"originEquity\": " 
						+ DoubleToString(feedOriginEquity, digitsQty) + ", \"orderComment\": \"" + feedOrderComment + "\", \"refId\": \"" + feedrefId + "\", \"orderType\": \"" + feedOrderType + "\""
						+     "}";
	Print("Post "+strPost);
	
   ArrayResize(post, StringToCharArray(strPost, post)-1);

   string req_Header= "HTTP:/1.1\n\rAuthorization: Bearer "+authToken+"\n\rContent-Type: text/plain";

   int res=WebRequest("POST",(protocol+url+uri),req_Header, 10000,post,result,ResponseHeaders);

   //Print("Just sent webrequest to SurmountFinance \n\r"); 
   //Print("endpoint: \n\r ", ((url)) , "\n\r");
   //Print("WebRequest response code ",res, "\n\r" ); 
   //Print("Response header: \n\r ", ResponseHeaders, "\n\r"	        );
   //Print("Response Body: \n\r ", CharArrayToString(result)	        );


      if(res==-1)
        {
         Print("Authentication was blocked, incorrect or unauthorized use by user. Code  =",GetLastError());
         //--- Perhaps the URL is not listed, display a message about the necessity to add the address
         //MessageBox("To allow EA Operation, Add the address '"+ host +"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
			//return returnResponse;
        }
      else
        {
         if(res==200)
           {
				//returnResponse.Deserialize(result);  
				//return returnResponse;  
				Print("POST OK");
				LastSignal=TimeToStr(TimeCurrent(),TIME_MINUTES);
           }
         else
           {
            PrintFormat("Connecting to '%s' failed, code %d , EA Not Authenticated to operate on this session.",url,res);
            Print("Headers ", ResponseHeaders);
            Print("Result from API ", CharArrayToString(result));
  			   //return returnResponse;
           }
        }
   return 0;
}

int GetSignal( string quantModelID)
{

  
   int digitsQty = 10;
   string resultstring;

   uchar   post[],result[];    
   string ResponseHeaders; 
   //string host =   "dev.surmountfinance.com";
   //string url = "http://"+ host +"/api/v1/HistoryDropFeed/" + feedSymbol + "/" + feedTimeFramestr;
   string protocol = "http://";
	string url = "dev.surmountfinance.com/api/v1/";
	string uri = "signals/"+quantModelID;
	
   string req_Header= "HTTP:/1.1\n\rAuthorization: Bearer "+authToken+"\n\rContent-Type: text/plain";
   //Print("Request Header: \n\r", req_Header);


   //int res=WebRequest("POST",url,req_Header, 10000, post, result, ResponseHeaders);
   int res=WebRequest("GET",(protocol+url+uri),req_Header, 10000,post,result,ResponseHeaders);

      if(res==-1)
        {
         Print("Authentication was blocked, incorrect or unauthorized use by user. Code  =",GetLastError());
        }
      else
        {
         if(res==200)
           {
				resultstring = CharArrayToString(result);
			   Print("GET OK:",quantModelID);
				deJSON(resultstring);
				return 1;
           }
         else
           {
            PrintFormat("Connecting to '%s' failed, code %d , EA Not Authenticated to operate on this session.",url,res);
            Print("Headers ", ResponseHeaders);
            Print("Result from API ", CharArrayToString(result));
  			   //return returnResponse;
           }
        }
   return 0;
}

int PostPriceHist(string feedSymbol, int feedTimeFrame,double feedClose,double feedHigh,double feedLow, double feedOpen, int feedTime,double feedVolume, string quantModelID)
{
// POST price feed to Surmount finance REST API

   string feedTimeFramestr="M1";
   if(feedTimeFrame==1)feedTimeFramestr="M1";
   if(feedTimeFrame==5)feedTimeFramestr="M5";
   if(feedTimeFrame==15)feedTimeFramestr="M15";
   if(feedTimeFrame==30)feedTimeFramestr="M30";
   if(feedTimeFrame==60)feedTimeFramestr="H1";
   if(feedTimeFrame==240)feedTimeFramestr="H4";
   if(feedTimeFrame==1440)feedTimeFramestr="D1";
   if(feedTimeFrame==10080)feedTimeFramestr="W1";
   if(feedTimeFrame==43200)feedTimeFramestr="MN1";

	int digitsQty = 10;
   
   uchar   post[],result[];    
   string ResponseHeaders; 
   //string host =   "dev.surmountfinance.com";
   //string url = "http://"+ host +"/api/v1/HistoryDropFeed/" + feedSymbol + "/" + feedTimeFramestr;
   string protocol = "http://";
	string url = "dev.surmountfinance.com/api/v1/";
	string uri = "HistoryDropFeed/"+feedSymbol+"/"+ feedTimeFramestr;
   //string strPost = "{ \"dataSource\": [ { \"Volume\": 20730608  }  ]}";
   //string strPost = "{ 'dataSource': [ { 'close': " + DoubleToString(feedClose,digitsQty) + ", 'high': " + DoubleToString(feedHigh,digitsQty) + ", 'low': " + DoubleToString(feedLow, digitsQty) + ", 'open': " + DoubleToString(feedOpen , digitsQty) + ", 'time': " + IntegerToString(feedTime)+ ", 'volume': " + DoubleToString(feedVolume, digitsQty)  + " } ] }";
   string strPost = " { \"close\": " + DoubleToString(feedClose,digitsQty) + ", \"high\": " + DoubleToString(feedHigh,digitsQty) + ", \"low\": " + DoubleToString(feedLow, digitsQty) + ", \"open\": " + DoubleToString(feedOpen , digitsQty) + ", \"time\": " + IntegerToString(feedTime)+ ", \"volume\": " + DoubleToString(feedVolume, digitsQty)  + " } ";
   //string strPost = "{\n\r\"close\": 100\n\r}";
   //string strPost = StringConcatenate("{","\"close\"",": 10 }");
   //strPost = " {\"close\": 219.89,\"high\": 220.94,\"low\": 218.83,\"open\": 220,\"time\": 1569470402,\"volume\": 208 } ";		
   
   
   
   //Print("About to send webrequest to: \n\r ",  url );
   //Print("Request Body: \n\r", strPost );
   //StringToCharArray(strPost,post);
   ArrayResize(post, StringToCharArray(strPost, post)-1);
   string req_Header=   "HTTP/1.1\n\r" + 
                        "Authorization: Bearer "+authToken+"\n\r" +
                        //"Content-Type: application/json\n\r"; 
                        "Content-Type: text/plain\n\r"; 
                        
                        //"Content-Length: " + IntegerToString(ArraySize(post)) + "\n\r" +
                        //"Host: " + host + "\n\r"
								//"quantModelId: " + quantModelID + "\n\r";
   req_Header= "HTTP:/1.1\n\rAuthorization: Bearer eyJhbGciOiJIUzI1NiJ9.NjBkMWY0ZDIxNjUzZjYzMmRjMDJhYzcw.VlraElqzBlvjqJCsdNlW942ocwKeqpIPxE-OuZF0NSs\n\rContent-Type: text/plain";
   //Print("Request Header: \n\r", req_Header);


   //int res=WebRequest("POST",url,req_Header, 10000, post, result, ResponseHeaders);
   int res=WebRequest("POST",(protocol+url+uri),req_Header, 10000,post,result,ResponseHeaders);
   //int res=WebRequest("POST", url, NULL, req_Header, 10000, post, ArraySize(post), result, ResponseHeaders);
   //int res=WebRequest("POST", url, req_Header, 10000, post, result, ResponseHeaders);
     
   
   //int res=0;

   //Print("Just sent webrequest to SurmountFinance \n\r"); 
   //Print("endpoint: \n\r ", ((url)) , "\n\r");
   //Print("WebRequest response code ",res, "\n\r" ); 
   //Print("Response header: \n\r ", ResponseHeaders, "\n\r"	        );
   //Print("Response Body: \n\r ", CharArrayToString(result)	        );


      if(res==-1)
        {
         Print("Authentication was blocked, incorrect or unauthorized use by user. Code  =",GetLastError());
         //--- Perhaps the URL is not listed, display a message about the necessity to add the address
         //MessageBox("To allow EA Operation, Add the address '"+ host +"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
			//return returnResponse;
        }
      else
        {
         if(res==200)
           {
            LastHistPost=TimeToStr(TimeCurrent(),TIME_MINUTES);
				//returnResponse.Deserialize(result);  
				//return returnResponse;  
           }
         else
           {
            PrintFormat("Connecting to '%s' failed, code %d , EA Not Authenticated to operate on this session.",url,res);
            Print("Headers ", ResponseHeaders);
            Print("Result from API ", CharArrayToString(result));
  			   //return returnResponse;
           }
        }
  return 0;
}







/*
   string protocol = "http://";
   string url = "dev.surmountfinance.com/api/v1/";
   string uri = "HistoryDropFeed/" + feedSymbol + "/" + feedTimeFrame;
   int digitsQty = 10;
   string req_Header= "Content-Type: application/json\r\nAuthorization: Bearer eyJhbGciOiJIUzI1NiJ9.NjBkMWY0ZDIxNjUzZjYzMmRjMDJhYzcw.VlraElqzBlvjqJCsdNlW942ocwKeqpIPxE-OuZF0NSs";
   //string tempBody = "{ 'prices': '222', 'dataSource': [ { 'close': " + DoubleToString(feedClose,digitsQty) + ", 'high': " + DoubleToString(feedHigh,digitsQty) + ", 'low': " + DoubleToString(feedLow, digitsQty) + ", 'open': " + DoubleToString(feedOpen , digitsQty) + ", 'time': " + IntegerToString(feedTime)+ ", 'volume': " + DoubleToString(feedVolume, digitsQty)  + " } ] }";
   //string tempBody = "{\"prices\":\"220\",\"dataSource\":[{\"close\":219.89,\"high\":220.94,\"low\":218.83,\"open\":220,\"time\":1569470400,\"volume\":20730608}]}";
   //string tempBody = "{}";
    CJAVal jsonRequestBody;
	    jsonRequestBody["key"] = "value";
    uchar jsonData[];


Print("Flushing latest  error code ", GetLastError());

      string headers;
      char   post[],result[];
uchar emptyBody[];
	   CJAVal returnResponse;
      Print("About to send webrequest to ", protocol + url + uri );
      Print("req_Header", req_Header);
     // Print("req_body", tempBody);

Print("Request Body in JSon Serialized is ", jsonRequestBody.Serialize());

      //StringToCharArray(tempBody , post, 0, StringLen(tempBody) ); Print("StringLen is ",StringLen(tempBody) );
StringToCharArray(jsonRequestBody.Serialize(), jsonData, 0, StringLen(jsonRequestBody.Serialize()),CP_UTF8);


    //  int res=WebRequest("POST",(protocol+url+uri),req_Header, 10000, post, result, headers);
//int res=WebRequest("POST",(protocol+url+uri),req_Header, 10000, jsonData, result, headers);
int res=WebRequest("POST",(protocol+url+uri),req_Header, 10000, emptyBody, result, headers);
      Print("Just sent webrequest to SurmountFinance \n\r"); 
		Print("URI ", ((protocol+url+uri)) , "\n\r");
		Print("WebRequest res ",res, " latest MQL5 error code ", GetLastError(), "\n\r" ); 
      Print("Response header ", headers, "\n\r"	        );
	   Print("Response result ", CharArrayToString(result)	        );

      if(res==-1)
        {
         Print("Authentication was blocked, incorrect or unauthorized use by user. Code  =",GetLastError());
         //--- Perhaps the URL is not listed, display a message about the necessity to add the address
         MessageBox("To allow EA Operation, Add the address '"+protocol+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
			//return returnResponse;
        }
      else
        {
         if(res==200)
           {
				returnResponse.Deserialize(result);  
				//return returnResponse;  
           }
         else
           {
            PrintFormat("Connecting to '%s' failed, code %d , EA Not Authenticated to operate on this session.",url,res);
            Print("Headers ", headers);
            Print("Result from API ", CharArrayToString(result));
  			   //return returnResponse;
           }
        }
*/




/*

void PostOrderStatusAPI(string pair, int order_type)
  {
   if(MQLInfoInteger(MQL_TESTER)) { }
   else
     {
// JSON text to send
 //  string strJsonText= "{\"key\"= \"value\"};
    CJAVal json;

   json["key"] = "value";


   // Text must be converted to a uchar array. Note that StringToCharArray() adds 
   // a nul character to the end of the array unless the size/length parameter
   // is explicitly specified 
   uchar jsonData[];
   StringToCharArray(json.Serialize(), jsonData, 0, StringLen(json.Serialize()),CP_UTF8);

   // Use MT4's WebRequest() to send the JSON data to the server.
   char serverResult[];
   string serverHeaders;
   int res = WebRequest("POST", "http://x.x.x.x/api/updatetradingstatus/", "", "", 10000, jsonData, ArraySize(jsonData), serverResult, serverHeaders);

   Print("Web request result: ", res, ", error: #", (res == -1 ? GetLastError() : 0));


     }


  }

*/







/*
   string protocol = "http://";
   string url = "dev.surmountfinance.com/api/v1/";
   string uri = "HistoryDropFeed/" + feedSymbol + "/" + feedTimeFrame;
   int digitsQty = 10;
   string req_Header= "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.NjBkMWY0ZDIxNjUzZjYzMmRjMDJhYzcw.VlraElqzBlvjqJCsdNlW942ocwKeqpIPxE-OuZF0NSs;Content-Type: application/json";
   //string tempBody = "{ 'prices': '222', 'dataSource': [ { 'close': " + DoubleToString(feedClose,digitsQty) + ", 'high': " + DoubleToString(feedHigh,digitsQty) + ", 'low': " + DoubleToString(feedLow, digitsQty) + ", 'open': " + DoubleToString(feedOpen , digitsQty) + ", 'time': " + IntegerToString(feedTime)+ ", 'volume': " + DoubleToString(feedVolume, digitsQty)  + " } ] }";
   //string tempBody = "{\"prices\":\"220\",\"dataSource\":[{\"close\":219.89,\"high\":220.94,\"low\":218.83,\"open\":220,\"time\":1569470400,\"volume\":20730608}]}";
   string tempBody = "{}";
      string headers;
      char   post[],result[];
	   CJAVal returnResponse;
      Print("About to send webrequest to ", protocol + url + uri );
      Print("req_Header", req_Header);
      Print("req_body", tempBody);
      StringToCharArray(tempBody , post, 0, StringLen(tempBody) ); Print("StringLen is ",StringLen(tempBody) );



      int res=WebRequest("POST",(protocol+url+uri),req_Header, 10000, post, result, headers);
      Print("Just sent webrequest to SurmountFinance \n\r"); 
		Print("URI ", ((protocol+url+uri)) , "\n\r");
		Print("WebRequest res ",res, "\n\r" );
      Print("Response header ", headers, "\n\r"	        );
	   Print("Response result ", CharArrayToString(result)	        );

      if(res==-1)
        {
         Print("Authentication was blocked, incorrect or unauthorized use by user. Code  =",GetLastError());
         //--- Perhaps the URL is not listed, display a message about the necessity to add the address
         MessageBox("To allow EA Operation, Add the address '"+protocol+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
			//return returnResponse;
        }
      else
        {
         if(res==200)
           {
				returnResponse.Deserialize(result);  
				//return returnResponse;  
           }
         else
           {
            PrintFormat("Connecting to '%s' failed, code %d , EA Not Authenticated to operate on this session.",url,res);
            Print("Headers ", headers);
            Print("Result from API ", CharArrayToString(result));
  			   //return returnResponse;
           }
        }
        
*/

void deJSON(string resultString){
    
    StringReplace(resultString,"[","");
    StringReplace(resultString,"]","");
    StringReplace(resultString,"{","");
    StringReplace(resultString,"}","");
    StringReplace(resultString,CharToStr(34),"");
    StringReplace(resultString,"/","");


   //Print(resultString);

    // Split {
    string sep=",";
    string out;
    ushort u_sep;
    int tmpGETOrders;

    //--- Get the separator code
    u_sep=StringGetCharacter(sep,0);

    //--- Split the string to substrings
    int GETresultCnt=StringSplit(resultString,u_sep,GETresult);

    resultString = "";
    //--- Now output all obtained strings
    if(GETresultCnt>0)
     {
      /*for(int i=0;i<GETresultCnt;i++)
        {

          //GETresult[i]=StringSubstr(GETresult[i],StringFind(GETresult[i],":",0)+1);
           Print(i+" "+GETresultCnt+" "+GETresult[i]);
          //GETresult[i] = "{"+GETresult[i]+"}";
        }
        */
      GETOrders=0;
      int FindSymbol=0;
      for(int i=2;i<GETresultCnt;i=i+17)
           {  
           //int GETAge=StringToInteger(StringSubstr(GETresult[i+8],StringFind(GETresult[i+8],":",0)+1));
           if(StringSubstr(GETresult[i],0,6)!="symbol")break;
           
           FindSymbol=0;
           tmpGETOrders=GETOrders;
           for(int j=0;j<GETOrders;j++){
              if(StringSubstr(GETresult[i+3],StringFind(GETresult[i+3],":",0)+1)==GETOrderTicket[j]){
                  FindSymbol=FindSymbol+1;
                  tmpGETOrders=j;
              }          
               
           }
           
           
            GETOrderSymbol[tmpGETOrders]=StringSubstr(GETresult[i],StringFind(GETresult[i],":",0)+1);
            //Print(GETOrderSymbol[GETOrders]);
            GETOrderTicket[tmpGETOrders]=StringToInteger(StringSubstr(GETresult[i+3],StringFind(GETresult[i+3],":",0)+1));
            //Print(GETOrderTicket[GETOrders]);
            GETOrderLots[tmpGETOrders]=StringToDouble(StringSubstr(GETresult[i+4],StringFind(GETresult[i+4],":",0)+1));
            
            GETOrderPrice[tmpGETOrders]=StringToDouble(StringSubstr(GETresult[i+5],StringFind(GETresult[i+5],":",0)+1));
            //Print(GETOrderPrice[GETOrders]);
            GETOrderTP[tmpGETOrders]=StringToDouble(StringSubstr(GETresult[i+6],StringFind(GETresult[i+6],":",0)+1));
            //Print(GETOrderTP[GETOrders]);
            GETOrderSL[tmpGETOrders]=StringToDouble(StringSubstr(GETresult[i+7],StringFind(GETresult[i+7],":",0)+1));
            //Print(GETOrderSL[GETOrders]);
            GETOrderTime[tmpGETOrders]=StringToInteger(StringSubstr(GETresult[i+8],StringFind(GETresult[i+8],":",0)+1));
            //Print(GETOrderTime[GETOrders]);
            GETOrderComment[tmpGETOrders]=StringSubstr(GETresult[i+11],StringFind(GETresult[i+11],":",0)+1);
            //Print(GETOrderComment[GETOrders]);
            GETOrderMagicNumber[tmpGETOrders]=StringToInteger(StringSubstr(GETresult[i+12],StringFind(GETresult[i+12],":",0)+1));
            //Print(GETOrderMagicNumber[GETOrders]);
            GETOrderType[tmpGETOrders]=StringSubstr(GETresult[i+13],StringFind(GETresult[i+13],":",0)+1);
            out=out+ "    "+GETOrderSymbol[tmpGETOrders]+"-"+GETOrderType[tmpGETOrders];
            if(FindSymbol==0){
               GET1stOrderType[GETOrders]=StringSubstr(GETresult[i+13],StringFind(GETresult[i+13],":",0)+1);
               //Print("1st order type"+GET1stOrderType[GETOrders]);
               GET1stOrderTime[GETOrders]=StringToInteger(StringSubstr(GETresult[i+8],StringFind(GETresult[i+8],":",0)+1));
               //Print("1st order time"+GET1stOrderTime[GETOrders]);
               GETOrders=GETOrders+1;               
            }
           
        }
    }
    OpenPos=OpenPos+GETOrders;
    if(GETOrders>0)Print("GET Orders Found:"+GETOrders+ out);

}

double CalcLots(string symbol_, double lots, int type, double op, double sl){

double lot_size;
int stoploss;

lot_size=Lots;

if(Lots>0)return(Lots);
if(Multi>0)return(lots*Multi);
if(Risk==0)return(lots);
     
if(type==0 || type==2 || type==4)stoploss=op-sl;
if(type==1 || type==3 || type==5)stoploss=sl-op;

string acc_currency=AccountCurrency();

double money_risk=AccountBalance()*Risk/100; //*************************RISK REPLACE*******************
double dix=MarketInfo( symbol_, MODE_TICKVALUE );
//Point*SymbolInfoDouble(Symbol(),MODE_TICKVALUE)*10;

   if(dix*stoploss>0){
      Print("money_risk",money_risk);
      Print("dix*stoploss ",dix*stoploss);
      lot_size=money_risk/(dix*stoploss);
      if(lot_size*100<1)lot_size=0.01;
      if(lot_size>5)lot_size=1;
  }
  
  
return(lot_size);

}
