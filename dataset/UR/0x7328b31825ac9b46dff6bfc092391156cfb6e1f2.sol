 

pragma solidity ^0.4.23;

 
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

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
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
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract NamedToken is ERC20 {
   string public name;
   string public symbol;
}

contract BitWich is Pausable {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    
    event LogBought(address indexed buyer, uint buyCost, uint amount);
    event LogSold(address indexed seller, uint sellValue, uint amount);
    event LogPriceChanged(uint newBuyCost, uint newSellValue);

     
    ERC20 public erc20Contract;

     
    uint public netAmountBought;
    
     
    uint public buyCost;
    
     
    uint public sellValue;
    
    constructor(uint _buyCost, 
                uint _sellValue,
                address _erc20ContractAddress) public {
        require(_buyCost > 0);
        require(_sellValue > 0);
        
        buyCost = _buyCost;
        sellValue = _sellValue;
        erc20Contract = NamedToken(_erc20ContractAddress);
    }
    
     
    function tokenName() external view returns (string) {
        return NamedToken(erc20Contract).name();
    }
    
    function tokenSymbol() external view returns (string) {
        return NamedToken(erc20Contract).symbol();
    }
    
    function amountForSale() external view returns (uint) {
        return erc20Contract.balanceOf(address(this));
    }
    
     
    function getBuyCost(uint _amount) external view returns(uint) {
        uint cost = _amount.div(buyCost);
        if (_amount % buyCost != 0) {
            cost = cost.add(1);  
        }
        return cost;
    }
    
     
    function getSellValue(uint _amount) external view returns(uint) {
        return _amount.div(sellValue);
    }
    
     
     
    function buy(uint _minAmountDesired) external payable whenNotPaused {
        processBuy(msg.sender, _minAmountDesired);
    }
    
     
     
     
    function sell(uint _amount, uint _weiExpected) external whenNotPaused {
        processSell(msg.sender, _amount, _weiExpected);
    }
    
     
     
    function processBuy(address _buyer, uint _minAmountDesired) internal {
        uint amountPurchased = msg.value.mul(buyCost);
        require(erc20Contract.balanceOf(address(this)) >= amountPurchased);
        require(amountPurchased >= _minAmountDesired);
        
        netAmountBought = netAmountBought.add(amountPurchased);
        emit LogBought(_buyer, buyCost, amountPurchased);

        erc20Contract.safeTransfer(_buyer, amountPurchased);
    }
    
     
    function processSell(address _seller, uint _amount, uint _weiExpected) internal {
        require(netAmountBought >= _amount);
        require(erc20Contract.allowance(_seller, address(this)) >= _amount);
        uint value = _amount.div(sellValue);  
        require(value >= _weiExpected);
        assert(address(this).balance >= value);  
        _amount = value.mul(sellValue);  
        
        netAmountBought = netAmountBought.sub(_amount);
        emit LogSold(_seller, sellValue, _amount);
        
        erc20Contract.safeTransferFrom(_seller, address(this), _amount);
        _seller.transfer(value);
    }
    
     
    function lacksFunds() external view returns(bool) {
        return address(this).balance < getRequiredBalance(sellValue);
    }
    
     
     
    function amountAvailableToCashout() external view onlyOwner returns (uint) {
        return address(this).balance.sub(getRequiredBalance(sellValue));
    }

     
    function cashout() external onlyOwner {
        uint requiredBalance = getRequiredBalance(sellValue);
        assert(address(this).balance >= requiredBalance);
        
        owner.transfer(address(this).balance.sub(requiredBalance));
    }
    
     
    function close() public onlyOwner whenPaused {
        erc20Contract.transfer(owner, erc20Contract.balanceOf(address(this)));
        selfdestruct(owner);
    }
    
     
     
    function extraBalanceNeeded(uint _proposedSellValue) external view onlyOwner returns (uint) {
        uint requiredBalance = getRequiredBalance(_proposedSellValue);
        return (requiredBalance > address(this).balance) ? requiredBalance.sub(address(this).balance) : 0;
    }
    
     
    function adjustPrices(uint _buyCost, uint _sellValue) external payable onlyOwner whenPaused {
        buyCost = _buyCost == 0 ? buyCost : _buyCost;
        sellValue = _sellValue == 0 ? sellValue : _sellValue;
        
        uint requiredBalance = getRequiredBalance(sellValue);
        require(msg.value.add(address(this).balance) >= requiredBalance);
        
        emit LogPriceChanged(buyCost, sellValue);
    }
    
    function getRequiredBalance(uint _proposedSellValue) internal view returns (uint) {
        return netAmountBought.div(_proposedSellValue).add(1);
    }
    
     
     
    function transferAnyERC20Token(address _address, uint _tokens) external onlyOwner {
        require(_address != address(erc20Contract));
        
        ERC20(_address).safeTransfer(owner, _tokens);
    }
}

contract BitWichLoom is BitWich {
    constructor() 
            BitWich(800, 1300, 0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0) public {
    }
}