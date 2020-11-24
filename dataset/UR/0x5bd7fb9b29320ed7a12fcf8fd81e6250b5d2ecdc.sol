 

pragma solidity ^0.4.24;

 

contract ZethrInterface {
  function balanceOf(address who) public view returns (uint);
  function transfer(address _to, uint _value) public returns (bool);
	function withdraw(address _recipient) public;
}

 
contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

 
contract ZlotsJackpotHoldingContract is ERC223Receiving {

   

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  } 

   
  modifier onlyZlots() {
    require(msg.sender == zlots);
    _;
  }

	 

   
  event JackpotPayout(
    uint amountPaid,
    address winner,
    uint payoutNumber
  );

	 

   
  address owner;
  address zlots;
  ZethrInterface Zethr = ZethrInterface(0xD48B633045af65fF636F3c6edd744748351E020D);

   
  uint payoutNumber = 0;  
  uint totalPaidOut = 0;  

   

	 
  constructor (address zlotsAddress) public {
    owner = msg.sender;
    zlots = zlotsAddress;
  }

   
   
  function () public payable { }

   
   
  function payOutWinner(address winner) public onlyZlots {
		 
 		uint payoutAmount = Zethr.balanceOf(address(this)) / 2;
		Zethr.transfer(winner, payoutAmount);	

		 
		payoutNumber += 1;
		totalPaidOut += payoutAmount / 2;

		emit JackpotPayout(payoutAmount / 2, winner, payoutNumber);
  }

	 
	function pullTokens(address _to) public onlyOwner {
    uint balance = Zethr.balanceOf(address(this));
    Zethr.transfer(_to, balance);
	}

   
  function setZlotsAddress(address zlotsAddress) public onlyOwner {
    zlots = zlotsAddress;
  }

   
   
  function tokenFallback(address  , uint  , bytes ) public returns (bool) {
     
  }

	 
  function getJackpot() public view returns (uint) {
    return Zethr.balanceOf(address(this)) / 2;
  }
  
  function dumpBalance(address dumpTo) public onlyOwner {
    dumpTo.transfer(address(this).balance);
  }
}