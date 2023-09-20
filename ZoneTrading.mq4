//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "GCS Research"
#property link ""
#property version "0.2"
#property strict
#property description "Zone Recovery"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum po_koefs
  {
   _1=1,/*1*/  _10=10,/*10*/ _100=100,/*100*/ _1000=1000,/*1000*/
  };

extern string oth_set = "///////////////Other settings///////////////////";
extern int Max_orders = 5;
extern double MaxSpread=30;
extern int Slippage=0;
extern int Magic=654456;
extern string comment="MMM";
extern int Display = 0;
po_koefs Point_multiplier=_10;

extern string sig_set = "///////////////Signal settings///////////////////";
extern int TradeDir = -1;
extern int EMA_period = 500;
extern int EMA_TradeDir = -1; //EMA Trade Direction 1 to EMA -1 Away
//extern double RSI_sell_CalcZone= 70;
//extern double RSI_buy_CalcZone = 30;
extern int ATR_period = 10;
extern int ATR_Shift=1;
extern int StdDev_Period= 5;
extern double StdDevTrig = 0;
extern int VolStdTrig=0;
extern int VolTrig=0;
extern int MFITradeDir=0;
extern int MFITrig=40;
extern int MFIPeriod=10;

extern string lot_set="///////////////Lot settings///////////////////";
extern double Lot=0.1;
extern double Risk = 1; 
extern double Lot_multiplier=1.5;
extern double max_lot = 0;
extern double min_lot = 0;

extern string dis_set="///////////////Distance settings///////////////////";
extern double ZoneOpen=2;
extern double Zone=0.5;
extern double distance_multiplier=1;
extern int max_distance = 0;
extern int min_distance = 0;

extern string prof_set="///////////////Profit/Lose settings///////////////////";
extern double TakeProfit=0.5;
extern double StopLoss=0.5;
extern bool use_close_profit = false;
extern double profit_1_order = 2;
extern double profit_multiplier=0.7;
extern bool use_close_lose = false;
extern double lose_1_order = 6;
extern double lose_multiplier=1.1;
extern string   TimeManagement=" ========= Trade Time Filter =====";  //=========================
input int           TimeManagment           = 0;          // Activate Trade Time Filter

input string         TradeHours =  "11"; // Trade hours comma separated
input int            StartMinute=0;
input int            HourSelect = 99;  // Select single hour for optimization 99=Disabled
input int            StartDay = 1;  //Start Day 1=Monday
input int            StartHour= 1;   //Start Hour
input int            StopDay = 5;  //Stop Day 5=Friday
input int            StopHour = 16;  //Stop Hour
input string            Months="1,2,3,4,5,6,7,8,9,10,11,12"; // Months, comma saperated
input string            DaysOfWeek="1,2,3,4,5";  // Days of week, 1=Monday
input int            CloseHour=23;
input int            RevHour=99;

string EAName = "Murray's Money Maker";

int Sig_p;
int buys,sells,pbuys,psells,Orders_Total,pOrders_Total,Orders_Pend,Orders_cnt,TradeDay;
//double Point=Point*Point_multiplier;
int nor_lot=2,LastBar,pendcnt,Vol,VolStd;
string NoTradeCmt;
double ZoneTop, ZoneBottom,ZoneTopL, ZoneBottomL,ZoneTopS, ZoneBottomS,fstordopen,CalcZone,CalcZoneOpen,CalcSL,CalcTP,OpenLots,StopLoss2;
string TradeCode="X3MA_EA2.0";

//////////////////////////////////////////////////////////////
int OnInit()
  {

   if(MarketInfo(Symbol(),MODE_LOTSTEP)==0.1) nor_lot=1;
   StopLoss2=StopLoss;
   if(StopLoss==0)StopLoss2=TakeProfit;
   CalcZone=Zone;CalcSL=StopLoss2*Point;CalcTP=TakeProfit*Point;

   return(INIT_SUCCEEDED);
  }
