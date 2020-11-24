 

pragma solidity ^0.4.13;

contract Calculator {
    function getAmount(uint value) constant returns (uint);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

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

contract PriceCalculator is Calculator, Ownable {
    using SafeMath for uint256;

    uint256 public price;

    function PriceCalculator(uint256 _price) {
        price = _price;
    }

    function getAmount(uint value) constant returns (uint) {
        return value.div(price);
    }

    function setPrice(uint256 _price) onlyOwner {
        price = _price;
    }
}