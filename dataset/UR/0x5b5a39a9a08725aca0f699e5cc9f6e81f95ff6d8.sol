 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.23;

 
 
contract niguezRandomityEngine {
  function ra() external view returns (uint256);
	function rx() external view returns (uint256);
}

contract usingNRE {

  niguezRandomityEngine internal nre = niguezRandomityEngine(0x031eaE8a8105217ab64359D4361022d0947f4572);
    
  function ra() internal view returns (uint256) {
        return nre.ra();
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

  contract SPACEDICE is Mortal, usingNRE{
  uint minBet = 1000000000000000;  

  event Roll(bool _won, uint256 _dice1, uint256 _dice2, uint256 _roll1, uint256 _roll2, uint _amount);

  constructor() payable public {}

  function() public {  
    revert();
  }

  function bet(uint _diceOne, uint _diceTwo) payable public {
    require(tx.origin == msg.sender); 
    require(_diceOne > 0 && _diceOne <= 6);
    require(_diceTwo > 0 && _diceTwo <= 6);
    require(msg.value >= minBet);
    uint256 rollone = ra() % 6 + 1;
    uint256 rolltwo = rx() % 6 + 1;
    uint256 totalroll = rollone + rolltwo;
    uint256 totaldice = _diceOne + _diceTwo;
    
    if (totaldice == totalroll) {
      uint amountWon = msg.value;
       
      if(_diceOne==_diceTwo){
         
        if(rollone == rolltwo){ 
          amountWon = msg.value*30; 
          if(rollone==1 || rolltwo==6) amountWon = msg.value*33; 
          emit Roll(true, _diceOne, _diceTwo, rollone, rolltwo, amountWon);
        }
         
        else
        {
          emit Roll(false, _diceOne, _diceTwo, rollone, rolltwo, 0);
        }
      }
       
      else{
            if(totalroll==7) amountWon = msg.value*5; 
            if(totalroll==6 || totalroll==8) amountWon = msg.value*6; 
            if(totalroll==5 || totalroll==9) amountWon = msg.value*8; 
            if(totalroll==4 || totalroll==10) amountWon = msg.value*10; 
            if(totalroll==3 || totalroll==11) amountWon = msg.value*16; 
            emit Roll(true, _diceOne, _diceTwo, rollone, rolltwo, amountWon);
      }
      if(!msg.sender.send(amountWon)) revert();
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