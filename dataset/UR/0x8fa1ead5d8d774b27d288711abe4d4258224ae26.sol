 

pragma solidity ^0.4.11;

 

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) constant returns (uint balance);
  function allowance(address _owner, address _spender) constant returns (uint remaining);

  function transfer(address _to, uint _value) returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) returns (bool ok);
  function approve(address _spender, uint _value) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract SafeMath {
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    uint c = a - b;
    assert(c <= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  address public newOwner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner {
    if (_newOwner != address(0)) {
      newOwner = _newOwner;
    }
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  event OwnershipTransferred(address indexed _from, address indexed _to);
}

 
contract StandardToken is ERC20, Ownable, SafeMath {

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = safeSub(balances[msg.sender],_amount);
            balances[_to] = safeAdd(balances[_to],_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] = safeSub(balances[_from],_amount);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);
            balances[_to] = safeAdd(balances[_to],_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) returns (bool success) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
           return false;
        }
        if (balances[msg.sender] < _value) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint remaining) {
       return allowed[_owner][_spender];
     }
}

 
contract LookRevToken is StandardToken {

     
    string public constant name = "LookRev";
    string public constant symbol = "LOK";
    uint8 public constant decimals = 18;
    string public VERSION = 'LOK1.0';
    bool public finalised = false;
    
    address public wallet;

    mapping(address => bool) public kycRequired;

     
     
    uint public constant START_DATE = 1502902800;
    uint public constant END_DATE = 1505581200;

    uint public constant DECIMALSFACTOR = 10**uint(decimals);
    uint public constant TOKENS_SOFT_CAP =   10000000 * DECIMALSFACTOR;
    uint public constant TOKENS_HARD_CAP = 2000000000 * DECIMALSFACTOR;
    uint public constant TOKENS_TOTAL =    4000000000 * DECIMALSFACTOR;
    uint public initialSupply = 10000000 * DECIMALSFACTOR;

     
     
     
     
    uint public tokensPerKEther = 3000000;
    uint public CONTRIBUTIONS_MIN = 0 ether;
    uint public CONTRIBUTIONS_MAX = 0 ether;
    uint public constant KYC_THRESHOLD = 10000 * DECIMALSFACTOR;

    function LookRevToken() {
      owner = msg.sender;
      wallet = owner;
      totalSupply = initialSupply;
      balances[owner] = totalSupply;
    }

    
   function setWallet(address _wallet) onlyOwner {
        wallet = _wallet;
        WalletUpdated(wallet);
    }
    event WalletUpdated(address newWallet);

     
     
    function setTokensPerKEther(uint _tokensPerKEther) onlyOwner {
        require(now < START_DATE);
        require(_tokensPerKEther > 0);
        tokensPerKEther = _tokensPerKEther;
        TokensPerKEtherUpdated(tokensPerKEther);
    }
    event TokensPerKEtherUpdated(uint tokensPerKEther);

     
    function () payable {
        proxyPayment(msg.sender);
    }

     
     
    function proxyPayment(address participant) payable {

        require(!finalised);

        require(now <= END_DATE);

        require(msg.value > CONTRIBUTIONS_MIN);
        require(CONTRIBUTIONS_MAX == 0 || msg.value < CONTRIBUTIONS_MAX);

          
          
          
         uint tokens = msg.value * tokensPerKEther / 10**uint(18 - decimals + 3);

          
         require(totalSupply + tokens <= TOKENS_HARD_CAP);

          
         balances[participant] = safeAdd(balances[participant],tokens);
         totalSupply = safeAdd(totalSupply,tokens);

          
         Transfer(0x0, participant, tokens);
          
          
          
          
          
          
         TokensBought(participant, msg.value, balances[participant], tokens,
              totalSupply, tokensPerKEther);

         if (msg.value > KYC_THRESHOLD) {
              
             kycRequired[participant] = true;
         }

          
          
         wallet.transfer(msg.value);
    }

    event TokensBought(address indexed buyer, uint ethers, 
        uint participantTokenBalance, uint tokens, uint newTotalSupply, 
        uint tokensPerKEther);

    function finalise() onlyOwner {
         
        require(totalSupply >= TOKENS_SOFT_CAP || now > END_DATE);

        require(!finalised);

        finalised = true;
    }

   function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now < START_DATE);
        require(balance > 0);
        balances[participant] = safeAdd(balances[participant],balance);
        totalSupply = safeAdd(totalSupply,balance);
        Transfer(0x0, participant, balance);
        PrecommitmentAdded(participant, balance);
    }
    event PrecommitmentAdded(address indexed participant, uint balance);

    function transfer(address _to, uint _amount) returns (bool success) {
         
         
        require(finalised || msg.sender == owner);
        require(!kycRequired[msg.sender]);
        return super.transfer(_to, _amount);
    }

   function transferFrom(address _from, address _to, uint _amount) returns (bool success)
    {
         
        require(finalised);
        require(!kycRequired[_from]);
        return super.transferFrom(_from, _to, _amount);
    }

    function kycVerify(address participant, bool _required) onlyOwner {
        kycRequired[participant] = _required;
        KycVerified(participant, kycRequired[participant]);
    }
    event KycVerified(address indexed participant, bool required);

     
     
    function burnFrom(address _from, uint _amount) returns (bool success) {
        require(totalSupply >= _amount);

        if (balances[_from] >= _amount
            && allowed[_from][0x0] >= _amount
            && _amount > 0
            && balances[0x0] + _amount > balances[0x0]
        ) {
            balances[_from] = safeSub(balances[_from],_amount);
            balances[0x0] = safeAdd(balances[0x0],_amount);
            allowed[_from][0x0] = safeSub(allowed[_from][0x0],_amount);
            totalSupply = safeSub(totalSupply,_amount);
            Transfer(_from, 0x0, _amount);
            return true;
        } else {
            return false;
        }
    }

     
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success) 
    {
        return ERC20(tokenAddress).transfer(owner, amount);
    }
}