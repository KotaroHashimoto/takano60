//+------------------------------------------------------------------+
//|                                                     takano60.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

input int Magic_Number = 1;
input double Entry_Lot = 0.1;
extern double TP_pips = 30;
extern double Trail_pips = 20;
extern double Cross_Det_Percentage = 18;

string thisSymbol;
int lastExitHour;

int getOrdersTotal() {

  int count = 0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        count ++;
      }
    }
  }

  return count;
}

bool readyToEnter(double& bottom, double& upper, double& open, double& close) {

  double low2 = iLow(thisSymbol, PERIOD_H1, 2);
  double low1 = iLow(thisSymbol, PERIOD_H1, 1);
  double high2 = iHigh(thisSymbol, PERIOD_H1, 2);
  double high1 = iHigh(thisSymbol, PERIOD_H1, 1);
  
  open = iOpen(thisSymbol, PERIOD_H1, 1);
  close = iClose(thisSymbol, PERIOD_H1, 1);

  if(low1 < low2 && high2 < high1 && Cross_Det_Percentage * (high1 - low1) < MathAbs(open - close)) {
    bottom = low1;
    upper = high1;
    return True;
  }
  else {
    bottom = 0;
    upper = 0;
    return False;
  }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

  thisSymbol = Symbol();
  lastExitHour = -1;
  
  TP_pips *= 10.0 * Point;
  Trail_pips *= 10.0 * Point;
  
  Cross_Det_Percentage *= 0.01;
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  if(getOrdersTotal() == 0) {
  
    if(lastExitHour == Hour()) {
      return;
    }
    else {
      lastExitHour = -1;;
    }
  
    double bottom, upper, open, close;
    if(readyToEnter(bottom, upper, open, close)) {

      if(upper < Bid && open < close) {
        int ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot, NormalizeDouble(Ask, Digits), 3, 
                               NormalizeDouble(bottom, Digits), NormalizeDouble(Ask + TP_pips, Digits), NULL, Magic_Number);
      }
      else if(Ask < bottom && open > close) {
        int ticket = OrderSend(Symbol(), OP_SELL, Entry_Lot, NormalizeDouble(Bid, Digits), 3, 
                               NormalizeDouble(upper, Digits), NormalizeDouble(Bid - TP_pips, Digits), NULL, Magic_Number);
      }
    }
  }
  else {
    lastExitHour = Hour();

    for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS)) {
        if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
          if(OrderType() == OP_BUY) {
            if(OrderOpenPrice() + Trail_pips < Bid && OrderStopLoss() < OrderOpenPrice()) {
              bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
            }
          }
          
          else if(OrderType() == OP_SELL) {
            if(Ask < OrderOpenPrice() - Trail_pips && OrderOpenPrice() < OrderStopLoss()) {
              bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
            }
          }
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
