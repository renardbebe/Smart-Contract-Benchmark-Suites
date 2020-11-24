 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
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

}

 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
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

contract BuyLimits {
    event LogLimitsChanged(uint _minBuy, uint _maxBuy);

     
    uint public minBuy;  
    uint public maxBuy;  

     
    modifier isWithinLimits(uint _amount) {
        require(withinLimits(_amount));
        _;
    }

     
    function BuyLimits(uint _min, uint  _max) public {
        _setLimits(_min, _max);
    }

     
    function withinLimits(uint _value) public view returns(bool) {
        if (maxBuy != 0) {
            return (_value >= minBuy && _value <= maxBuy);
        }
        return (_value >= minBuy);
    }

     
    function _setLimits(uint _min, uint _max) internal {
        if (_max != 0) {
            require (_min <= _max);  
        }
        minBuy = _min;
        maxBuy = _max;
        emit LogLimitsChanged(_min, _max);
    }
}


 
contract DAOstackPreSale is Pausable,BuyLimits,Whitelist {
    event LogFundsReceived(address indexed _sender, uint _amount);

    address public wallet;

     
    function DAOstackPreSale(address _wallet, uint _minBuy, uint _maxBuy)
    public
    BuyLimits(_minBuy, _maxBuy)
    {
         
        require(_wallet != address(0));
        wallet = _wallet;
    }

     
    function () payable whenNotPaused onlyWhitelisted isWithinLimits(msg.value) external {
        wallet.transfer(msg.value);
        emit LogFundsReceived(msg.sender, msg.value);
    }

     
    function drain() external {
        wallet.transfer((address(this)).balance);
    }

}