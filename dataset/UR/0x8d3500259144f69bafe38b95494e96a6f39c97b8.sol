 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity >=0.5.10 <0.6.0;



contract DivideContract {
  using SafeMath for uint256;

  address owner;
  mapping(address => bool) operators;
  uint256 public NUM_RECIPIENTS = 2;
  uint256 public PRECISION = 10000;
  RecipientList recipientList;
  address public nftAddress;

  struct RecipientList {
    address payable[] available_recipients;
    uint256[] ratios;
  }

  event OperatorChanged(
    address indexed operator,
    bool action
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 totalAmount
  );

  event RecipientsInfoChanged(
    bool action,
    address payable[] recipients,
    uint256[] ratios
  );

  modifier isOwner() {
    require(msg.sender == owner, 'No permissions');
    _;
  }

  modifier isOperator() {
    require(operators[msg.sender] || msg.sender == owner, 'No permissions');
    _;
  }

  constructor(address _nftAddress) public {
    require(_nftAddress != address(0));  
    owner = msg.sender;
    nftAddress = _nftAddress;
  }

   
  function arraySum(uint256[] memory data) private pure returns (uint256) {
    uint256 res;
    for (uint256 i; i < data.length; i++) {
      res = res.add(data[i]);
    }
    return res;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

   
  function operatorExists (address entity) public view returns (bool) {
    return operators[entity];
  }

  function assignOperator (address entity) public isOwner() {
    require(entity != address(0), 'Target is invalid addresses');
    require(!operatorExists(entity), 'Target is already an operator');
    emit OperatorChanged(entity, true);
    operators[entity] = true;
  }

  function removeOperator (address entity) public isOwner() {
    require(entity != address(0), 'Target is invalid addresses');
    require(operatorExists(entity), 'Target is not an operator');
    emit OperatorChanged(entity, false);
    operators[entity] = false;
  }

   
   
  function registerRecipientsInfo (address payable[] memory recipients, uint256[] memory ratio) public isOperator() returns (bool) {
    require(arraySum(ratio) == PRECISION, 'Total sum of ratio must be 100%');
    require(recipients.length == ratio.length, 'Incorrect data size');
    require(recipients.length == NUM_RECIPIENTS, 'Incorrect number of recipients');

    recipientList = RecipientList(recipients, ratio);
    emit RecipientsInfoChanged(true, recipients, ratio);
    return true;
  }

   
   
  function getRecipientsInfo() public view isOperator() returns (address, address payable[] memory, uint256[] memory) {
    return (nftAddress, recipientList.available_recipients, recipientList.ratios);
  }

  function deleteRecipientsInfo () public isOperator() {
    require(recipientList.available_recipients.length > 0, 'No recipients registered');
    emit RecipientsInfoChanged(false, recipientList.available_recipients, recipientList.ratios);
    delete recipientList;
  }

  function calculateAmount(uint256 fee_received, uint256 ratio) private view returns (uint256) {
    return (fee_received.mul(ratio).div(PRECISION));
  }


   
   
  function () external payable {
    require(recipientList.available_recipients.length == NUM_RECIPIENTS, 'No recipients registered');

    uint256 amount1 = calculateAmount(msg.value, recipientList.ratios[0]);
    address payable toWallet1 = recipientList.available_recipients[0];
    toWallet1.transfer(amount1);
    emit Transfer(msg.sender, toWallet1, amount1, msg.value);

     
    uint256 amount2 = address(this).balance;
    address payable toWallet2 = recipientList.available_recipients[1];
    toWallet2.transfer(amount2);
    emit Transfer(msg.sender, toWallet2, amount2, msg.value);
  }
}