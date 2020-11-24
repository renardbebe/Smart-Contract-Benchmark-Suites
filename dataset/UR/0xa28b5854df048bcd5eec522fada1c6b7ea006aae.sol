 

 
 
 

pragma solidity ^0.4.23;

 
 
contract niguezRandomityEngine {

  function ra() external view returns (uint256);
	function rb() external view returns (uint256);
	function rc() external view returns (uint256);
	function rd() external view returns (uint256);
	function re() external view returns (uint256);
	function rf() external view returns (uint256);
	function rg() external view returns (uint256);
	function rh() external view returns (uint256);
	function ri() external view returns (uint256);
	function rj() external view returns (uint256);
	function rk() external view returns (uint256);
	function rl() external view returns (uint256);
	function rm() external view returns (uint256);
	function rn() external view returns (uint256);
	function ro() external view returns (uint256);
	function rp() external view returns (uint256);
	function rq() external view returns (uint256);
	function rr() external view returns (uint256);
	function rs() external view returns (uint256);
	function rt() external view returns (uint256);
	function ru() external view returns (uint256);
	function rv() external view returns (uint256);
	function rw() external view returns (uint256);
	function rx() external view returns (uint256);
}

contract usingNRE {

  niguezRandomityEngine internal nre = niguezRandomityEngine(0x031eaE8a8105217ab64359D4361022d0947f4572);
    
  function ra() internal view returns (uint256) {
        return nre.ra();
    }
	
	function rb() internal view returns (uint256) {
        return nre.rb();
    }
	
	function rc() internal view returns (uint256) {
        return nre.rc();
    }
	
	function rd() internal view returns (uint256) {
        return nre.rd();
    }
	
	function re() internal view returns (uint256) {
        return nre.re();
    }
	
	function rf() internal view returns (uint256) {
        return nre.rf();
    }
	
	function rg() internal view returns (uint256) {
        return nre.rg();
    }
	
	function rh() internal view returns (uint256) {
        return nre.rh();
    }
	
	function ri() internal view returns (uint256) {
        return nre.ri();
    }
	
	function rj() internal view returns (uint256) {
        return nre.rj();
    }
	
	function rk() internal view returns (uint256) {
        return nre.rk();
    }
	
	function rl() internal view returns (uint256) {
        return nre.rl();
    }
	
	function rm() internal view returns (uint256) {
        return nre.rm();
    }
	
	function rn() internal view returns (uint256) {
        return nre.rn();
    }
	
	function ro() internal view returns (uint256) {
        return nre.ro();
    }
	
	function rp() internal view returns (uint256) {
        return nre.rp();
    }
	
	function rq() internal view returns (uint256) {
        return nre.rq();
    }
	
	function rr() internal view returns (uint256) {
        return nre.rr();
    }
	
	function rs() internal view returns (uint256) {
        return nre.rs();
    }
	
	function rt() internal view returns (uint256) {
        return nre.rt();
    }
	
	function ru() internal view returns (uint256) {
        return nre.ru();
    }
	
	function rv() internal view returns (uint256) {
        return nre.rv();
    }
	
	function rw() internal view returns (uint256) {
        return nre.rw();
    }
	
	function rx() internal view returns (uint256) {
        return nre.rx();
    }
}

contract Ownable {
  address owner;
  constructor() public {
  owner = msg.sender;
  }

  modifier onlyOwner {
  require(msg.sender == owner);
  _;
  }
}

  contract Mortal is Ownable {
  function kill() public onlyOwner {
  selfdestruct(owner);
  }
}

  contract FIREDICE is Mortal, usingNRE{
  uint minBet = 1000000000000000;  

  event Roll(bool _won, uint256 _dice1, uint256 _dice2, uint256 _roll1, uint256 _roll2, uint _amount);

  constructor() payable public {}

  function() public {  
    revert();
  }

  function bet(uint _diceOne, uint _diceTwo) payable public {
    require(_diceOne > 0 && _diceOne <= 6);
    require(_diceTwo > 0 && _diceTwo <= 6);
    require(msg.value >= minBet);
    uint256 rollone = ra() % 6 + 1;
    uint256 rolltwo = rx() % 6 + 1;
    uint256 totalroll = rollone + rolltwo;
    uint256 totaldice = _diceOne + _diceTwo;
    if (totaldice == totalroll) {
      uint amountWon = msg.value*2; 
      if(rollone==rolltwo && _diceOne==_diceTwo) amountWon = msg.value*8; 
      if(totalroll==2 || totalroll==12) amountWon = msg.value*30; 
      if(!msg.sender.send(amountWon)) revert();
      emit Roll(true, _diceOne, _diceTwo, rollone, rolltwo, amountWon);
    }
    else {
      emit Roll(false, _diceOne, _diceTwo, rollone, rolltwo, 0);
    }
  }

  function checkContractBalance() public view returns(uint) {
    return address(this).balance;
  }

   
  function collect(uint _amount) public onlyOwner {
    require(address(this).balance > _amount);
    owner.transfer(_amount);
  }
}