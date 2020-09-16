//+------------------------------------------------------------------+
//|                                                        Test1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;
// check it min 50

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group          "Operation Data"
input double         contracts=0;                  // Number of contracts
input double         stopLoss=0;                   // Operation stop loss value
input double         stopGain=0;                   // Operation stop gain vaule

input group          "Security Data"
input int            maxLoss = 0;                  // Max Loss
input int            maxGain = 0;                  // Max Gain
input int            numMaxOper = 0;               // period Max # of operations in the 

input group          "Time Data"
input int            openHour=9;                   // Open time (BMF)
input int            openMinutes=15;               // Open time (BMF)
input int            closeHour=17;                 // Close time (BMF)
input int            closeMinutes=45;                // Close time (BMF)
   
input group          "Fast Moving Average"
input int            iMA_fast_ma_period=8;         // med avg fast 
input int            iMA_fast_ma_shift=0;
input ENUM_MA_METHOD iMA_fast_ma_method=MODE_SMA;  // Soft fast == 0

input group          "Slow Moving Average"
input int            iMA_slow_ma_period=21;        // med avg fast 
input int            iMA_slow_ma_shift=0;
input ENUM_MA_METHOD iMA_slow_ma_method=MODE_EMA;  // Soft SMOOTH TYPE == 1

// iMACD Diff between fast and slow moving average
input group "MACD Data"
input int            fast_ema_period=13;           // med avg fast 
input int            slow_ema_period=29;
input int            signal_period=9;              // Soft fast

//+------------------------------------------------------------------+
//| MONITORING GLOBAL VARIABLES                                      |
//+------------------------------------------------------------------+

string               gl_TipoOrdem="UNDEFINED";      // UNDEFINED, BUY OR SELL
string               gl_TipoOrdemMM = "UNDEFINED";
string               gl_TipoOrdemMACD = "UNDEFINED";
bool                 gl_openPosition = false;      // Default starting value
long                 gl_positionType = 0;          // Initialized
double               gl_contracts = 0;             //
string               gl_tendenciaMACD = "NA";      // Trend
string               gl_tendenciaMM = "NA";        // Trend
int                  gl_Order = 0;
long                 gl_ticks = 0;


//+------------------------------------------------------------------+
//| HANDLES (HEART) -- ALL INDICATORS MUST HAVE A HANDLE             |
//+------------------------------------------------------------------+

// Handles are mandatory for the robots.

int                  iMA_fast_handle=-1;           //INVALID_HANDLE == -1
int                  iMA_slow_handle=INVALID_HANDLE;
int                  iMACD_handle=-1;              //INVALID_HANDLE == -1

//+------------------------------------------------------------------+
//| BUFFERS -- ALL INDICATORS MUST HAVE BUFFERS FOR EACH LINE        |
//+------------------------------------------------------------------+

// Whats value in Candle 0? 1? 10? ...
// Stored in the buffers

double               iMA_fast_buffer[];            // iMA_fast_buffer[0] iMA_fast_buffer[1] ...
double               iMA_slow_buffer[];            // iMA_fast_buffer[0] iMA_fast_buffer[1] ...

double               iMACD_main_buffer[];          // iMACD_main_buffer[0]
double               iMACD_signal_buffer[]; 


