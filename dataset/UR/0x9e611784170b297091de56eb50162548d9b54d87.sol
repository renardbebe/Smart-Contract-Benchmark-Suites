 

pragma solidity ^0.4.8;

contract Crowdsale {
	function invest(address receiver) payable{}
}
 
contract Investment{
	Crowdsale public ico;
	address[] public investors;
	mapping(address => uint) public balanceOf;


	 
	function Investment(){
		ico = Crowdsale(0x7be89db09b0c1023fd0407b24b98810ae97f61c1);
	}

	 
	function() payable{
		if(!isInvestor(msg.sender)){
			investors.push(msg.sender);
		}
		balanceOf[msg.sender] += msg.value;
	}

	 
	function isInvestor(address who) returns (bool){
		for(uint i = 0; i< investors.length; i++)
			if(investors[i] == who)
				return true;
		return false;
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
		msg.sender.send(balanceOf[msg.sender]);
	}

	 
	function getNumInvestors() constant returns(uint){
		return investors.length;
	}

}