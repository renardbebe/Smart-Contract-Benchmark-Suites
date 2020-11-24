 

pragma solidity ^0.4.13;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

     
    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

 
contract ERC20Basic {
uint256 public totalSupply;
function balanceOf(address who) constant returns (uint256);
function transfer(address to, uint256 value) returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract ImpToken is ERC20Basic {
    function decimals() public returns (uint) {}
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

 

contract Sale is Haltable {
    using SafeMath for uint;

     
    ImpToken public impToken;

     
    address public destinationWallet;

     
    uint public oneImpInWei;

     
    uint public minBuyTokenAmount;

     
    uint public maxBuyTokenAmount;

     
    event Invested(address receiver, uint weiAmount, uint tokenAmount);

     
    function Sale(address _impTokenAddress, address _destinationWallet) {
        require(_impTokenAddress != 0);
        require(_destinationWallet != 0);

        impToken = ImpToken(_impTokenAddress);

        destinationWallet = _destinationWallet;
    }

     
    function() payable stopInEmergency {
        uint weiAmount = msg.value;
        address receiver = msg.sender;

        uint tokenMultiplier = 10 ** impToken.decimals();
        uint tokenAmount = weiAmount.mul(tokenMultiplier).div(oneImpInWei);

        require(tokenAmount > 0);

        require(tokenAmount >= minBuyTokenAmount && tokenAmount <= maxBuyTokenAmount);

         
        uint tokensLeft = getTokensLeft();

        require(tokensLeft > 0);

        require(tokenAmount <= tokensLeft);

         
        assignTokens(receiver, tokenAmount);

         
        destinationWallet.transfer(weiAmount);

         
        Invested(receiver, weiAmount, tokenAmount);
    }

     
    function setDestinationWallet(address destinationAddress) external onlyOwner {
        destinationWallet = destinationAddress;
    }

     
    function setMinBuyTokenAmount(uint value) external onlyOwner {
        minBuyTokenAmount = value;
    }

     
    function setMaxBuyTokenAmount(uint value) external onlyOwner {
        maxBuyTokenAmount = value;
    }

     
    function setOneImpInWei(uint value) external onlyOwner {
        require(value > 0);

        oneImpInWei = value;
    }

     
    function assignTokens(address receiver, uint tokenAmount) private {
        impToken.transfer(receiver, tokenAmount);
    }

     
    function getTokensLeft() public constant returns (uint) {
        return impToken.balanceOf(address(this));
    }
}