////////////////////////////////////
int deinit() {
  
   for (int j=3;j<=40;j++)
   {
      if(ObjectFind(0,"bg"+j+"_"+TradeCode) > -1) ObjectDelete("bg"+j+"_"+TradeCode);
      if(ObjectFind(0,"bg2"+j+"_"+TradeCode) > -1) ObjectDelete("bg2"+j+"_"+TradeCode);
   }
   Comment("");
   
   if(ObjectFind(0,"FRF.upperBB"+IntegerToString(0)) > -1) ObjectDelete("FRF.upperBB"+IntegerToString(0)); 
   if(ObjectFind(0,"FRF.lowerBB"+IntegerToString(0)) > -1) ObjectDelete("FRF.lowerBB"+IntegerToString(0)); 
   
   return(0);
}
void OnTick()
  {
//close profit
   CountOpenedPositions_f(0);
   
   if(use_close_profit)
     {
      //if(Profit_f()>=profit_1_order*MathPow(profit_multiplier,Orders_cnt-1)) Close_all_f(0);
     }

//close lose
   if(use_close_lose)
     {
      //if(Profit_f()<=-(lose_1_order*MathPow(lose_multiplier,Orders_cnt-1))) Close_all_f(0);
     }



    
//open
   NoTradeCmt="";
   
   //if((Year()*100 + Month())>202202) NoTradeCmt="Version Expired";
   
   double Spread=MarketInfo(Symbol(), MODE_SPREAD);
   if(Spread > MaxSpread){NoTradeCmt="Exceeding Max Spread";}



   if(TimeManagment == 1 && Orders_Total==0 && NoTradeCmt==""){  //  *********************************************************   Time  ********************************************************************

      if(HourSelect >= 99){

         if(StringFind(","+TradeHours+",",","+Hour()+",")==-1 )NoTradeCmt="NO NEW TRADES THIS HOUR";
         if(Minute()<StartMinute)NoTradeCmt="BEFORE START MINUTE";
         
         
      }else{
         if(Hour()==HourSelect|| Hour()== HourSelect-24) {
           
         }else{
            NoTradeCmt="NO NEW TRADES THIS HOUR";
         }      
      }

      int now = DayOfWeek()*24+Hour();
      if(now < (StartDay*24+StartHour)) {NoTradeCmt="BEFORE START DAY/HOUR";}
      if(now > (StopDay*24+StopHour)) {NoTradeCmt="PAST STOP DAY/HOUR";}
  

      if(StringFind(","+DaysOfWeek+",",","+DayOfWeek()+",")==-1) {NoTradeCmt="NOT TODAY";}
      if(StringFind(","+Months+",",","+Month()+",")==-1){NoTradeCmt="NOT THIS MONTH";}
      
   }

   if(Hour()==CloseHour){
      NoTradeCmt="Close Hour";
      if(Orders_Pend >0 || Orders_Total >0)Close_all_f(0);
   }
//NewBar
   if(Bars>LastBar && Orders_Total==0 && NoTradeCmt==""){
      Close_all_f(0);
      LastBar=Bars;
      double ATR=(iATR(Symbol(),0,ATR_period,ATR_Shift)+iATR(Symbol(),0,ATR_period,1))/2;
      CalcZone=Zone*ATR;
      CalcZoneOpen=ZoneOpen*ATR;
      double EMA=iMA(NULL,0,EMA_period,0,MODE_EMA,PRICE_MEDIAN,1);
      ZoneTop=EMA+CalcZoneOpen/2;
      ZoneBottom=EMA-CalcZoneOpen/2;
      if(Ask>ZoneTop || Bid<ZoneBottom){ZoneTop=0;LastBar=Bars+1;}
      
   }
   
   if(Orders_Total==0 && Orders_Pend ==0 && NoTradeCmt=="" && ZoneTop>0){
      double ticket_op=-1;
      double Lotss=Lot;

      if(TakeProfit<5)CalcTP=TakeProfit*CalcZone+Bid-Ask;
      if(StopLoss2<5)CalcSL=StopLoss2*CalcZone+Bid-Ask;
      if(TradeDir==1)ticket_op=OrderSend(Symbol(),OP_BUYSTOP,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneTop,Digits),Slippage,NormalizeDouble(ZoneTop-CalcZone-CalcSL,Digits),NormalizeDouble(ZoneTop+CalcTP,Digits),comment,Magic,0,clrBlack);   
      if(TradeDir==-1)ticket_op=OrderSend(Symbol(),OP_SELLLIMIT,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneTop,Digits),Slippage,NormalizeDouble(ZoneTop+CalcZone+CalcSL,Digits),NormalizeDouble(ZoneTop-CalcTP, Digits),comment,Magic,0,clrBlack);               

      if(TradeDir==1)ticket_op=OrderSend(Symbol(),OP_SELLSTOP,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneBottom,Digits),Slippage,NormalizeDouble(ZoneBottom+CalcZone+CalcSL,Digits),NormalizeDouble(ZoneBottom-CalcTP, Digits),comment,Magic,0,clrBlack);               
      if(TradeDir==-1)ticket_op=OrderSend(Symbol(),OP_BUYLIMIT,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneBottom,Digits),Slippage,NormalizeDouble(ZoneBottom-CalcZone-CalcSL,Digits),NormalizeDouble(ZoneBottom+CalcTP,Digits),comment,Magic,0,clrBlack);   
      Print(Bars);
      
   } 
   if(Orders_cnt==0 && Orders_Pend ==1 && Orders_Total==1){
      Orders_cnt=1;
      Close_all_f(1);
      //Select_last_order_f();
      //last buy
      if(buys==1 && TradeDir==1 ){ZoneBottom=ZoneTop-CalcZone;}
      if(sells==1 && TradeDir ==-1){ZoneBottom=ZoneTop;ZoneTop=ZoneTop+CalcZone;}
      if(sells==1 && TradeDir == 1){ZoneTop=ZoneBottom+CalcZone;}
      if(buys==1 && TradeDir==-1){ZoneTop=ZoneBottom;ZoneBottom=ZoneBottom-CalcZone;}
        
   }
   

   if (NoTradeCmt=="" && Orders_Total>0 && Orders_Pend ==0){
      if(Year()*1000+DayOfYear() > TradeDay){
         
         Sig_p=Sig_f();
         if(Sig_p!=0)  open_f();
      }
   }
   
   
   if(Display==1)DispCom();
   
   CountOpenedPositions_f(1);
   
  }
