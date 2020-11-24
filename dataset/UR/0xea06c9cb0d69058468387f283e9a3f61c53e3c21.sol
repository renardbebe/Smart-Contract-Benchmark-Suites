 

pragma solidity ^ 0.4.10;

contract EthMultiplier {

 
 
 

 
 
 

 uint16 private id;
 uint16 private payoutIdx;
 address private owner;


 
 
 

 struct Investor {
  address addr;
  uint payout;
  bool paidOut;
 }
 mapping (uint16 => Investor) public investors;

 uint8 public feePercentage = 10;
 uint8 public payOutPercentage = 25;
 bool public smartContactForSale = true;
 uint public priceOfSmartContract = 25 ether;
 

 
 
 

 
 
 

 function EthMultiplier() { owner = msg.sender; }


 
 
 

 function()
 payable {
   
   
   
  msg.value >= priceOfSmartContract? 
   buySmartContract(): 
   invest();
 }


 
 
 

 event newInvestor(
  uint16 idx,
  address investor,
  uint amount,
  uint InvestmentNeededForPayOut
 );
 
 event lastInvestorPaidOut(uint payoutIdx);

 modifier entryCosts(uint min, uint max) {
  if (msg.value < min || msg.value > max) throw;
  _;
 }

 function invest()
 payable
 entryCosts(1 finney, 10 ether) {
   
   
   
  
  investors[id].addr = msg.sender;
  investors[id].payout = msg.value * (100 + payOutPercentage) / 100;

  owner.transfer(msg.value * feePercentage / 100);

  while (this.balance >= investors[payoutIdx].payout) {
   investors[payoutIdx].addr.transfer(investors[payoutIdx].payout);
   investors[payoutIdx++].paidOut = true;
  }
  
  lastInvestorPaidOut(payoutIdx - 1);

  newInvestor(
   id++,
   msg.sender,
   msg.value,
   checkInvestmentRequired(id, false)
  );
 }


 
 
 

 event manualCheckInvestmentRequired(uint id, uint investmentRequired);

 modifier awaitingPayOut(uint16 _investorId, bool _manual) {
  if (_manual && (_investorId > id || _investorId < payoutIdx)) throw;
  _;
 }

 function checkInvestmentRequired(uint16 _investorId, bool _clickYes)
 awaitingPayOut(_investorId, _clickYes)
 returns(uint amount) {
  for (uint16 iPayoutIdx = payoutIdx; iPayoutIdx <= _investorId; iPayoutIdx++) {
   amount += investors[iPayoutIdx].payout;
  }

  amount = (amount - this.balance) * 100 / (100 - feePercentage);

  if (_clickYes) manualCheckInvestmentRequired(_investorId, amount);
 }


 
 
 

 event newOwner(uint pricePayed);

 modifier isForSale() {
  if (!smartContactForSale 
  || msg.value < priceOfSmartContract 
  || msg.sender == owner) throw;
  _;
  if (msg.value > priceOfSmartContract)
   msg.sender.transfer(msg.value - priceOfSmartContract);
 }

 function buySmartContract()
 payable
 isForSale {
   
   
   

   
  owner.transfer(priceOfSmartContract);
  owner = msg.sender;
  smartContactForSale = false;
  newOwner(priceOfSmartContract);
 }


 
 
 

 modifier onlyOwner() {
  if (msg.sender != owner) throw;
  _;
 }


 
 
 

 event newFeePercentageIsSet(uint percentage);

 modifier FPLimits(uint8 _percentage) {
   
  if (_percentage > 25) throw;
  _;
 }

 function setFeePercentage(uint8 _percentage)
 onlyOwner
 FPLimits(_percentage) {
  feePercentage = _percentage;
  newFeePercentageIsSet(_percentage);
 }


 
 
 

 event newPayOutPercentageIsSet(uint percentageOnTopOfDeposit);

 modifier POTODLimits(uint8 _percentage) {
   
   
  if (_percentage > 100 || _percentage < feePercentage) throw;
  _;
 }

 function setPayOutPercentage(uint8 _percentageOnTopOfDeposit)
 onlyOwner
 POTODLimits(_percentageOnTopOfDeposit) {
  payOutPercentage = _percentageOnTopOfDeposit;
  newPayOutPercentageIsSet(_percentageOnTopOfDeposit);
 }


 
 
 

 event smartContractIsForSale(uint price);
 event smartContractSaleEnded();

 function putSmartContractOnSale(bool _sell)
 onlyOwner {
  smartContactForSale = _sell;
  _sell? 
   smartContractIsForSale(priceOfSmartContract): 
   smartContractSaleEnded();
 }


 
 
 

 event smartContractPriceIsSet(uint price);

 modifier SCPLimits(uint _price) {
   
  if (_price <= 10 ether) throw;
  _;
 }

 function setSmartContractPrice(uint _price)
 onlyOwner 
 SCPLimits(_price) {
  priceOfSmartContract = _price;
  smartContractPriceIsSet(_price);
 }


}