// Class 3 - Strategy
// Pode ser feito negocio a negocio (compra 100 petro, vende 100 petro) or timer (por tick ou timer)
// Ou Movimentacao de book (profundidade de book)
// Curso basico: comecar pelo tick, que serve para 90% dos casos


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- create timer

   // -- YOU Must loop all indicators and clean when the robot is added
   // -- do it here
   //
   
   // When you drag your robot, note on the first tab "ALLOW Algo Trade"
   MessageBox("Feche as guias");
   if(contracts<=0)
   {
      Print("Contracts cannot smaller or equal 0");
      return(INIT_FAILED);
   }
   if(stopLoss == 0)
   {
      Print("stopLoss cannot smaller or equal 0");
      return(INIT_FAILED);
   }
   

   if(stopGain == 0)
   {
      Print("stopGain cannot smaller or equal 0");
      return(INIT_FAILED);
   }
   

   EventSetTimer(240); // Aqui aciono o timer de 240 segundos
   Print("Arrastei o robo para o grafico");
   
   //+------------------------------------------------------------------+
   //|HANDLES                                                           |
   //+------------------------------------------------------------------+

   iMA_fast_handle=iMA(_Symbol,_Period,iMA_fast_ma_period,iMA_fast_ma_shift,iMA_fast_ma_method,PRICE_CLOSE);
   
   iMA_slow_handle=iMA(_Symbol,_Period,iMA_slow_ma_period,iMA_slow_ma_shift,iMA_slow_ma_method,PRICE_CLOSE);
   
   iMACD_handle=iMACD(_Symbol,_Period,fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   
   // Most recent candle is the last candle BY DEFAULT.
   // We ask Metatrade to put the array[0] on the right side
   
   //+------------------------------------------------------------------+
   //|Array set as series                                               |
   //+------------------------------------------------------------------+
   ArraySetAsSeries(iMA_fast_buffer,true); // BOY, put the candle to the right, please
   ArraySetAsSeries(iMA_slow_buffer,true); // BOY, put the candle to the right, please

   ArraySetAsSeries(iMACD_main_buffer,true); // BOY, put the candle to the right, please
   ArraySetAsSeries(iMACD_signal_buffer,true); // BOY, put the candle to the right, please

   //+------------------------------------------------------------------+
   //| Chart indicator ADD                                              |
   //+------------------------------------------------------------------+
   
   ChartIndicatorAdd(ChartID(),0,iMA_fast_handle); //ChartID is the chart itself (PETR4 is 1, Mini is 2, and so on); indicator is 0 for "Window 0"
   ChartIndicatorAdd(ChartID(),0,iMA_slow_handle);

   ChartIndicatorAdd(ChartID(),1,iMACD_handle); // 1 means that it will be plotted in the second chart. "Window 1"
   
   Print("Inicializacao realizada com sucesso.");
   
   gl_ticks=0;
   
   return(INIT_SUCCEEDED);
   
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- destroy timer created in the OnInit
   EventKillTimer(); 
   //+------------------------------------------------------------------+
   //| INDICATOR RELEASE      << Handles                                |
   //+------------------------------------------------------------------+
   // Releases memory and resources, if you are talking of 10 indicators and 400 assets
   IndicatorRelease(iMA_fast_handle);
   IndicatorRelease(iMA_slow_handle);

   IndicatorRelease(iMACD_handle);
   
   //+------------------------------------------------------------------+
   //| ARRAYFREE          << buffer                                     |
   //+------------------------------------------------------------------+
   // It could be in the middle of the robot. 
   ArrayFree(iMA_fast_buffer);
   ArrayFree(iMA_slow_buffer);
   ArrayFree(iMACD_main_buffer);
   ArrayFree(iMACD_signal_buffer);
   
   //+------------------------------------------------------------------+
   //| DELETE CHART INDICATOR                                           |
   //+------------------------------------------------------------------+
   
   string iMA_fast_chart=ChartIndicatorName(0,0,0); // Please what is the name of the indicator 1?
   ChartIndicatorDelete(0,0,iMA_fast_chart);

   string iMA_slow_chart=ChartIndicatorName(0,0,0); // Please what is the name of the indicator 1?
   ChartIndicatorDelete(0,0,iMA_slow_chart);


   string iMACD_chart=ChartIndicatorName(0,1,0); // we now it is window 1
   ChartIndicatorDelete(0,1,iMACD_chart);
   
   //+------------------------------------------------------------------+
   //| MESSAGE                                           |
   //+------------------------------------------------------------------+   
   
   Print("Robo finalizado com sucesso. Obrigado");
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
  {
// each tick == each business. After a business, update the following variables  
   gl_ticks = gl_ticks + 1;
  
//+------------------------------------------------------------------+
//| Chart initialization                                             |
//+------------------------------------------------------------------+

   ResetLastError(); // Clean all pending errors   
   // FIRST THING TO DO AFTER A BUSINESS: Update the values
   CopyBuffer(iMA_fast_handle,0,0,3,iMA_fast_buffer); // Will copy 3 positions from iMA_fast_buffer [0].[1],[2] to iMA_fast_handle
   CopyBuffer(iMA_slow_handle,0,0,3,iMA_slow_buffer); // Position 0, candle position 0, 3 items

   CopyBuffer(iMACD_handle,0,0,3,iMACD_main_buffer); // Same, but this is the histogram, the next is the signal
   CopyBuffer(iMACD_handle,1,0,3,iMACD_main_buffer); // Note that this copies to the position 1
   
   MqlDateTime dt;  // It is an struct. dt.hour, dt.min, ...
   TimeCurrent(dt); // Server time. > if you want use TimeLocal() To know the local time. TimeCurrent = time of the deal
   
   
   // Update date time vars
   double loc_currTime=dt.hour*60+dt.min;
   double loc_openTime=openHour*60+openMinutes;
   double loc_closeTime=closeHour*60+closeMinutes-1; // Do not use last minute. // first 15 minutes have lots of problem
   
   // Check open market
   if(loc_currTime<loc_openTime)
   {
      Comment("Robot waiting the opening.");
      // Assure all variables are "initialized" as if it was the begining of the day
      //  as if it was brand new
      return;
   }

   // Check closed market
   if(loc_currTime>loc_closeTime)
   {
      Comment("Robot - Market closed.");
      // Do something so that the robot does not sleep with an open position
      
      return;
   }
   //Print(TimeCurrent());
   //Print(TimeLocal());
   
   // Check position (tenho custodia)

   gl_openPosition=PositionSelect(_Symbol);
   
   if(gl_openPosition)
   {
      gl_positionType=PositionGetInteger(POSITION_TYPE); //buyer or seller
      gl_contracts=PositionGetDouble(POSITION_VOLUME);   // Quantity
   }
   else
   {
      gl_positionType=WRONG_VALUE; // -1
   }
   
   // ANALYSIS
   // ========
      
   // correct way   
   if(iMA_fast_buffer[0]>iMA_slow_buffer[0] && 
      iMA_slow_buffer[1] > iMA_fast_buffer[1])
         gl_TipoOrdemMM="COMPRA";

   if(iMA_fast_buffer[0]<iMA_slow_buffer[0] && 
      iMA_fast_buffer[1] > iMA_slow_buffer[1])
         gl_TipoOrdemMM="VENDA";
         
         
   // Analysis 
         
   if(iMACD_main_buffer[0]>iMACD_signal_buffer[0] && 
      iMACD_signal_buffer[1] > iMACD_main_buffer[1])
         gl_TipoOrdemMACD="COMPRA";

   if(iMACD_main_buffer[0]<iMACD_signal_buffer[0] && 
      iMACD_signal_buffer[1] > iMACD_main_buffer[1])
         gl_TipoOrdemMACD="VENDA";         
            
   // Get the moving average + trend of MACD (+ vol)
   // You can use one of the 7 averages available in Metatrade to calibrate your averages.
   // You could use 1 and 2. Candle can cross the average and be false. 
   // Check at the end of the candle and undo the operation if required.
   
   // ==== BUY
   // ========
   if(gl_tendenciaMM=="COMPRA" && gl_tendenciaMACD == "COMPRA")
      gl_Order=1; // Buy
      
   // ==== Hold venda se ja esta posicionado
   if(gl_openPosition == true && gl_positionType==POSITION_TYPE_BUY && gl_Order ==1)
      gl_Order=0;  // Do nothing
      
   // ==== SELL
   // =========
   
   if(gl_tendenciaMM=="VENDA" && gl_tendenciaMACD == "VENDA")
      gl_Order=-1; // Sell
      
   // ==== Hold venda se ja esta posicionado
   if(gl_openPosition== true && gl_positionType==POSITION_TYPE_SELL && gl_Order ==-1)
      gl_Order=0; // Do Nothing

   // comenta grafico
   Comment("glTicks: ", gl_ticks , " | glContratos: ",gl_contracts, " | glTendenciaMM: ",gl_tendenciaMM, " | glTendenciaMACD: ",gl_tendenciaMACD );

   
        
   // Ready for order placement (bater a boleta)
   // =================
   //  ORDER PLACEMENT
   // =================
   
   if(gl_Order!=0)
   {
   
      MqlTick price_info;                       // create the price structure
      ZeroMemory(price_info);                   // Clean the area
      
      if(!SymbolInfoTick(_Symbol,price_info))   // Populate the asset value
      {  
         Print(_Symbol," | ",__FUNCTION__, " | ", __LINE__," Erro to get SymbolInfoTich()");
         return;  
         
      }
      
      if(gl_Order==1)      // Compra
      {
         //take from the guy that is selling (oferece o preco para ser habil para comprar. Se colocar ask, a ordem nao anda.
         // stop loss is UNDER ask
         if(trade.Buy(gl_contracts,_Symbol, price_info.bid,price_info.ask-stopLoss, price_info.ask+stopGain,"[CR01]"))
         {
            Print("Ordem enviada com sucesso");
         } else {
            Print("Ordem enviada com ERRO");         
         }
         
      }
      if(gl_Order==-1)     // Venda
      {
         if(trade.Sell(gl_contracts,_Symbol, price_info.bid, price_info.bid+stopLoss,price_info.bid-stopGain,"[CV01]"))
         {
            Print("Ordem enviada com sucesso");
         } else {
            Print("Ordem enviada com ERRO");         
         }
      }
      
      Sleep(60*1000);       // Counting 60 seconds after each deal, to support the topology OMS - Order Management System -> XP -> B3 ->OMS ->MetaTraderServer -> Your Server -> MT
   
   
   }
  
   
   
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      Print("Essa funcao ocorre a cada 5 segundos");
  }



//+------------------------------------------------------------------+
