 

 

pragma solidity ^0.4.8;

contract Crowdsale {
	function invest(address receiver) payable{}
}

contract SafeMath {
   
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Investment is SafeMath{
	Crowdsale public ico;
	address[] public investors;
	mapping(address => uint) public balanceOf;
	mapping(address => bool) invested;


	 
	function Investment(){
		ico = Crowdsale(0x362bb67f7fdbdd0dbba4bce16da6a284cf484ed6);
	}

	 
	function() payable{
		if(msg.value > 0){
			 
			 
			if(!invested[msg.sender]){
				investors.push(msg.sender);
				invested[msg.sender] = true;
			}
			balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value);
		}
	}



	 
	function buyTokens(uint from, uint to){
		uint amount;
		if(to>investors.length)
			to = investors.length;
		for(uint i = from; i < to; i++){
			if(balanceOf[investors[i]]>0){
				amount = balanceOf[investors[i]];
				delete balanceOf[investors[i]];
				ico.invest.value(amount)(investors[i]);
			}
		}
	}

	 
	function withdraw(){
		uint amount = balanceOf[msg.sender];
		balanceOf[msg.sender] = 0;
		if(!msg.sender.send(amount))
			balanceOf[msg.sender] = amount;
	}

	 
	function getNumInvestors() constant returns(uint){
		return investors.length;
	}

}