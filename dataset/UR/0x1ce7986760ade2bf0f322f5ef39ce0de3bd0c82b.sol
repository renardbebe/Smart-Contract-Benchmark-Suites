 

pragma solidity ^0.4.0;

 
 
contract PonzICO {
    address public owner;
    uint public total;
    mapping (address => uint) public invested;
    mapping (address => uint) public balances;
    address[] investors;

     
    event LogInvestment(address investor, uint amount);
    event LogWithdrawal(address investor, uint amount);

     
    modifier checkZeroBalance() { if (balances[msg.sender] == 0) { throw; } _;}
    modifier accreditedInvestor() { if (msg.value < 100 finney) { throw; } _;}

	 
     
	function PonzICO() {
		owner = msg.sender;
	}

     
     
    function ownerFee(uint amount) private returns (uint fee) {
        if (total < 200000 ether) {
            fee = amount/2;
            balances[owner] += fee;
        }
        return;
    }

     
     
    function withdraw()
    checkZeroBalance()
    {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        if (!msg.sender.send(amount)) {
            balances[msg.sender] = amount;
        } else {
            LogWithdrawal(msg.sender, amount);
        }
    }

     
    function reinvest()
    checkZeroBalance()
    {
        uint dividend = balances[msg.sender];
        balances[msg.sender] = 0;
        uint fee = ownerFee(dividend);
        dividend -= fee;
        for (uint i = 0; i < investors.length; i++) {
            balances[investors[i]] += dividend * invested[investors[i]] / total;
        }
        invested[msg.sender] += (dividend + fee);
        total += (dividend + fee);
        LogInvestment(msg.sender, dividend+fee);
    }

	 
     
     
	function invest() payable
    accreditedInvestor()
    {
         
        uint dividend = msg.value;
        uint fee = ownerFee(dividend);
        dividend -= fee;
         
        for (uint i = 0; i < investors.length; i++) {
            balances[investors[i]] += dividend * invested[investors[i]] / total;
        }

         
        if (invested[msg.sender] == 0) {
            investors.push(msg.sender);
            invested[msg.sender] = msg.value;
        } else {
            invested[msg.sender] += msg.value;
        }
        total += msg.value;
        LogInvestment(msg.sender, msg.value);
	}

     
     
    function () { throw; }
}