 

pragma solidity ^0.4.25;

contract Ownable {
    
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        emit OwnershipTransferred(owner, _newOwner);
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



contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract UsdPrice {
    function USD(uint _id) public constant returns (uint256);
}


contract ICO is Ownable {
    
    using SafeMath for uint256;
    
    UsdPrice public fiat;
    ERC20 public ELYC;
    
    uint256 private tokenPrice;
    uint256 private tokensSold;
    
    constructor() public {
        fiat = UsdPrice(0x8055d0504666e2B6942BeB8D6014c964658Ca591); 
        ELYC = ERC20(0xFD96F865707ec6e6C0d6AfCe1f6945162d510351); 
        tokenPrice = 8;  
        tokensSold = 0;
    }
    
    
     
    event PurchaseMade(address indexed by, uint256 tokensPurchased, uint256 tokenPricee);
    event WithdrawOfELYC(address recipient, uint256 tokensSent);
    event TokenPriceChanged(uint256 oldPrice, uint256 newPrice);
     
     

       
     
     
    function getTokenPriceInETH() public view returns(uint256) {
        return fiat.USD(0).mul(tokenPrice);
    }
    
    
     
    function getTokenPriceInUsdCents() public view returns(uint256) {
        return tokenPrice;
    }
    
    
     
    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }
    
    
     
    function getRate() public view returns(uint256) {
        uint256 e18 = 1e18;
        return e18.div(getTokenPriceInETH());
    }


     
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
     
    function buyTokens(address _investor) public payable returns(bool) {
        require(_investor != address(0) && msg.value > 0);
        ELYC.transfer(_investor, msg.value.mul(getRate()));
        tokensSold = tokensSold.add(msg.value.mul(getRate()));
        owner.transfer(msg.value);
        emit PurchaseMade(_investor, msg.value.mul(getRate()), getTokenPriceInETH());
        return true;
    }
    
    
     
     
     
    function withdrawAnyERC20(address _addressOfToken, address _recipient) public onlyOwner {
        ERC20 token = ERC20(_addressOfToken);
        token.transfer(_recipient, token.balanceOf(address(this)));
    }
    

     
    function withdrawELYC(address _recipient, uint256 _value) public onlyOwner {
        require(_recipient != address(0));
        ELYC.transfer(_recipient, _value);
        emit WithdrawOfELYC(_recipient, _value);
    }
    
    
     
    function changeTokenPriceInCent(uint256 _newTokenPrice) public onlyOwner {
        require(_newTokenPrice != tokenPrice && _newTokenPrice > 0);
        emit TokenPriceChanged(tokenPrice, _newTokenPrice);
        tokenPrice = _newTokenPrice;
    }
    
    
     
    function terminateICO() public onlyOwner {
        require(ELYC.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}