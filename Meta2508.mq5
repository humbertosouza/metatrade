//+------------------------------------------------------------------+
//|                                               YouDEV e ADVFN.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh> // INCLUINDO A CLASSE TRADE QUE TEM UM MONTE DE FUNCOES RELACIONADAS
CTrade Trade;              // AO ENVIO DE ORDENS PRA NAO DAR UMA DE CHATO E FAZER 40 LINHAS
// (INSTANCIAMENTO == GOOGLE)
//+------------------------------------------------------------------+
//| PARAMETROS DE ENTRADA                                            |
//+------------------------------------------------------------------+

input group          "Dados de Operação"
input double         contratos=0;                  // número de contratos (máx 5)
input double         stopLoss=0;                   // valor do stoploss da operação
input double         stopGain=0;                   // valor do stopgain da operação

input group          "Dados de horário"
input int            hAbertura=10;                  // horário de abertura
input int            mAbertura=15;                 // minuto de abertura
input int            hFechamento=16;               // horário de fechamento
input int            mFechamento=45;               // minuto de fechamento

input group          "Dados de media movel rapida"
input int            iMA_fast_ma_period=8;         // período médio média rápida
input int            iMA_fast_ma_shift=0;          // deslocamento horizontal média rápida
input ENUM_MA_METHOD iMA_fast_ma_method=MODE_SMA;  // tipo suavizado média rápida

input group          "Dados de media movel lenta"
input int            iMA_slow_ma_period=21;        // período médio média lenta
input int            iMA_slow_ma_shift=0;          // deslocamento horizontal média lenta
input ENUM_MA_METHOD iMA_slow_ma_method=MODE_EMA;  // tipo suavizado média lenta

input group          "Dados de MACD"
input int            fast_ema_period=13;           // período para cálculo da média móvel rápida
input int            slow_ema_period=29;           // período para cálculo da média móvel lenta
input int            signal_period=9;              // período para diferença entre as médias

//+------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS DE MONITORAMENTO                               |
//+------------------------------------------------------------------+

int                  glTicks=0;
double               glContratos=0;
long                 glPositionType=0;
bool                 glOpenPosition=false;

int                  glOrder=0;
string               glTendenciaMM="INDEFINIDA";
string               glTendenciaMACD="INDEFINIDA";

//+------------------------------------------------------------------+
//| HANDLES (CORACAO) - TODO INDICADOR TEM QUE TER UM HANDLE         |
//+------------------------------------------------------------------+

int                  iMA_fast_handle=INVALID_HANDLE;
int                  iMA_slow_handle=INVALID_HANDLE;
int                  iMACD_handle=INVALID_HANDLE;

//+------------------------------------------------------------------+
//| BUFFERS - TODO INDICADOR TEM QUE TER O NUMERO DE BUFFER          |
//| PROPORICIONAL AO NUMERO DE LINHAS QUE ESSE INDICADOR TEM         |                                                |
//+------------------------------------------------------------------+

double               iMA_fast_buffer[];
double               iMA_slow_buffer[];

