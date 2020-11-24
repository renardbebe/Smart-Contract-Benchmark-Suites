 

pragma solidity ^0.4.22;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
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



contract HoldersList is Ownable{
   uint256 public _totalTokens;
   
   struct TokenHolder {
        uint256 balance;
        uint       regTime;
        bool isValue;
    }
    
    mapping(address => TokenHolder) holders;
    address[] public payees;
    
    function changeBalance(address _who, uint _amount)  public onlyOwner {
        
            holders[_who].balance = _amount;
            if (notInArray(_who)){
                payees.push(_who);
                holders[_who].regTime = now;
                holders[_who].isValue = true;
            }
            
         
    }
    function notInArray(address _who) internal view returns (bool) {
        if (holders[_who].isValue) {
            return false;
        }
        return true;
    }
    
   
  
    function setTotal(uint _amount) public onlyOwner {
      _totalTokens = _amount;
  }
  
   
  
   function getTotal() public constant returns (uint)  {
     return  _totalTokens;
  }
  
   
  function returnBalance (address _who) public constant returns (uint){
      uint _balance;
      
      _balance= holders[_who].balance;
      return _balance;
  }
  
  
   
  function returnPayees () public constant returns (uint){
      uint _ammount;
      
      _ammount= payees.length;
      return _ammount;
  }
  
  
   
  function returnHolder (uint _num) public constant returns (address){
      address _addr;
      
      _addr= payees[_num];
      return _addr;
  }
  
   
  function returnRegDate (address _who) public constant returns (uint){
      uint _redData;
      
      _redData= holders[_who].regTime;
      return _redData;
  }
    
}



contract Dividend is Ownable   {
  using SafeMath for uint256;  
   
  uint _totalDivid=0;
  uint _newDivid=0;
  uint public _totalTokens;
  uint pointMultiplier = 10e18;
  HoldersList list;
  bool public PaymentFinished = false;
  
 
  
 
 address[] payees;
 
 struct ETHHolder {
        uint256 balance;
        uint       balanceUpdateTime;
        uint       rewardWithdrawTime;
 }
 mapping(address => ETHHolder) eholders;
 
   function returnMyEthBalance (address _who) public constant returns (uint){
       
      uint _eBalance;
      
      _eBalance= eholders[_who].balance;
      return _eBalance;
  }
  
  
  function returnTotalDividend () public constant returns (uint){
      return _totalDivid;
  }
  
  
  function changeEthBalance(address _who, uint256 _amount) internal {
     
     
    eholders[_who].balanceUpdateTime = now;
    eholders[_who].balance += _amount;

  }
  
    
  function setHoldersList(address _holdersList) public onlyOwner {
    list = HoldersList(_holdersList);
  }
  
  
  function Withdraw() public returns (bool){
    uint _eBalance;
    address _who;
    _who = msg.sender;
    _eBalance= eholders[_who].balance;
    require(_eBalance>0);
    eholders[_who].balance = 0;
    eholders[_who].rewardWithdrawTime = now;
    _who.transfer(_eBalance);
    return true;
    
   
  }
  
   
  function finishDividend() onlyOwner public returns (bool) {
    PaymentFinished = true;
    return true;
  }
  
  function() external payable {
     
     require(PaymentFinished==false);
     
     _newDivid= msg.value;
     _totalDivid += _newDivid;
     
     uint _myTokenBalance=0;
     uint _myRegTime;
     uint _myEthShare=0;
      
     uint256 _length;
     address _addr;
     
     _length=list.returnPayees();
     _totalTokens=list.getTotal();
     
     for (uint256 i = 0; i < _length; i++) {
        _addr =list.returnHolder(i);
        _myTokenBalance=list.returnBalance(_addr);
        _myRegTime=list.returnRegDate(_addr);
        _myEthShare=_myTokenBalance.mul(_newDivid).div(_totalTokens);
          changeEthBalance(_addr, _myEthShare);
        }
    
  }
 
}