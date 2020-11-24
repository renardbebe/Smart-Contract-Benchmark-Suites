 

pragma solidity ^0.4.19;

 

 
contract ERC20 {
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

uint256 public totalSupply;
function balanceOf(address _owner) constant public returns (uint256 balance);
function transfer(address _to, uint256 _value) public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
function approve(address _spender, uint256 _value) public returns (bool success);
function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
}

 
contract SafeMath {
     
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }

     
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        if (a == 0 || b == 0) return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
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
        if (_newOwner != 0x0) {
          newOwner = _newOwner;
        }
    }

     
    function acceptOwnership() {
        require(msg.sender == newOwner);
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

 
contract StandardToken is ERC20, SafeMath {

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) internal allowed;

     
    mapping (address => mapping (address => uint256)) spentamount;

     
    mapping (address => bool) buyerAppended;

     
    address[] buyers;

     
    address[] vips;

     
    mapping (address => uint256) viprank;

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(_to != 0x0);
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] = safeSub(balances[msg.sender],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) 
        returns (bool success) {
        require(_to != 0x0);
        if(_from == _to) return false;
        if (balances[_from] < _value) return false;
        if (_value > allowed[_from][msg.sender]) return false;

        balances[_from] = safeSub(balances[_from],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {

         
         
         
         
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

     
     function allowance(address _owner, address _spender) constant 
        returns (uint256 remaining) {
       return allowed[_owner][_spender];
     }
}

 
contract LooksCoin is StandardToken, Ownable {

    uint256 public constant decimals = 0;

     
    uint256 public constant VIP_MINIMUM = 24000;

     
    uint256 constant INITIAL_TOKENS_COUNT = 100000000;

     
    address public tokenSaleContract = 0x0;

     
    address coinmaster = address(0x33169f40d18c6c2590901db23000D84052a11F54);

     
    function LooksCoin(address _tokenSaleContract) {
        assert(_tokenSaleContract != 0x0);
        owner = coinmaster;
        tokenSaleContract = _tokenSaleContract;
        balances[owner] = INITIAL_TOKENS_COUNT;
        totalSupply = INITIAL_TOKENS_COUNT;
    }

     
    function name() constant returns (string name) {
      return "LooksCoin";
    }

     
    function symbol() constant returns (string symbol) {
      return "LOOKS";
    }

     
    function setSaleManageContract(address _newSaleManageContract) {
        require(msg.sender == owner);
        assert(_newSaleManageContract != 0x0);
        tokenSaleContract = _newSaleManageContract;
    }

     
    function getVIPRank(address _to) constant public returns (uint256 rank) {
        if (balances[_to] < VIP_MINIMUM) {
            return 0;
        }
        return viprank[_to];
    }

     
    function updateVIPRank(address _to) returns (uint256 rank) {
         
         
        if (balances[_to] >= VIP_MINIMUM && viprank[_to] == 0) {
            viprank[_to] = now;
            vips.push(_to);
        }
        return viprank[_to];
    }

    event TokenRewardsAdded(address indexed participant, uint256 balance);
     
    function rewardTokens(address _to, uint256 _value) {
        require(msg.sender == tokenSaleContract || msg.sender == owner);
        assert(_to != 0x0);
        require(_value > 0);

        balances[_to] = safeAdd(balances[_to], _value);
        totalSupply = safeAdd(totalSupply, _value);
        updateVIPRank(_to);
        TokenRewardsAdded(_to, _value);
    }

    event SpentTokens(address indexed participant, address indexed recipient, uint256 amount);
     
    function spend(address _to, uint256 _value) public returns (bool success) {
        require(_value > 0);
        assert(_to != 0x0);
        if (balances[msg.sender] < _value) return false;

        balances[msg.sender] = safeSub(balances[msg.sender],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        spentamount[msg.sender][_to] = safeAdd(spentamount[msg.sender][_to], _value);

        SpentTokens(msg.sender, _to, _value);
        if(!buyerAppended[msg.sender]) {
            buyerAppended[msg.sender] = true;
            buyers.push(msg.sender);
        }
        return true;
    }

    function getSpentAmount(address _who, address _to) constant returns (uint256) {
        return spentamount[_who][_to];
    }

    event Burn(address indexed burner, uint256 value);
     
    function burnTokens(address burner, uint256 _value) public returns (bool success) {
        require(msg.sender == burner || msg.sender == owner);
        assert(burner != 0x0);
        if (_value > totalSupply) return false;
        if (_value > balances[burner]) return false;
        
        balances[burner] = safeSub(balances[burner],_value);
        totalSupply = safeSub(totalSupply,_value);
        Burn(burner, _value);
        return true;
    }

    function getVIPOwner(uint256 index) constant returns (address) {
        return (vips[index]);
    }

    function getVIPCount() constant returns (uint256) {
        return vips.length;
    }

    function getBuyer(uint256 index) constant returns (address) {
        return (buyers[index]);
    }

    function getBuyersCount() constant returns (uint256) {
        return buyers.length;
    }
}

 
contract LooksCoinCrowdSale {
    LooksCoin public looksCoin;
    ERC20 public preSaleToken;

     
    uint256 public constant TOKEN_PRICE_N = 1e18;
     
    uint256 public constant TOKEN_PRICE_D = 2400;
     

    address saleController = 0x0;

     
    uint256 public importedTokens = 0;

     
    uint256 public tokensSold = 0;

     
    address fundstorage = 0x0;

     
    enum State{
        Pause,
        Init,
        Running,
        Stopped,
        Migrated
    }

    State public currentState = State.Running;    

     
    modifier onCrowdSaleRunning() {
         
        require(currentState == State.Running);
        _;
    }

     
    function LooksCoinCrowdSale() {
        saleController = msg.sender;
        fundstorage = msg.sender;
        looksCoin = new LooksCoin(this);

        preSaleToken = ERC20(0x253C7dd074f4BaCb305387F922225A4f737C08bd);
    }

     
    function setState(State _newState)
    {
        require(msg.sender == saleController);
        currentState = _newState;
    }

     
    function setSaleController(address _newSaleController) {
        require(msg.sender == saleController);
        assert(_newSaleController != 0x0);
        saleController = _newSaleController;
    }

     
    function setWallet(address _fundstorage) {
        require(msg.sender == saleController);
        assert(_fundstorage != 0x0);
        fundstorage = _fundstorage;
        WalletUpdated(fundstorage);
    }
    event WalletUpdated(address newWallet);

     
    mapping (address => bool) private importedFromPreSale;

    event TokensImport(address indexed participant, uint256 tokens, uint256 totalImport);
     
    function importTokens(address _account) returns (bool success) {
         
        require(currentState == State.Running);
        require(msg.sender == saleController || msg.sender == _account);
        require(!importedFromPreSale[_account]);

         
        uint256 preSaleBalance = preSaleToken.balanceOf(_account) / TOKEN_PRICE_N;

        if (preSaleBalance == 0) return false;

        looksCoin.rewardTokens(_account, preSaleBalance);
        importedTokens = importedTokens + preSaleBalance;
        importedFromPreSale[_account] = true;
        TokensImport(_account, preSaleBalance, importedTokens);
        return true;
    }

     
    function() public payable {
        buyTokens();
    }

    event TokensBought(address indexed buyer, uint256 ethers, uint256 tokens, uint256 tokensSold);
     
    function buyTokens() payable returns (uint256 amount)
    {
        require(currentState == State.Running);
        assert(msg.sender != 0x0);
        require(msg.value > 0);

         
        uint256 tokens = msg.value * TOKEN_PRICE_D / TOKEN_PRICE_N;
        if (tokens == 0) return 0;

        looksCoin.rewardTokens(msg.sender, tokens);
        tokensSold = tokensSold + tokens;

         
        assert(fundstorage.send(msg.value));
        TokensBought(msg.sender, msg.value, tokens, tokensSold);
        return tokens;
    }
}