//func
/////////////////////////////////////////////////////////////////////////////////////////////
char Sig_f()
  {
   CountOpenedPositions_f(0);
   if(Orders_Total==0)
     {
      
      //double rsi=iRSI(Symbol(),0,RSI_period,PRICE_CLOSE,0);
      double EMA=iMA(NULL,0,EMA_period,0,MODE_EMA,PRICE_MEDIAN,1);
      int TradeDir;
      if(Ask<EMA) TradeDir=1;
      if(Ask>EMA) TradeDir=-1;
      TradeDir=TradeDir*EMA_TradeDir;
      double stdev=iStdDev(NULL,0,StdDev_Period,0,MODE_SMA,PRICE_MEDIAN,0);
      Vol=iVolume(NULL,0,1);
      if(MFITradeDir!=0){
         TradeDir=0;
         int MFI=iMFI(NULL,0,MFIPeriod,0)-50;
         Print(MFI);
         if(MFI>MFITrig) TradeDir=1;
         if(MFI<-1*MFITrig) TradeDir=-1;
         TradeDir=TradeDir*MFITradeDir;
      }  
      Print(TradeDir);
      if(stdev>StdDevTrig && Vol>VolTrig) return(TradeDir);
      return(0);
     }
   else
     {
      if(Max_orders>0 && Orders_cnt>=Max_orders) return(0);

      Select_last_order_f();
      //last buy
      if(OrderType()==OP_BUY)
        {
         double dist=CalcZone*MathPow(distance_multiplier,Orders_cnt-1);
         if(max_distance>0 && dist>max_distance*Point) dist=max_distance*Point;
         if(min_distance>0 && dist<min_distance*Point) dist=min_distance*Point;

         return(-1);
        }
      //last sell
      if(OrderType()==OP_SELL)
        {
         double dist=CalcZone*MathPow(distance_multiplier,Orders_cnt-1);
         if(max_distance>0 && dist>max_distance*Point) dist=max_distance*Point;
         if(min_distance>0 && dist<min_distance*Point) dist=min_distance*Point;
         
         return(1);
        }
     }//end else


   return(0);
  }
