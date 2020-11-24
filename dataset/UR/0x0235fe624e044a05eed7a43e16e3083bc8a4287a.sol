 

pragma solidity ^0.4.17;

contract Cofounded {
  mapping (address => uint) public cofounderIndices;
  address[] public cofounders;


   
  modifier restricted () {
    uint cofounderIndex = cofounderIndices[msg.sender];
    require(msg.sender == cofounders[cofounderIndex]);
    _;
  }

   
   
   
  function Cofounded (address[] contractCofounders) public {
    cofounders.push(msg.sender);
    
    for (uint8 x = 0; x < contractCofounders.length; x++) {
      address cofounder = contractCofounders[x];

      bool isValidUniqueCofounder =
        cofounder != address(0) &&
        cofounder != msg.sender &&
        cofounderIndices[cofounder] == 0;

            
       
       
       
       
       
       
       
      if (isValidUniqueCofounder) {
        uint256 cofounderIndex = cofounders.push(cofounder) - 1;
        cofounderIndices[cofounder] = cofounderIndex;
      }
    }
  }

   
  function getCofounderCount () public constant returns (uint256) {
    return cofounders.length;
  }

   
  function getCofounders () public constant returns (address[]) {
    return cofounders;
  }
}

interface ERC20 {

   
  function transfer (address to, uint256 value) public returns (bool success);
  function transferFrom (address from, address to, uint256 value) public returns (bool success);
  function approve (address spender, uint256 value) public returns (bool success);
  function allowance (address owner, address spender) public constant returns (uint256 remaining);
  function balanceOf (address owner) public constant returns (uint256 balance);
   
  event Transfer (address indexed from, address indexed to, uint256 value);
  event Approval (address indexed owner, address indexed spender, uint256 value);
}


 
 
interface ERC165 {
   
  function supportsInterface(bytes4 interfaceID) external constant returns (bool);
}
contract InterfaceSignatureConstants {
  bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC20 =
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('allowance(address,address)'));

  bytes4 constant InterfaceSignature_ERC20_PlusOptions = 
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('decimals()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('allowance(address,address)'));
}

 
 
 
 
contract OriginalToken is Cofounded, ERC20, ERC165, InterfaceSignatureConstants {
    bool private hasExecutedCofounderDistribution;
    struct Allowance {
      uint256 amount;
      bool    hasBeenPartiallyWithdrawn;
    }

     
     
    string public constant name = 'Original Crypto Coin';
     
    string public constant symbol = 'OCC';
     
    uint8 public constant decimals = 18;
     

     
     
     
    uint256 public totalSupply = 100000000000000000000000000000;

    mapping (address => uint256) public balances;
     
     
     
    mapping (address => mapping (address => Allowance)) public allowances;

   
   
   
  function OriginalToken (address[] tokenCofounders,
                          uint256 cofounderDistribution) Cofounded(tokenCofounders) public { 

    if (hasExecutedCofounderDistribution ||
        cofounderDistribution == 0 || 
        totalSupply < cofounderDistribution) revert();

    hasExecutedCofounderDistribution = true;
    uint256 initialSupply = totalSupply;

     
     

    for (uint8 x = 0; x < cofounders.length; x++) {
      address cofounder = cofounders[x];

      initialSupply -= cofounderDistribution;
       
       
      if (initialSupply < cofounderDistribution) revert();
      balances[cofounder] = cofounderDistribution;
    }

    balances[msg.sender] += initialSupply;
  }

  function transfer (address to, uint256 value) public returns (bool) {
    return transferBalance (msg.sender, to, value);
  }

  function transferFrom (address from, address to, uint256 value) public returns (bool success) {
    Allowance storage allowance = allowances[from][msg.sender];
    if (allowance.amount < value) revert();

    allowance.hasBeenPartiallyWithdrawn = true;
    allowance.amount -= value;

    if (allowance.amount == 0) {
      delete allowances[from][msg.sender];
    }

    return transferBalance(from, to, value);
  }

  event ApprovalDenied (address indexed owner, address indexed spender);

   
  function approve (address spender, uint256 value) public returns (bool success) {
    Allowance storage allowance = allowances[msg.sender][spender];

    if (value == 0) {
      delete allowances[msg.sender][spender];
      Approval(msg.sender, spender, value);
      return true;
    }

    if (allowance.hasBeenPartiallyWithdrawn) {
      delete allowances[msg.sender][spender];
      ApprovalDenied(msg.sender, spender);
      return false;
    } else {
      allowance.amount = value;
      Approval(msg.sender, spender, value);
    }

    return true;
  }

   
  function transferBalance (address from, address to, uint256 value) private returns (bool) {
     
    if (to == address(0) || from == to) revert();
     
    if (value == 0) {
      Transfer(msg.sender, to, value);
      return true;
    }

    uint256 senderBalance = balances[from];
    uint256 receiverBalance = balances[to];
    if (senderBalance < value) revert();
    senderBalance -= value;
    receiverBalance += value;
     
    if (receiverBalance < value) revert();

    balances[from] = senderBalance;
    balances[to] = receiverBalance;

    Transfer(from, to, value);
    return true;
  }

 
   
  function allowance (address owner, address spender) public constant returns (uint256 remaining) {
    return allowances[owner][spender].amount;
  }

  function balanceOf (address owner) public constant returns (uint256 balance) {
    return balances[owner];
  }

  function supportsInterface (bytes4 interfaceID) external constant returns (bool) {
    return ((interfaceID == InterfaceSignature_ERC165) ||
            (interfaceID == InterfaceSignature_ERC20)  ||
            (interfaceID == InterfaceSignature_ERC20_PlusOptions));
  }
}