 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 


contract Ownable {
  address public owner;

  function Ownable() public{
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract SafeMath {
  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) pure internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public returns (bool success) {
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
     
    
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
      
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract UbetCoins is Ownable, StandardToken {

    string public name = "Ubet Coins";
    string public symbol = "UBETS"; 
    uint public decimals = 18;      

    uint256 public totalSupply =  4000000000 * (10**decimals);
    uint256 public tokenSupplyFromCheck = 0;              
        
     
    uint256 public ratePerOneEther = 962;
    uint256 public totalUBetCheckAmounts = 0;

     
    uint64 public issueIndex = 0;

     
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);
    
     
    address public moneyWallet = 0xe5688167Cb7aBcE4355F63943aAaC8bb269dc953;

     
    event UBetCheckIssue(string chequeIndex);
      
    struct UBetCheck {
      string accountId;
      string accountNumber;
      string fullName;
      string routingNumber;
      string institution;
      uint256 amount;
      uint256 tokens;
      string checkFilePath;
      string digitalCheckFingerPrint;
    }
    
    mapping (address => UBetCheck) UBetChecks;
    address[] public UBetCheckAccts;
    
    
     
    function UbetCoins() public{
        balances[msg.sender] = totalSupply;
    }
  
     

     
     
    function transferOwnership(address _newOwner) public onlyOwner {
        balances[_newOwner] = balances[owner];
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    }
    
     
    
     
     
     
     
     
     
     
     
     
     
     
    function registerUBetCheck(address _beneficiary, string _accountId,  string _accountNumber, string _routingNumber, string _institution, string _fullname,  uint256 _amount, string _checkFilePath, string _digitalCheckFingerPrint, uint256 _tokens) public payable onlyOwner {
      
      require(_beneficiary != address(0));
      require(bytes(_accountId).length != 0);
      require(bytes(_accountNumber).length != 0);
      require(bytes(_routingNumber).length != 0);
      require(bytes(_institution).length != 0);
      require(bytes(_fullname).length != 0);
      require(_amount > 0);
      require(_tokens > 0);
      require(bytes(_checkFilePath).length != 0);
      require(bytes(_digitalCheckFingerPrint).length != 0);
      
      uint256 __conToken = _tokens * (10**(decimals));

      
      var UBetCheck = UBetChecks[_beneficiary];
      
      UBetCheck.accountId = _accountId;
      UBetCheck.accountNumber = _accountNumber;
      UBetCheck.routingNumber = _routingNumber;
      UBetCheck.institution = _institution;
      UBetCheck.fullName = _fullname;
      UBetCheck.amount = _amount;
      UBetCheck.tokens = _tokens;
      
      UBetCheck.checkFilePath = _checkFilePath;
      UBetCheck.digitalCheckFingerPrint = _digitalCheckFingerPrint;
      
      totalUBetCheckAmounts = safeAdd(totalUBetCheckAmounts, _amount);
      tokenSupplyFromCheck = safeAdd(tokenSupplyFromCheck, _tokens);
      
      UBetCheckAccts.push(_beneficiary) -1;
      
       
      doIssueTokens(_beneficiary, __conToken);
      
       
      UBetCheckIssue(_accountId);
    }
    
     
    function getUBetChecks() public view returns (address[]) {
      return UBetCheckAccts;
    }
    
     
    function getUBetCheck(address _address) public view returns(string, string, string, string, uint256, string, string) {
            
      return (UBetChecks[_address].accountNumber,
              UBetChecks[_address].routingNumber,
              UBetChecks[_address].institution,
              UBetChecks[_address].fullName,
              UBetChecks[_address].amount,
              UBetChecks[_address].checkFilePath,
              UBetChecks[_address].digitalCheckFingerPrint);
    }
    
     
     
    function () public payable {
      purchaseTokens(msg.sender);
    }

     
    function countUBetChecks() public view returns (uint) {
        return UBetCheckAccts.length;
    }
    

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
      require(_beneficiary != address(0));    

       
      uint256 increasedTotalSupply = safeAdd(totalSupply, _tokens);
      
       
      totalSupply = increasedTotalSupply;
       
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _tokens);
      
      emit Transfer(msg.sender, _beneficiary, _tokens);
    
       
      emit Issue(
                issueIndex++,
                _beneficiary,
                _tokens
                );
    }
    
     
     
    function purchaseTokens(address _beneficiary) public payable {
      
      uint _tokens = safeDiv(safeMul(msg.value, ratePerOneEther), (10**(18-decimals)));
      doIssueTokens(_beneficiary, _tokens);

       
      address(moneyWallet).transfer(address(this).balance);
    }
    
    
     
     
    function setMoneyWallet(address _address) public onlyOwner {
        moneyWallet = _address;
    }
    
     
     
    function setRatePerOneEther(uint256 _value) public onlyOwner {
      require(_value >= 1);
      ratePerOneEther = _value;
    }
    
}