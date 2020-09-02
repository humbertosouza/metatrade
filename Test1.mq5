//+------------------------------------------------------------------+
//|                                                        Test1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

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
input ENUM_MA_METHOD iMA_fast_ma_method=MODE_SMA;         // Soft fast == 0

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

string glTipoOrdem="UNDEFINED"; // UNDEFINED, BUY OR SELL

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
   }
   

   if(stopGain == 0)
   {
   }
   

   EventSetTimer(5); // Aqui aciono o timer de 5 em 5 segundos
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
//---
   
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
