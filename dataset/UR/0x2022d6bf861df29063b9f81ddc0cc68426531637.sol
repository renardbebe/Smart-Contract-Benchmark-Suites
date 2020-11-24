 

pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

 

 
contract ArbitrageETHStaking is Ownable {

    using SafeMath for uint256;

     

    event onPurchase(
       address indexed customerAddress,
       uint256 etherIn,
       uint256 contractBal,
       uint256 poolFee,
       uint timestamp
    );

    event onWithdraw(
         address indexed customerAddress,
         uint256 etherOut,
         uint256 contractBal,
         uint timestamp
    );


     

    mapping(address => uint256) internal personalFactorLedger_;  
    mapping(address => uint256) internal balanceLedger_;  

     
    uint256 minBuyIn = 0.001 ether;  
    uint256 stakingPrecent = 2;
    uint256 internal globalFactor = 10e21;  
    uint256 constant internal constantFactor = 10e21 * 10e21;  

     
    function() external payable {
        buy();
    }

     
    function buy()
        public
        payable
    {
        address _customerAddress = msg.sender;

        require(msg.value >= minBuyIn, "should be more the 0.0001 ether sent");

        uint256 _etherBeforeBuyIn = getBalance().sub(msg.value);

        uint256 poolFee;
         
        if (_etherBeforeBuyIn != 0) {

             
            poolFee = msg.value.mul(stakingPrecent).div(100);

             
            uint256 globalIncrease = globalFactor.mul(poolFee) / _etherBeforeBuyIn;
            globalFactor = globalFactor.add(globalIncrease);
        }


        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).add(msg.value).sub(poolFee);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onPurchase(_customerAddress, msg.value, getBalance(), poolFee, now);
    }

     
    function withdraw(uint256 _sellEth)
        public
    {
        address _customerAddress = msg.sender;
         
        require(_sellEth > 0, "user cant spam transactions with 0 value");
        require(_sellEth <= ethBalanceOf(_customerAddress), "user cant withdraw more then he holds ");


         
        _customerAddress.transfer(_sellEth);
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).sub(_sellEth);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onWithdraw(_customerAddress, _sellEth, getBalance(), now);
    }

     
    function withdrawAll()
        public
    {
        address _customerAddress = msg.sender;
         
        uint256 _sellEth = ethBalanceOf(_customerAddress);
        require(_sellEth > 0, "user cant call withdraw, when holds nothing");
         
        _customerAddress.transfer(_sellEth);
        balanceLedger_[_customerAddress] = 0;
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onWithdraw(_customerAddress, _sellEth, getBalance(), now);
    }

     

     
    function getBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

     
    function ethBalanceOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
         
        return balanceLedger_[_customerAddress].mul(personalFactorLedger_[_customerAddress]).mul(globalFactor) / constantFactor;
    }
}