 

 


pragma solidity ^0.4.15;


contract IERC20 {
    function totalSupply() public constant returns (uint _totalSupply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
contract Ownable {

  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

  
contract BitindiaVestingContract is Ownable{

  IERC20 token;

  mapping (address => uint256) ownersMap;

  mapping (address => uint256) ownersMapFirstPeriod;    
  mapping (address => uint256) ownersMapSecondPeriod;    
  mapping (address => uint256) ownersMapThirdPeriod;   

    
  bool public initialized = false;

   
  uint256 public totalCommitted;

    
  mapping (address => address)  originalAddressTraker;
  mapping (address => uint) changeAddressAttempts;

   
  uint256 public constant firstDueDate = 1544486400;     
  uint256 public constant secondDueDate = 1560211200;    
  uint256 public constant thirdDueDate = 1576022400;     

   
  address public constant tokenAddress = 0x420335D3DEeF2D5b87524Ff9D0fB441F71EA621f;
  
   
  event ChangeClaimAddress(address oldAddress, address newAddress);

   
  event AmountClaimed(address user, uint256 amount);

    
  event AddUser(address userAddress, uint256 amount);
 
   
  function BitindiaVestingContract() public {
      token = IERC20(tokenAddress);
      initialized = false;
      totalCommitted = 0;
  }

    
  function initialize() public onlyOwner
  {
      require(totalCommitted>0);
      require(totalCommitted <= token.balanceOf(this));
      if(!initialized){
            initialized = true;
      }
  }

   
  modifier whenContractIsActive() {
     
    require(initialized);
    _;
  }

   
  modifier preInitState() {
     
    require(!initialized);
    _;
  }

    
  modifier whenClaimable() {
     
    assert(now>firstDueDate);
    _;
  }
  
    
  modifier checkValidUser(){
    assert(ownersMap[msg.sender]>0);
    _;
  }

   
  function addVestingUser(address user, uint256 amount) public onlyOwner preInitState {
      uint256 oldAmount = ownersMap[user];
      ownersMap[user] = amount;
      ownersMapFirstPeriod[user] = amount/3;         
      ownersMapSecondPeriod[user] = amount/3;
      ownersMapThirdPeriod[user] = amount - ownersMapFirstPeriod[user] - ownersMapSecondPeriod[user];
      originalAddressTraker[user] = user;
      changeAddressAttempts[user] = 0;
      totalCommitted += (amount - oldAmount);
      AddUser(user, amount);
  }
  
   
  function changeClaimAddress(address newAddress) public checkValidUser{

       
      address origAddress = originalAddressTraker[msg.sender];
      uint newCount = changeAddressAttempts[origAddress]+1;
      assert(newCount<5);
      changeAddressAttempts[origAddress] = newCount;
      
       
      uint256 balance = ownersMap[msg.sender];
      ownersMap[msg.sender] = 0;
      ownersMap[newAddress] = balance;


       
      balance = ownersMapFirstPeriod[msg.sender];
      ownersMapFirstPeriod[msg.sender] = 0;
      ownersMapFirstPeriod[newAddress] = balance;

       
      balance = ownersMapSecondPeriod[msg.sender];
      ownersMapSecondPeriod[msg.sender] = 0;
      ownersMapSecondPeriod[newAddress] = balance;


       
      balance = ownersMapThirdPeriod[msg.sender];
      ownersMapThirdPeriod[msg.sender] = 0;
      ownersMapThirdPeriod[newAddress] = balance;


       
      originalAddressTraker[newAddress] = origAddress;
      ChangeClaimAddress(msg.sender, newAddress);
  }


   
  function updateChangeAttemptCount(address user) public onlyOwner{
    address origAddress = originalAddressTraker[user];
    changeAddressAttempts[origAddress] = 0;
  }

   
  function getBalance() public constant returns (uint256) {
      return token.balanceOf(this);
  }

   
  function claimAmount() internal whenContractIsActive whenClaimable checkValidUser{
      uint256 amount = 0;
      uint256 periodAmount = 0;
      if(now>firstDueDate){
        periodAmount = ownersMapFirstPeriod[msg.sender];
        if(periodAmount > 0){
          ownersMapFirstPeriod[msg.sender] = 0;
          amount += periodAmount;
        }
      }

      if(now>secondDueDate){
        periodAmount = ownersMapSecondPeriod[msg.sender];
        if(periodAmount > 0){
          ownersMapSecondPeriod[msg.sender] = 0;
          amount += periodAmount;
        }
      }

      if(now>thirdDueDate){
        periodAmount = ownersMapThirdPeriod[msg.sender];
        if(periodAmount > 0){
          ownersMapThirdPeriod[msg.sender] = 0;
          amount += periodAmount;
        }
      }
      require(amount>0);
      ownersMap[msg.sender]= ownersMap[msg.sender]-amount;
      token.transfer(msg.sender, amount);
      totalCommitted -= amount;

  }


    
  function () external payable {
      claimAmount();
  }


   
   function getClaimable() public constant returns (uint256){
       return totalCommitted;
   }
   
     
   function getMyBalance() public checkValidUser constant returns (uint256){
       
       return ownersMap[msg.sender];
       
   }
   


}