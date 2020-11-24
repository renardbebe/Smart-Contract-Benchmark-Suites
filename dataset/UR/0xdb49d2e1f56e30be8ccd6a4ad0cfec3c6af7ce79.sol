 

 

pragma solidity ^0.4.15;

contract ICO {
	function invest(address receiver) payable {}
}

contract SafeMath {

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
}

contract owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function owned() {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract mortal is owned {
  function close() onlyOwner {
		require(address(this).balance == 0);
    selfdestruct(owner);
  }
}

contract Reservation2 is mortal, SafeMath {
	ICO public ico;
	address[] public investors;
	mapping(address => uint) public balanceOf;
	mapping(address => bool) invested;
	uint public weiCap;


	 
	function Reservation2(address _icoAddr, uint _etherCap) {
		ico = ICO(_icoAddr);
		weiCap = safeMul(_etherCap, 1 ether);
	}

	 
	function() payable {
		require(msg.value > 0);

		require(weiCap == 0 || this.balance <= weiCap);

		if (!invested[msg.sender]) {
			investors.push(msg.sender);
			invested[msg.sender] = true;
		}
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value);
	}

	 
	function buyTokens(uint _from, uint _to) onlyOwner {
		require(address(ico)!=0x0); 
		uint amount;
		if (_to > investors.length)
			_to = investors.length;
		for (uint i = _from; i < _to; i++) {
			if (balanceOf[investors[i]] > 0) {
				amount = balanceOf[investors[i]];
				delete balanceOf[investors[i]];
				ico.invest.value(amount)(investors[i]);
			}
		}
	}

	 
	function withdraw() {
		uint amount = balanceOf[msg.sender];
		require(amount > 0);
		
		balanceOf[msg.sender] = 0;
		msg.sender.transfer(amount);
	}

	 
	function getNumInvestors() constant returns(uint) {
		return investors.length;
	}
	
	function setICO(address _icoAddr) onlyOwner {
		ico = ICO(_icoAddr);
	}

}