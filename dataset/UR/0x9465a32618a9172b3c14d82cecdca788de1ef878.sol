 

pragma solidity ^0.4.21;

 

 
interface ReinvestProxy {

     
    function reinvestFor(address customer) external payable;

}

 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
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

 

 

contract P4RTYDaoVault is Whitelist {


     

     
    modifier onlyDivis {
        require(myDividends() > 0);
        _;
    }


     

    event onStake(
        address indexed customerAddress,
        uint256 stakedTokens,
        uint256 timestamp
    );

    event onDeposit(
        address indexed fundingSource,
        uint256 ethDeposited,
        uint    timestamp
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn,
        uint timestamp
    );

    event onReinvestmentProxy(
        address indexed customerAddress,
        address indexed destinationAddress,
        uint256 ethereumReinvested
    );




     


    uint256 constant internal magnitude = 2 ** 64;


     

     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;

     
    uint256 internal tokenSupply_ = 1;
    uint256 internal profitPerShare_;

    ERC20 public p4rty;


     

    constructor(address _p4rtyAddress) Ownable() public {

        p4rty = ERC20(_p4rtyAddress);

    }

     
    function() payable public {
        deposit();
    }

     
    function deposit() payable public  {

        uint256 _incomingEthereum = msg.value;
        address _fundingSource = msg.sender;

         
        profitPerShare_ += (_incomingEthereum * magnitude / tokenSupply_);


         
        emit onDeposit(_fundingSource, _incomingEthereum, now);

    }

    function stake(uint _amountOfTokens) public {


         
         

        address _customerAddress = msg.sender;

         
        require(p4rty.balanceOf(_customerAddress) > 0);



        uint256 _balance = p4rty.balanceOf(_customerAddress);
        uint256 _stakeAmount = Math.min256(_balance,_amountOfTokens);

        require(_stakeAmount > 0);
        p4rty.transferFrom(_customerAddress, address(this), _stakeAmount);

         
        tokenSupply_ = SafeMath.add(tokenSupply_, _stakeAmount);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _stakeAmount);

         
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _stakeAmount);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        emit onStake(_customerAddress, _amountOfTokens, now);
    }

     
    function withdraw() onlyDivis public {

        address _customerAddress = msg.sender;
         
        uint256 _dividends = dividendsOf(_customerAddress);

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);


         
        _customerAddress.transfer(_dividends);

         
        emit onWithdraw(_customerAddress, _dividends, now);
    }

    function reinvestByProxy(address _customerAddress) onlyWhitelisted public {
         
        uint256 _dividends = dividendsOf(_customerAddress);

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);


         
        ReinvestProxy reinvestProxy =  ReinvestProxy(msg.sender);
        reinvestProxy.reinvestFor.value(_dividends)(_customerAddress);

        emit onReinvestmentProxy(_customerAddress,msg.sender,_dividends);

    }


     

     
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

     
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
    function votingPower(address _customerAddress) public view returns (uint256) {
        return SafeMath.div(balanceOf(_customerAddress), totalSupply());
    }

     
    function myDividends() public view returns (uint256) {
        return dividendsOf(msg.sender);

    }

     
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

}