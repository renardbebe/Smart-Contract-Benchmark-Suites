 

pragma solidity ^0.4.12;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
     
    
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
      
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract UBetCoin is Ownable, StandardToken {

    string public name = "UBetCoin";                
    string public symbol = "UBET";                  
    uint public decimals = 2;                       

    uint256 public totalSupply =  400000000000;       
    uint256 public tokenSupplyFromCheck = 0;              
    uint256 public tokenSupplyBackedByGold = 4000000000;  
    
    string public constant YOU_BET_MINE_DOCUMENT_PATH = "https://s3.amazonaws.com/s3-ubetcoin-user-signatures/document/GOLD-MINES-assigned+TO-SAINT-NICOLAS-SNADCO-03-22-2016.pdf";
    string public constant YOU_BET_MINE_DOCUMENT_SHA512 = "7e9dc6362c5bf85ff19d75df9140b033c4121ba8aaef7e5837b276d657becf0a0d68fcf26b95e76023a33251ac94f35492f2f0af882af4b87b1b1b626b325cf8";
    string public constant UBETCOIN_LEDGER_TO_LEDGER_ENTRY_DOCUMENT_PATH = "https://s3.amazonaws.com/s3-ubetcoin-user-signatures/document/LEDGER-TO-LEDGER+ENTRY-FOR-UBETCOIN+03-20-2018.pdf";
    string public constant UBETCOIN_LEDGER_TO_LEDGER_ENTRY_DOCUMENT_SHA512 = "c8f0ae2602005dd88ef908624cf59f3956107d0890d67d3baf9c885b64544a8140e282366cae6a3af7bfbc96d17f856b55fc4960e2287d4a03d67e646e0e88c6";
    
     
    uint256 public ratePerOneEther = 962;
    uint256 public totalUBetCheckAmounts = 0;

     
    uint64 public issueIndex = 0;

     
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);
    
     
    address public moneyWallet = 0xe5688167Cb7aBcE4355F63943aAaC8bb269dc953;

     
    event UbetCheckIssue(string chequeIndex);
      
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
    address[] public uBetCheckAccts;
    
    
     
    function UBetCoin() {
        balances[msg.sender] = totalSupply;
    }
  
     

     
     
    function transferOwnership(address _newOwner) onlyOwner {
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
      
      var __conToken = _tokens * (10**(decimals));
      
      var uBetCheck = UBetChecks[_beneficiary];
      
      uBetCheck.accountId = _accountId;
      uBetCheck.accountNumber = _accountNumber;
      uBetCheck.routingNumber = _routingNumber;
      uBetCheck.institution = _institution;
      uBetCheck.fullName = _fullname;
      uBetCheck.amount = _amount;
      uBetCheck.tokens = _tokens;
      
      uBetCheck.checkFilePath = _checkFilePath;
      uBetCheck.digitalCheckFingerPrint = _digitalCheckFingerPrint;
      
      totalUBetCheckAmounts = safeAdd(totalUBetCheckAmounts, _amount);
      tokenSupplyFromCheck = safeAdd(tokenSupplyFromCheck, _tokens);
      
      uBetCheckAccts.push(_beneficiary) -1;
      
       
      doIssueTokens(_beneficiary, __conToken);
      
       
      UbetCheckIssue(_accountId);
    }
    
     
    function getUBetChecks() public returns (address[]) {
      return uBetCheckAccts;
    }
    
     
    function getUBetCheck(address _address) public returns(string, string, string, string, uint256, string, string) {
            
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

     
    function countUBetChecks() public returns (uint) {
        return uBetCheckAccts.length;
    }
    

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
      require(_beneficiary != address(0));    

       
      uint256 increasedTotalSupply = safeAdd(totalSupply, _tokens);
      
       
      totalSupply = increasedTotalSupply;
       
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _tokens);
      
      Transfer(msg.sender, _beneficiary, _tokens);
    
       
      Issue(
          issueIndex++,
          _beneficiary,
          _tokens
      );
    }
    
     
     
    function purchaseTokens(address _beneficiary) public payable {
       
      require(msg.value >= 0.00104 ether);
     
      uint _tokens = safeDiv(safeMul(msg.value, ratePerOneEther), (10**(18-decimals)));
      doIssueTokens(_beneficiary, _tokens);

       
      moneyWallet.transfer(this.balance);
    }
    
    
     
     
    function setMoneyWallet(address _address) public onlyOwner {
        moneyWallet = _address;
    }
    
     
     
    function setRatePerOneEther(uint256 _value) public onlyOwner {
      require(_value >= 1);
      ratePerOneEther = _value;
    }
    
}