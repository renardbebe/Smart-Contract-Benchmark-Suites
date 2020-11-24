 

pragma solidity ^0.4.19;

contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool);
}


contract ICO is Ownable {
    
    using SafeMath for uint256;
    
    string public website = "www.propvesta.com";
    uint256 public rate;
    uint256 public tokensSold;
    address public fundsWallet = 0x304f970BaA307238A6a4F47caa9e0d82F082e3AD;
    
    TokenInterface public constant PROV = TokenInterface(0x409Ec1FCd524480b3CaDf4331aF21A2cB3Db68c9);
    
    function ICO() public {
        rate = 20000000;
    }
    
    function changeRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0 && rate != _newRate);
        rate = _newRate;
    }
    
    function changeFundsWallet(address _fundsWallet) public onlyOwner returns(bool) {
        fundsWallet = _fundsWallet;
        return true;
    }
    
    event TokenPurchase(address indexed investor, uint256 tokensPurchased);
    
    function buyTokens(address _investor) public payable {
        require(msg.value >= 1e16);
        uint256 exchangeRate = rate;
        uint256 bonus = 0;
        uint256 investment = msg.value;
        uint256 remainder = 0;
        if(investment >= 1e18 && investment < 2e18) {
            bonus = 30;
        } else if(investment >= 2e18 && investment < 3e18) {
            bonus = 35;
        } else if(investment >= 3e18 && investment < 4e18) {
            bonus = 40;
        } else if(investment >= 4e18 && investment < 5e18) {
            bonus = 45;
        } else if(investment >= 5e18) {
            bonus = 50;
        }
        exchangeRate = rate.mul(bonus).div(100).add(rate);
        uint256 toTransfer = 0;
        if(investment > 10e18) {
            uint256 bonusCap = 10e18;
            toTransfer = bonusCap.mul(exchangeRate);
            remainder = investment.sub(bonusCap);
            toTransfer = toTransfer.add(remainder.mul(rate));
        } else {
            toTransfer = investment.mul(exchangeRate);
        }
        PROV.transfer(_investor, toTransfer);
        TokenPurchase(_investor, toTransfer);
        tokensSold = tokensSold.add(toTransfer);
        fundsWallet.transfer(investment);
    }
    
    function() public payable {
        buyTokens(msg.sender);
    }
    
    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }
    
    event TokensWithdrawn(uint256 totalPROV);
    
    function withdrawPROV(uint256 _value) public onlyOwner {
        PROV.transfer(fundsWallet, _value);
        TokensWithdrawn(_value);
    }
}