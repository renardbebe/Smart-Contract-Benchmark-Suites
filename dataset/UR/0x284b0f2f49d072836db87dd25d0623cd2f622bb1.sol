 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function unown() onlyOwner {
    owner = address(0);
  }

}

contract Transferable is Ownable {

  bool public transfersAllowed = false;
  mapping(address => bool) allowedTransfersTo;

  function Transferable() {
    allowedTransfersTo[msg.sender] = true;
  }

  modifier onlyIfTransfersAllowed() {
    require(transfersAllowed == true || allowedTransfersTo[msg.sender] == true);
    _;
  }

  function allowTransfers() onlyOwner {
    transfersAllowed = true;
  }

  function disallowTransfers() onlyOwner {
    transfersAllowed = false;
  }

  function allowTransfersTo(address _owner) onlyOwner {
    allowedTransfersTo[_owner] = true;
  }

  function disallowTransfersTo(address _owner) onlyOwner {
    allowedTransfersTo[_owner] = false;
  }

  function transfersAllowedTo(address _owner) constant returns (bool) {
    return (transfersAllowed == true || allowedTransfersTo[_owner] == true);
  }

}

 
contract BasicToken is ERC20Basic, Transferable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint256 size) {
     require(msg.data.length >= size + 4);
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) onlyIfTransfersAllowed {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) onlyIfTransfersAllowed {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract DesToken is StandardToken {

  string public name = "DES Token";
  string public symbol = "DES";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 35000000 * 1 ether;

   
  function DesToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}

 
contract Haltable is Ownable {
  bool public halted = false;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract DesTokenSale is Haltable {
    using SafeMath for uint;

    string public name = "3DES Token Sale Contract";

    DesToken public token;
    address public beneficiary;

    uint public tokensSoldTotal = 0;  
    uint public weiRaisedTotal = 0;  
    uint public investorCount = 0;
    uint public tokensSelling = 0;  
    uint public tokenPrice = 0;  
    uint public purchaseLimit = 0;  

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    function DesTokenSale(
      address _token,
      address _beneficiary
      ) {
        token = DesToken(_token);
        beneficiary = _beneficiary;
    }

    function changeBeneficiary(address _beneficiary) onlyOwner stopInEmergency {
        beneficiary = _beneficiary;
    }

    function startPhase(
      uint256 _tokens,
      uint256 _price,
      uint256 _limit
      ) onlyOwner {
        require(tokensSelling == 0);
        require(_tokens <= token.balanceOf(this));
        tokensSelling = _tokens * 1 ether;
        tokenPrice = _price;
        purchaseLimit = _limit * 1 ether;
    }

     
     
    function finishPhase() onlyOwner {
        require(tokensSelling != 0);
        token.transfer(beneficiary, tokensSelling);
        tokensSelling = 0;
    }

    function () payable {
        doPurchase(msg.sender);
    }

    function doPurchaseFor(address _sender) payable {
        doPurchase(_sender);
    }

    function doPurchase(address _sender) private stopInEmergency {
         
        require(tokensSelling != 0);

         
        require(msg.value >= 0.01 * 1 ether);
        
         
        uint tokens = msg.value * 1 ether / tokenPrice;
        
         
        require(token.balanceOf(_sender).add(tokens) <= purchaseLimit);
        
         
         
        tokensSelling = tokensSelling.sub(tokens);
        
         
        tokensSoldTotal = tokensSoldTotal.add(tokens);
        if (token.balanceOf(_sender) == 0) investorCount++;
        weiRaisedTotal = weiRaisedTotal.add(msg.value);
        
         
        token.transfer(_sender, tokens);

         
        beneficiary.transfer(msg.value);

        NewContribution(_sender, tokens, msg.value);
    }
    
}