///////////////////////////////////////////////////////////////////////////////////////////////
void open_f()
  {
///////////// LOT /////////////////
   double Lotss=Lot;
   CountOpenedPositions_f(0);
   Lotss=Lot*Lot_multiplier*Orders_cnt;
//user limit
   if(max_lot>0 && Lotss>max_lot) Lotss=max_lot;
   if(min_lot>0 && Lotss<min_lot) Lotss=min_lot;
//broker limit
   double Min_Lot =MarketInfo(Symbol(),MODE_MINLOT);
   double Max_Lot =MarketInfo(Symbol(),MODE_MAXLOT);
   if(Lotss<Min_Lot) Lotss=Min_Lot;
   if(Lotss>Max_Lot) Lotss=Max_Lot;

//chek free margin
   if(MarketInfo(Symbol(),MODE_MARGINREQUIRED)*Lotss>AccountFreeMargin()) {Alert("Not enouth money to open order "+string(Lotss)+" lots!");return;}



///////////// MAIN /////////////  
   int ticket_op=-1;
   for(int j_op = 0; j_op < 64; j_op++)
     {
      while(IsTradeContextBusy()) Sleep(200);
      RefreshRates();

      
      if(Sig_p>0){
         if(Orders_cnt==0){
            ZoneTop=Ask;
            ZoneBottom=Bid-CalcZone;
            if(TakeProfit<5)CalcTP=(ZoneTop-ZoneBottom)*(TakeProfit/Zone)/Point;
            if(StopLoss2<5)CalcSL=(ZoneTop-ZoneBottom)*(StopLoss2/Zone)/Point;

            OpenLots=RiskLots(CalcSL+(ZoneTop-ZoneBottom)/Point);
            ticket_op=OrderSend(Symbol(),OP_BUY,NormalizeDouble(OpenLots,nor_lot),Ask,Slippage,NormalizeDouble(ZoneBottom-CalcSL*Point,Digits),NormalizeDouble(ZoneTop+CalcTP*Point,Digits),comment,Magic,0,clrLightBlue);
            TradeDay=Year()*1000+DayOfYear();
         }else{
            if(Hour()<RevHour){
               ticket_op=OrderSend(Symbol(),OP_BUYSTOP,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneTop,Digits),Slippage,NormalizeDouble(ZoneBottom-CalcSL,Digits),NormalizeDouble(ZoneTop+CalcTP,Digits),comment,Magic,0,clrLightBlue);
            }else{
               ticket_op=OrderSend(Symbol(),OP_SELLLIMIT,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneTop,Digits),Slippage,NormalizeDouble(ZoneTop+CalcZone,Digits),NormalizeDouble(ZoneBottom,Digits),comment,Magic,0,clrLightBlue);
               Orders_cnt=Max_orders-1;                        
            }           
         }
         
      }
      if(Sig_p<0){
         if(Orders_cnt==0){
            ZoneTop=Ask+CalcZone;
            ZoneBottom=Bid;
            if(TakeProfit<5)CalcTP=(ZoneTop-ZoneBottom)*(TakeProfit/Zone)/Point;
            if(StopLoss2<5)CalcSL=(ZoneTop-ZoneBottom)*(StopLoss2/Zone)/Point;

            OpenLots=RiskLots(CalcSL+(ZoneTop-ZoneBottom)/Point);
            ticket_op=OrderSend(Symbol(),OP_SELL,NormalizeDouble(OpenLots,nor_lot),Bid,Slippage,NormalizeDouble(ZoneTop+CalcSL,Digits),NormalizeDouble(ZoneBottom-CalcTP,Digits),comment,Magic,0,clrRed);
            TradeDay=Year()*1000+DayOfYear();
         }else{   
            if(Hour()<RevHour){         
               ticket_op=OrderSend(Symbol(),OP_SELLSTOP,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneBottom,Digits),Slippage,NormalizeDouble(ZoneTop+CalcSL,Digits),NormalizeDouble(ZoneBottom-CalcTP, Digits),comment,Magic,0,clrRed);               
            }else{
               ticket_op=OrderSend(Symbol(),OP_BUYLIMIT,NormalizeDouble(Lotss,nor_lot),NormalizeDouble(ZoneBottom,Digits),Slippage,NormalizeDouble(ZoneBottom-CalcZone,Digits),NormalizeDouble(ZoneTop, Digits),comment,Magic,0,clrRed);            
               Orders_cnt=Max_orders-1;                        
            }               
         }
      }
      Orders_cnt=Orders_cnt+1;

      if(ticket_op>-1)break;
      
     }


  }
