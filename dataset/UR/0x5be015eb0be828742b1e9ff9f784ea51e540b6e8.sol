 

pragma solidity ^0.4.11;

 

 
contract ERC20 {
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _who) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool ok);
    function approve(address _spender, uint256 _value) returns (bool ok);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

   
contract SafeMath {
    uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        require (a <= MAX_UINT256 - b);
        return a + b;
    }

     
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }

     
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        if (a == 0 || b == 0) return 0;
        require (a <= MAX_UINT256 / b);
        return a * b;
    }
}

 
contract Ownable {
    address owner;
    address newOwner;

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
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

 
contract StandardToken is ERC20, Ownable, SafeMath {

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    function StandardToken() {
       
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
         
        if(_amount <= 0) return false;
        if (msg.sender == _to) return false;
        if (balances[msg.sender] < _amount) return false;
        if (balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = safeSub(balances[msg.sender],_amount);
            balances[_to] = safeAdd(balances[_to],_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        }
        return false;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
         
        if(_amount <= 0) return false;
        if(_from == _to) return false;
        if (balances[_from] < _amount) return false;
        if (_amount > allowed[_from][msg.sender]) return false;

        balances[_from] = safeSub(balances[_from],_amount);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);
        balances[_to] = safeAdd(balances[_to],_amount);
        Transfer(_from, _to, _amount);

        return false;
    }

     
    function approve(address _spender, uint256 _amount) returns (bool success) {

         
         
         
         
        if ((_amount != 0) && (allowed[msg.sender][_spender] != 0)) {
           return false;
        }
        if (balances[msg.sender] < _amount) {
            return false;
        }
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
     }

     
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
       return allowed[_owner][_spender];
     }
}

 
contract LooksCoin is StandardToken {

     
    address wallet = 0x0;

     
    mapping (address => uint256) viprank;

     
    uint256 public VIP_MINIMUM = 1000000;

     
    uint256 constant INITIAL_TOKENS_COUNT = 20000000000;

     
    uint256 tokensCount;

     
    uint256 public constant TOKEN_PRICE_N = 1e13;
     
    uint256 public constant TOKEN_PRICE_D = 1;
     
     

     
    function LooksCoin() payable {
        owner = msg.sender;
        wallet = msg.sender;
        tokensCount = INITIAL_TOKENS_COUNT;
        balances[owner] = tokensCount;
    }

     
    function name() constant returns (string name) {
      return "LOOK";
    }

     
    function symbol() constant returns (string symbol) {
      return "LOOK";
    }

     
    function decimals () constant returns (uint8 decimals) {
      return 6;
    }

     
    function totalSupply() constant returns (uint256 supply) {
      return tokensCount;
    }

     
    function setWallet(address _wallet) onlyOwner {
        wallet = _wallet;
        WalletUpdated(wallet);
    }
    event WalletUpdated(address newWallet);

     
    function getVIPRank(address participant) constant returns (uint256 rank) {
        if (balances[participant] < VIP_MINIMUM) {
            return 0;
        }
        return viprank[participant];
    }

     
    function() payable {
        buyToken();
    }

     
    function buyToken() public payable returns (uint256 amount)
    {
         
        uint256 tokens = safeMul(msg.value, TOKEN_PRICE_D) / TOKEN_PRICE_N;

         
        balances[msg.sender] = safeAdd(balances[msg.sender],tokens);
        tokensCount = safeAdd(tokensCount,tokens);

         
        Transfer(0x0, msg.sender, tokens);
         
         
         
         
         
        TokensBought(msg.sender, msg.value, balances[msg.sender], tokens, tokensCount);

         
         
        if (balances[msg.sender] >= VIP_MINIMUM && viprank[msg.sender] == 0) {
            viprank[msg.sender] = now;
        }

         
        assert(wallet.send(msg.value));
        return tokens;
    }

    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 participantTokenBalance, uint256 tokens, uint256 totalTokensCount);

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        return StandardToken.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success)
    {
        return StandardToken.transferFrom(_from, _to, _amount);
    }

     
    function burnTokens(uint256 _amount) returns (bool success) {
        if (_amount <= 0) return false;
        if (_amount > tokensCount) return false;
        if (_amount > balances[msg.sender]) return false;
        balances[msg.sender] = safeSub(balances[msg.sender],_amount);
        tokensCount = safeSub(tokensCount,_amount);
        Transfer(msg.sender, 0x0, _amount);
        return true;
    }
}