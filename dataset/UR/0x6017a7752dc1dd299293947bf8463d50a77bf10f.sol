 

pragma solidity ^0.4.24;

contract ERC20Basic {}
contract ERC20 is ERC20Basic {}
contract Ownable {}
contract BasicToken is ERC20Basic {}
contract StandardToken is ERC20, BasicToken {}
contract Pausable is Ownable {}
contract PausableToken is StandardToken, Pausable {}
contract MintableToken is StandardToken, Ownable {}

contract OpiriaToken is MintableToken, PausableToken {
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address who) public view returns (uint256);
}

contract VestingContractCT {
   
  address public owner;
  OpiriaToken public company_token;

  address public PartnerAccount;
  uint public originalBalance;
  uint public currentBalance;
  uint public alreadyTransfered;
  uint public startDateOfPayments;
  uint public endDateOfPayments;
  uint public periodOfOnePayments;
  uint public limitPerPeriod;
  uint public daysOfPayments;

   
  modifier onlyOwner
  {
    require(owner == msg.sender);
    _;
  }
  
  
   
  event Transfer(address indexed to, uint indexed value);
  event OwnerChanged(address indexed owner);


   
  constructor (OpiriaToken _company_token) public {
    owner = msg.sender;
    PartnerAccount = 0x89a380E3d71a71C51441EBd7bf512543a4F6caE7;
    company_token = _company_token;
    originalBalance = 2500000 * 10**18;  
    currentBalance = originalBalance;
    alreadyTransfered = 0;
    startDateOfPayments = 1554069600;  
    endDateOfPayments = 1569880800;  
    periodOfOnePayments = 24 * 60 * 60;  
    daysOfPayments = (endDateOfPayments - startDateOfPayments) / periodOfOnePayments;  
    limitPerPeriod = originalBalance / daysOfPayments;
  }


   
  function()
    public
    payable
  {
    revert();
  }


   
  function getBalance()
    constant
    public
    returns(uint)
  {
    return company_token.balanceOf(this);
  }


  function setOwner(address _owner) 
    public 
    onlyOwner 
  {
    require(_owner != 0);
    
    owner = _owner;
    emit OwnerChanged(owner);
  }
  
  function sendCurrentPayment() public {
    uint currentPeriod = (now - startDateOfPayments) / periodOfOnePayments;
    uint currentLimit = currentPeriod * limitPerPeriod;
    uint unsealedAmount = currentLimit - alreadyTransfered;
    if (unsealedAmount > 0) {
      if (currentBalance >= unsealedAmount) {
        company_token.transfer(PartnerAccount, unsealedAmount);
        alreadyTransfered += unsealedAmount;
        currentBalance -= unsealedAmount;
        emit Transfer(PartnerAccount, unsealedAmount);
      } else {
        company_token.transfer(PartnerAccount, currentBalance);
        alreadyTransfered += currentBalance;
        currentBalance -= currentBalance;
        emit Transfer(PartnerAccount, currentBalance);
      }
    }
  }
}