////////////////////////////////////////////////////////////////////////////////////
void CountOpenedPositions_f(int pendchk)
  {
   pOrders_Total=Orders_Total;
   buys=0;
   sells=0;
   
   pbuys=0;
   psells=0;
   
   Orders_Total=0;

   

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderMagicNumber()==Magic)
           {
            if(OrderSymbol()==Symbol())
              {
               if(OrderType()==OP_BUY) {
                  buys++;
                  if(fstordopen==0)fstordopen=OrderOpenPrice();
               }
               if(OrderType()==OP_SELL){
                  sells++;
                  if(fstordopen==0)fstordopen=OrderOpenPrice();
               }
               if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT) pbuys++;
               if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT )psells++;
              }
           }
        }
     }

   Orders_Total=buys+sells;
   Orders_Pend=pbuys+psells;
   if(Orders_Total+Orders_Pend==0)Orders_cnt=0;
   /*if(Orders_Total>0 && Orders_Total<pOrders_Total ){
      Close_all_f();
      fstordopen=0;
      Orders_cnt=0;
   }*/
   
   
   if(Orders_Total==0 && Orders_Pend == 1){
      Close_all_f(0);Print("389");
      fstordopen=0;
      Orders_cnt=0;
   }
      
  }
////////////////////////////////////////////////////////////////////
void Select_last_order_f()
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderMagicNumber()==Magic)
           {
            if(OrderSymbol()==Symbol() && (OrderType()==OP_BUY || OrderType()==OP_SELL))
              {
               break;
              }
           }
        }
     }

  }
/////////////////////////////////////////////////////////////////////////////////// 
double Profit_f()
  {
   double prof=0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderMagicNumber()==Magic)
           {
            if(OrderSymbol()==Symbol())
              {
               prof+=OrderProfit()+OrderSwap()+OrderCommission();
              }
           }
        }
     }

   return(prof);
  }
////////////////////////////////////////////////////////////////////////////////
void Close_all_f(int pend)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderMagicNumber()==Magic)
           {
            if(OrderSymbol()==Symbol())
              {
               bool ticket_ex=false;
               for(int j_ex=0;j_ex<64; j_ex++)
                 {
                  while(IsTradeContextBusy()) Sleep(200);
                  RefreshRates();

                  if(OrderType()==OP_BUY && pend==0) ticket_ex=OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,clrNONE);
                  else
                     if(OrderType()==OP_SELL&& pend==0) ticket_ex=OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,clrNONE);
                  else
                     if(OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP || OrderType()==OP_SELLLIMIT || OrderType()==OP_BUYLIMIT) ticket_ex=OrderDelete(OrderTicket(),clrBlack);
                  else
                     break;
                  if(ticket_ex==true)break;
                 }
              }
           }
        }
     }
   CountOpenedPositions_f(1);
  } 
