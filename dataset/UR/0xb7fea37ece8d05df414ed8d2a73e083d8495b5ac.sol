 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}


interface BittechToken {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address receiver, uint amount) external;
    function burn(uint256 _value) external;
}


contract BittechSale is Ownable {
    using SafeMath for uint256;
    
    BittechToken public token;
    uint256 public minimalPriceUSD = 10000;  
    uint256 public ETHUSD = 300;
    uint256 public tokenPricePerUSD = 100;  
    
    address public constant fundsWallet = 0x1ba99f4F5Aa56684423a122D72990A7851AaFD9e;
    uint256 public startTime;
    uint256 public constant weekTime = 604800;
    
    constructor() public {
       token = BittechToken(0x6EE2EE1a5a257E6E7AdE7fe537617EaD9C7BD3D2);
       startTime = now;
    }
    
    function getBonus() public view returns (uint256) {
        
        if (now >= startTime.add(weekTime.mul(8))) {
            return 104;
        } else if (now >= startTime.add(weekTime.mul(7))) {
            return 106;
        } else if (now >= startTime.add(weekTime.mul(6))) {
            return 108;
        } else if (now >= startTime.add(weekTime.mul(5))) {
            return 110;
        } else if (now >= startTime.add(weekTime.mul(4))) {
            return 112;
        } else if (now >= startTime.add(weekTime.mul(3))) {
            return 114;
        } else if (now >= startTime.add(weekTime.mul(2))) {
            return 116;
        } else if (now >= startTime.add(weekTime)) {
            return 118;
        } else {
            return 120;
        }
        
    }
    
    function () external payable {
        require(msg.sender != address(0));
        require(msg.value.mul(ETHUSD) >= minimalPriceUSD.mul(10 ** 18).div(1000));
        
        uint256 tokens = msg.value.mul(ETHUSD).mul(getBonus()).mul(tokenPricePerUSD).div(100).div(100);
        token.transfer(msg.sender, tokens);
        
        if (now >= startTime.add(weekTime.mul(8))) {
            fundsWallet.transfer(address(this).balance);
            token.burn(token.balanceOf(address(this)));
        }
    }
    
    function sendTokens(address _to, uint256 _amount) external onlyOwner {
        token.transfer(_to, _amount);
    }
    
    function updatePrice(uint256 _ETHUSD) onlyOwner public {
        ETHUSD = _ETHUSD;
    }

    function updateMinimal(uint256 _minimalPriceUSD) onlyOwner public {
        minimalPriceUSD = _minimalPriceUSD;
    }

    function updateTokenPricePerUSD(uint256 _tokenPricePerUSD) onlyOwner public {
        tokenPricePerUSD = _tokenPricePerUSD;
    }
    
}