double               iMACD_main_buffer[];
double               iMACD_signal_buffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//| Expert initialization function                                   |
//|                                                                  |
//+------------------------------------------------------------------+
//
int OnInit()
  {
//+------------------------------------------------------------------+
//| SOLICITACAO DE MENSAGEM PARA LIMPAR EVENT                        |
//+------------------------------------------------------------------+

   MessageBox("Apague a guia EXPERT.");

//+------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS DE MONITORAMENTO                               |
//+------------------------------------------------------------------+

   glTicks=0;
   glContratos=0;
   glPositionType=0;
   glOpenPosition=false;

   glOrder=0;
   glTendenciaMM="INDEFINIDA";
   glTendenciaMACD="INDEFINIDA";

//+------------------------------------------------------------------+
//| SISTEMA DE SEGURNCA CONTRA BOBAGEM DO USUARIO (DEVE SER FEITA    |
//| PARA TODAS AS VARIAVEIS DE ENTRADA DO SISTEMA PARA PREVENIR O    |
//| USUARIO DE FAZER BOBAGEM)                                        |
//+------------------------------------------------------------------+

   if(contratos<=0)
     {
      Print("■ Número de contratos nao pode ser menor ou igual a 0");
      return(INIT_FAILED);
     }

   if(contratos>5000)
     {
      Print("■ Número de contratos nao pode ser maior que 5000");
      return(INIT_FAILED);
     }

   if(stopLoss<=0)
     {
      Print("■ StopLoss nao pode ser menor ou igual a 0");
      return(INIT_FAILED);
     }

   if(stopGain<=0)
     {
      Print("■ StopGain nao pode ser menor ou igual a 0");
      return(INIT_FAILED);
     }

//+------------------------------------------------------------------+
//| HANDLES                                                          |
//+------------------------------------------------------------------+

   iMA_fast_handle=iMA(_Symbol,_Period,iMA_fast_ma_period,iMA_fast_ma_shift,iMA_fast_ma_method,PRICE_CLOSE);

   iMA_slow_handle=iMA(_Symbol,_Period,iMA_slow_ma_period,iMA_slow_ma_shift,iMA_slow_ma_method,PRICE_CLOSE);

   iMACD_handle=iMACD(_Symbol,_Period,fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);

//+------------------------------------------------------------------+
//| ARRAYSETASSERIES                                                 |
//+------------------------------------------------------------------+

   ArraySetAsSeries(iMA_fast_buffer,true);
   ArraySetAsSeries(iMA_slow_buffer,true);

   ArraySetAsSeries(iMACD_main_buffer,true);
   ArraySetAsSeries(iMACD_signal_buffer,true);

//+------------------------------------------------------------------+
//| CHARTINDICATORADD                                                |
//+------------------------------------------------------------------+

   ChartIndicatorAdd(ChartID(),0,iMA_fast_handle);
   ChartIndicatorAdd(ChartID(),0,iMA_slow_handle);

   ChartIndicatorAdd(ChartID(),1,iMACD_handle);

//+------------------------------------------------------------------+
//| INICIALIZACAO REALIZADA COM SUCESSO                              |
//+------------------------------------------------------------------+

   Print("□ Inicialização realizada com sucesso");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//| Expert deinitialization function                                 |
//|                                                                  |
//+------------------------------------------------------------------+
//
void OnDeinit(const int reason)
  {
//+------------------------------------------------------------------+
//| INDICATOR RELEASE << HANDLE                                      |
//+------------------------------------------------------------------+

   IndicatorRelease(iMA_fast_handle);
   IndicatorRelease(iMA_slow_handle);

   IndicatorRelease(iMACD_handle);

//+------------------------------------------------------------------+
//| ARRAYFREE << BUFFER                                              |
//+------------------------------------------------------------------+

   ArrayFree(iMA_fast_buffer);
   ArrayFree(iMA_slow_buffer);

   ArrayFree(iMACD_main_buffer);
   ArrayFree(iMACD_signal_buffer);

//+------------------------------------------------------------------+
//| DELETE CHART INDICATOR                                           |
//+------------------------------------------------------------------+

   string iMA_fast_chart=ChartIndicatorName(0,0,0);
   ChartIndicatorDelete(0,0,iMA_fast_chart);

   string iMA_slow_chart=ChartIndicatorName(0,0,0);
   ChartIndicatorDelete(0,0,iMA_slow_chart);

   string iMACD_chart=ChartIndicatorName(0,1,0);
   ChartIndicatorDelete(0,1,iMACD_chart);

//+------------------------------------------------------------------+
//| DEINICIALIZACAO REALIZADA COM SUCESSO                            |
//+------------------------------------------------------------------+

   Print("□ Deinicialização executada. Acesse www.youdev.com.br");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//| Expert tick function                                             |
//|                                                                  |
//+------------------------------------------------------------------+
//
void OnTick()
  {
//+------------------------------------------------------------------+
//| CHART INITIALIZATION                                             |
//+------------------------------------------------------------------+

   ResetLastError();

// iMA_fast_buffer[0],iMA_fast_buffer[1],iMA_fast_buffer[2]
// iMA_slow_buffer[0],iMA_slow_buffer[1],iMA_slow_buffer[2]
// iMACD_main_buffer[0],iMACD_main_buffer[1],iMACD_main_buffer[2]
// iMACD_signal_buffer[0],iMACD_signal_buffer[1],iMACD_signal_buffer[2]

   CopyBuffer(iMA_fast_handle,0,0,3,iMA_fast_buffer);
   CopyBuffer(iMA_slow_handle,0,0,3,iMA_slow_buffer);
   CopyBuffer(iMACD_handle,0,0,3,iMACD_main_buffer);
   CopyBuffer(iMACD_handle,1,0,3,iMACD_signal_buffer);

//+------------------------------------------------------------------+
//| SINCRONIZA HORARIO SERVIDOR                                      |
//+------------------------------------------------------------------+

   MqlDateTime dt;
   TimeCurrent(dt);

//+------------------------------------------------------------------+
//| ATUALIZA VARIAVEIS DE HORARIOS                                   |
//+------------------------------------------------------------------+

   double loc_horarioAtual=dt.hour*60+dt.min;
   double loc_horarioAbertura=hAbertura*60+mAbertura;
   double loc_horarioFechamento=hFechamento*60+mFechamento-1;

//+------------------------------------------------------------------+
//| VERIFICA ABERTURA                                                |
//+------------------------------------------------------------------+

   if(loc_horarioAtual<loc_horarioAbertura)
     {
      Comment("[ROBO AGUARDANDO ABERTURA]");

      // EU PRECISO FAZER COM QUE TODAS AS VARIAVEIS
      // ESTEJAM "INICIALIZADAS" PARA QUE O ROBO FUNCIONE
      // COMO SE FOSSE O INICIO DO DIA E EU TIVESSE ACABADO
      // DE COLOCAR O ROBO PRA FUNCIONAR

      return;
     }

//+------------------------------------------------------------------+
//| VERIFICA FECHAMENTO                                              |
//+------------------------------------------------------------------+

   if(loc_horarioAtual>loc_horarioFechamento)
     {
      Comment("[ROBO ENCERROU O DIA]");

      // EU PRECISO FAZER ALGUMA COISA PARA QUE
      // O ROBO NAO DURMA POSICIONADO DE UM DIA
      // PARA O OUTRO

      return;
     }

//+------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS DE MONITORAMENTO                               |
//+------------------------------------------------------------------+

   glTicks=glTicks+1;
   glContratos=0;
   glPositionType=0;
   glOpenPosition=false;

   glOrder=0;

//+------------------------------------------------------------------+
//| SELECIONA POSICAO                                                |
//+------------------------------------------------------------------+

   glOpenPosition=PositionSelect(_Symbol);

   if(glOpenPosition == true)
     {
      glPositionType=PositionGetInteger(POSITION_TYPE);
      glContratos=PositionGetDouble(POSITION_VOLUME);
     }
   else
     {
      glPositionType=WRONG_VALUE;
     }

//+------------------------------------------------------------------+
//| ANALISA INDICADORES                                              |
//+------------------------------------------------------------------+

   if(iMA_fast_buffer[1]>iMA_slow_buffer[1])
      if(iMA_slow_buffer[2]>iMA_fast_buffer[2])
         glTendenciaMM="COMPRA";

   if(iMA_fast_buffer[0]<iMA_slow_buffer[0])
      if(iMA_fast_buffer[1]>iMA_slow_buffer[1])
         glTendenciaMM="VENDA";

//+------------------------------------------------------------------+

   if(iMACD_main_buffer[0]>iMACD_signal_buffer[0])
      if(iMACD_signal_buffer[1]>iMACD_main_buffer[1])
         glTendenciaMACD="COMPRA";

   if(iMACD_main_buffer[0]<iMACD_signal_buffer[0])
      if(iMACD_signal_buffer[1]>iMACD_main_buffer[1])
         glTendenciaMACD="VENDA";

//+------------------------------------------------------------------+
//| COMPRA                                                           |
//+------------------------------------------------------------------+

   if(glTendenciaMM=="COMPRA" && glTendenciaMACD=="COMPRA")
      glOrder=1;  // COMPRA

//+------------------------------------------------------------------+
//| HOLD COMPRA                                                      |
//+------------------------------------------------------------------+

   if(glOpenPosition == true && glPositionType==POSITION_TYPE_BUY && glOrder==1)
      glOrder=0;  // FAZ NADA

//+------------------------------------------------------------------+
//| VENDA                                                            |
//+------------------------------------------------------------------+

   if(glTendenciaMM=="VENDA" && glTendenciaMACD=="VENDA")
      glOrder=-1; // VENDA

//+------------------------------------------------------------------+
//| HOLD VENDA                                                       |
//+------------------------------------------------------------------+

   if(glOpenPosition == true && glPositionType==POSITION_TYPE_SELL && glOrder==-1)
      glOrder=0;  // FAZ NADA

//+------------------------------------------------------------------+
//| COMENTA GRAFICO                                                  |
//+------------------------------------------------------------------+

   Comment("glTicks: ",glTicks," | glContratos: ",glContratos," | glTendenciaMM: ",glTendenciaMM," | glTendenciaMACD: ",glTendenciaMACD);

//+------------------------------------------------------------------+
//| ORDER PLACEMENT (COLOCACAO DE ORDEM)                             |
//+------------------------------------------------------------------+

   if(glOrder==1 || glOrder==-1)
     {
      //+------------------------------------------------------------------+
      //| ATUALIZA PRECO                                                   |
      //+------------------------------------------------------------------+

      MqlTick price_info;                 // FORMA A ESTRUTURA DO PRECO
      ZeroMemory(price_info);             // LIMPADA NA ÁREA
      SymbolInfoTick(_Symbol,price_info); // POPULAR OS DADOS DO ATIVO "price_info"

      if(glOrder==1)       // COMPRA
        {
         Trade.Buy(contratos,_Symbol,price_info.ask,(price_info.ask-stopLoss),(price_info.ask+stopGain),"[C01]");
        }

      if(glOrder==-1)      // VENDA
        {
         Trade.Sell(contratos,_Symbol,price_info.bid,(price_info.bid+stopLoss),(price_info.bid-stopGain),"[V01]");
        }

     // Sleep(60*1000); // CONTANDO 60 SEGUNDOS SEMPRE // SEGURANCA
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