//+------------------------------------------------------------------+
void DispCom()
{
 string cmt = "\n     --------------------------------------------------------------------------------";
      
      cmt=cmt+"\n                                "+EAName;
      
      cmt=cmt+"\n     --------------------------------------------------------------------------------";
      cmt=cmt+"\n     GMT Time: "+TimeToStr(TimeGMT(),TIME_MINUTES)+"  Server Time: "+TimeToStr(TimeCurrent(),TIME_MINUTES); //+"   Offset: "+OffsetGMT;
      cmt=cmt+"\n     Spread: "+DoubleToString((Ask-Bid)/Point,0)+"/"+MaxSpread+" Magic: "+Magic ;
      cmt=cmt+"\n     Zone: "+DoubleToString(CalcZone/Point,0)+"   StopLoss: "+DoubleToString(CalcSL/Point,0)+"   TakeProfit: "+DoubleToString(CalcTP/Point,0);
      cmt=cmt+"\n     Cycle: "+Orders_cnt+"  ZoneTop: "+DoubleToString(ZoneTop,5)+"  ZoneBottom: "+DoubleToString(ZoneBottom,5);
      cmt=cmt+"\n     Vol: "+Vol+"  VolStd: "+VolStd;
      cmt=cmt+"\n     Trade Hours: "+TradeHours;
      cmt=cmt+"\n     Start Minute: "+StartMinute;

            
      if(NoTradeCmt!=""){
            cmt=cmt+"\n\n     Not Trading  : "+NoTradeCmt;
      } 
      
       for (int j=3;j<=30;j++)
      {
         drawFixedLbl("bg"+j+"_"+TradeCode, "  gggggggggggggggggggggggggggggggggggggg", 0, 1, j*6, 5, "Webdings",Navy, false);
         drawFixedLbl("bg2"+j+"_"+TradeCode, "  gggggggggggggggggggggggggggggggggggggg", 0, 1+5, j*6+5, 5, "Webdings",Gray, true);
      }
      
      Comment(cmt);
      
      double BandsUp=ZoneTop;
      double BandsLo=ZoneBottom;
      
      if(BandsUp>0 && BandsLo>0){

    if(ObjectFind(0,"FRF.BandsUp") < 0) {
         ObjectDelete("FRF.BandsUp"+IntegerToString(0));
         ObjectCreate(0,"FRF.BandsUp"+IntegerToString(0),OBJ_HLINE,0,0,0,0,0);          // Create an arrow
         //ObjectSetInteger(0,"FRF.BandsUp"+IntegerToString(0),OBJPROP_ARROWCODE,159);    // Set the arrow code
         ObjectSetInteger(0,"FRF.BandsUp"+IntegerToString(0),OBJPROP_COLOR,clrYellow);
      }
      ObjectSetInteger(0,"FRF.BandsUp"+IntegerToString(0),OBJPROP_TIME,Time[0]);        // Set time
      ObjectSetDouble(0,"FRF.BandsUp"+IntegerToString(0),OBJPROP_PRICE,BandsUp);// Set price
        

    if(ObjectFind(0,"FRF.BandsLo") < 0) {
         ObjectDelete("FRF.BandsLo"+IntegerToString(0));
         ObjectCreate(0,"FRF.BandsLo"+IntegerToString(0),OBJ_HLINE,0,0,0,0,0);          // Create an arrow
         //ObjectSetInteger(0,"FRF.BandsLo"+IntegerToString(0),OBJPROP_ARROWCODE,159);    // Set the arrow code
         ObjectSetInteger(0,"FRF.BandsLo"+IntegerToString(0),OBJPROP_COLOR,clrYellow);
      }
      ObjectSetInteger(0,"FRF.BandsLo"+IntegerToString(0),OBJPROP_TIME,Time[0]);        // Set time
      ObjectSetDouble(0,"FRF.BandsLo"+IntegerToString(0),OBJPROP_PRICE,BandsLo);// Set price
        
       }
     
 }
 
 void drawFixedLbl(string objname, string s, int Corner, int DX, int DY, int FSize, string Font, color c, bool bg)
{
   if (ObjectFind(objname) < 0) {ObjectCreate(objname, OBJ_LABEL, 0, 0, 0);}   
   ObjectSet(objname, OBJPROP_CORNER, Corner);
   ObjectSet(objname, OBJPROP_XDISTANCE, DX);
   ObjectSet(objname, OBJPROP_YDISTANCE, DY);
   ObjectSet(objname,OBJPROP_BACK, bg);      
   ObjectSetText(objname, s, FSize, Font, c);
}

double RiskLots(int sl){


if(Risk==0 || sl==0)return(Lot);

double lot_size=0;


     

string acc_currency=AccountCurrency();

double money_risk=AccountBalance()*Risk/100; //*************************RISK REPLACE*******************
double dix=MarketInfo( Symbol(), MODE_TICKVALUE );
//Point*SymbolInfoDouble(Symbol(),MODE_TICKVALUE)*10;



   lot_size=money_risk/(dix*sl);
   if(max_lot>0 && lot_size>max_lot) lot_size=max_lot;
   if(min_lot>0 && lot_size<min_lot) lot_size=min_lot;
//broker limit
   double Min_Lot =MarketInfo(Symbol(),MODE_MINLOT);
   double Max_Lot =MarketInfo(Symbol(),MODE_MAXLOT);
   if(lot_size<Min_Lot) lot_size=Min_Lot;
   if(lot_size>Max_Lot) lot_size=Max_Lot;
  
return(NormalizeDouble(lot_size,2));

}
