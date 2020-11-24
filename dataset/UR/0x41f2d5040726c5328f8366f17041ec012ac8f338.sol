 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract EthVenturesFinal {
struct InvestorArray {
address etherAddress;
uint amount;
uint percentage_ownership;  
}
InvestorArray[] public investors;
 
uint public total_investors=0;
uint public fees=0;
uint public balance = 0;
uint public totaldeposited=0;
uint public totalpaidout=0;
uint public totaldividends=0;
string public Message_To_Investors="Welcome to EthVenturesFinal! New and improved! All bugs fixed!";  
address public owner;
 
modifier manager { if (msg.sender == owner) _ }
 
function EthVenturesFinal() {
owner = msg.sender;
}
 
function() {
Enter();
}
 
function Enter() {
 
 
if (msg.value < 2 ether)
{
uint PRE_payout;
uint PRE_amount=msg.value;
owner.send(PRE_amount/100);  
totalpaidout+=PRE_amount/100;  
PRE_amount-=PRE_amount/100;  
 
if(investors.length !=0 && PRE_amount !=0)
{
for(uint PRE_i=0; PRE_i<investors.length;PRE_i++)
{
PRE_payout = PRE_amount * investors[PRE_i].percentage_ownership /10000000000;  
investors[PRE_i].etherAddress.send(PRE_payout);  
totalpaidout += PRE_payout;  
totaldividends+=PRE_payout;  
}
Message_To_Investors="Dividends have been paid out!";
}
}
 
else
{
 
uint amount=msg.value;
fees = amount / 100;  
totaldeposited+=amount;  
amount-=amount/100;
balance += amount;  
 
bool alreadyinvestor =false;
uint alreadyinvestor_id;
 
for(uint i=0; i<investors.length;i++)
{
if( msg.sender== investors[i].etherAddress)  
{
alreadyinvestor=true;  
alreadyinvestor_id=i;  
break;  
}
}
 
if(alreadyinvestor==false)
{
total_investors=investors.length+1;
investors.length += 1;  
investors[investors.length-1].etherAddress = msg.sender;
investors[investors.length-1].amount = amount;
investors[investors.length-1].percentage_ownership = amount /totaldeposited*10000000000;
Message_To_Investors="New Investor has joined us!";  

for(uint k=0; k<investors.length;k++)  
{investors[k].percentage_ownership = investors[k].amount/totaldeposited*10000000000;}  

}
else  
{
investors[alreadyinvestor_id].amount += amount;
investors[alreadyinvestor_id].percentage_ownership = investors[alreadyinvestor_id].amount/totaldeposited*10000000000;
}
 
if (fees != 0)
{
owner.send(fees);  
totalpaidout+=fees;  
}

}
}
 
 
function NewOwner(address new_owner) manager
{
owner = new_owner;
Message_To_Investors="The contract has a new manager!";
}
 
 
 
function Emergency() manager
{
if(balance!=0)
{
owner.send(balance);
balance=0;
Message_To_Investors="Emergency Withdraw has been issued!";
}
}
 
 
function EmergencyBalanceReset(uint new_balance) manager
{
balance = new_balance;
Message_To_Investors="The Balance has been edited by the Manager!";
}
 
 
function NewMessage(string new_sms) manager
{
Message_To_Investors = new_sms;
}
 
 
 
function NewManualInvestor(address new_investor , uint new_amount) manager
{
total_investors=investors.length+1;
investors.length += 1;  
investors[investors.length-1].etherAddress = new_investor;
investors[investors.length-1].amount = new_amount;
investors[investors.length-1].percentage_ownership = new_amount /totaldeposited*10000000000;

Message_To_Investors="New manual Investor has been added by the Manager!";  
 
}
 
 
function ManualDeposit() manager
{
totaldeposited+=msg.value;  
balance+=msg.value;  

Message_To_Investors = "Manual Deposit received from the Manager";
}

 
}