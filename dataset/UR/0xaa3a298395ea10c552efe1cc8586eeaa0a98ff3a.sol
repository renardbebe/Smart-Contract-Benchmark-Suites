 

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract BonusCalculator {
    function getBonus() constant returns (uint);
}

contract GoldeaBonusCalculator is BonusCalculator, Ownable {
    uint public start;
    uint public end;
    uint constant period = 86400 * 7;
    mapping (uint => uint8) bonuses;

    function GoldeaBonusCalculator(uint256 _start, uint256 _end) {
        start = _start;
        end = _end;
        bonuses[0] = 30;
        bonuses[1] = 20;
        bonuses[3] = 10;
    }

    function getBonus() constant returns (uint) {
        assert(now > start);
        assert(now < end);

        uint week = (now - start) / period;
        uint8 foundBonus = bonuses[week];
        if (foundBonus != 0) {
            return foundBonus;
        } else {
            return 5;
        }
    }

    function setStart(uint256 _start) onlyOwner() {
        start = _start;
    }

    function setEnd(uint256 _end) onlyOwner() {
        end = _end;
    }
}