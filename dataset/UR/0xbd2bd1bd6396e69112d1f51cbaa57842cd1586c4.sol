 

pragma solidity ^0.4.0;

contract GameEthContractV1{

address owner;
mapping (address => uint256) deposits;
mapping (address => uint256) totalPaid;
mapping (address => uint256) paydates;
mapping (address => uint256) notToPay;

uint minWei = 40000000000000000;  
uint secInDay = 86400;  
uint gasForPayout = 50000;  
uint lastBlockTime;
uint inCommission = 3;  

event DepositIn(
        address indexed _from,
        uint256 _value,
        uint256 _date
    );
    
event PayOut(
        address indexed _from,
        uint256 _value,
        uint256 _date
    );
    

constructor(address _owner) public {
	owner = _owner; 
	lastBlockTime = now;
}

 
function () public payable{
 	require(now >= lastBlockTime && msg.value >= minWei);  
 	lastBlockTime = now;  
 	uint256 com = msg.value/100*inCommission;  
 	uint256 amount = msg.value - com;  
 	if (deposits[msg.sender] > 0){
 		 
 		uint256 daysGone = (now - paydates[msg.sender]) / secInDay;	 
 		notToPay[msg.sender] += amount/100*daysGone;  
 	}else{
 		 
 		paydates[msg.sender] = now;  
 	}
    deposits[msg.sender] += amount;  
    emit DepositIn(msg.sender, msg.value, now);  
    owner.transfer(com);  
}

 
function  depositForRecipent(address payoutAddress) public  payable{
 	require(now >= lastBlockTime && msg.value >= minWei);  
 	lastBlockTime = now;  
 	uint256 com = msg.value/100*inCommission;  
 	uint256 amount = msg.value - com;  
 	if (deposits[payoutAddress] > 0){
 		 
 		uint256 daysGone = (now - paydates[payoutAddress]) / secInDay;	 
 		notToPay[payoutAddress] += amount/100*daysGone;  
 	}else{
 		 
 		paydates[payoutAddress] = now;  
 	}
    deposits[payoutAddress] += amount;  
    emit DepositIn(payoutAddress, msg.value, now);  
    owner.transfer(com);  
}

 
function transferOwnership(address newOwnerAddress) public {
	require (msg.sender == owner);  
	owner = newOwnerAddress;
}


 
function payOut() public {
		require(deposits[msg.sender] > 0);  
		require(paydates[msg.sender] < now);  
		uint256 payForDays = (now - paydates[msg.sender]) / secInDay;  
        require(payForDays >= 30);
		pay(msg.sender,false,payForDays);  
}

 
 
function payOutFor(address _recipient) public {
		require(msg.sender == owner && deposits[_recipient] > 0);  
		require(paydates[_recipient] < now);  
		uint256 payForDays = (now - paydates[_recipient]) / secInDay;  
        require(payForDays >= 30); 
		pay(_recipient, true,payForDays);  
}


function pay(address _recipient, bool calcGasPrice,uint256 payForDays) private {
        uint256 payAmount = 0;
        payAmount = deposits[_recipient]/100*payForDays - notToPay[_recipient];  
        if (payAmount >= address(this).balance){
        	payAmount = address(this).balance;
        }
        assert(payAmount > 0);  
        if (calcGasPrice){
        	 
        	uint256 com = gasForPayout * tx.gasprice;  
        	assert(com < payAmount);    
        	payAmount = payAmount - com;  
        	owner.transfer(com);  
        }
        paydates[_recipient] = now;  
        _recipient.transfer(payAmount);  
        totalPaid[_recipient] += payAmount;  
        notToPay[_recipient] = 0;  
        emit PayOut(_recipient, payAmount, now);   
}



function totalDepositOf(address _sender) public constant returns (uint256 deposit) {
        return deposits[_sender];
}

function lastPayDateOf(address _sender) public constant returns (uint256 secFromEpoch) {
        return paydates[_sender];
}

function totalPaidOf(address _sender) public constant returns (uint256 paid) {
        return totalPaid[_sender];
}

}