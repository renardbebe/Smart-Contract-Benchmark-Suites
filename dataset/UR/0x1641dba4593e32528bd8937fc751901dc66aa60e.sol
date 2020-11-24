 

 


pragma solidity ^0.4.19;

contract owned {

    address public owner;
    address public candidate;

  function owned() public payable {
         owner = msg.sender;
     }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        candidate = _owner;
    }
    
    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract Token is owned, ERC20 {

    string  public standard    = 'Token 0.1';
    string  public name        = 'eHealth First';
    string  public symbol      = "EHF";
    uint8   public decimals    = 8;

    uint    public freezedMoment;

    struct TokenHolder {
        uint balance;
        uint balanceBeforeUpdate;
        uint balanceUpdateTime;
    }
    mapping (address => TokenHolder) public holders;
    mapping (address => uint) public vesting;
    mapping (address => mapping (address => uint256)) public allowed;

    address public vestingManager;

    function setVestingManager(address _vestingManager) public onlyOwner {
        vestingManager = _vestingManager;
    }

    function beforeBalanceChanges(address _who) internal {
        if (holders[_who].balanceUpdateTime <= freezedMoment) {
            holders[_who].balanceUpdateTime = now;
            holders[_who].balanceBeforeUpdate = holders[_who].balance;
        }
    }

    event Burned(address indexed owner, uint256 value);

    function Token() public owned() {}

    function balanceOf(address _who) constant public returns (uint) {
        return holders[_who].balance;
    }

    function transfer(address _to, uint256 _value) public {
        require(now > vesting[msg.sender] || msg.sender == vestingManager);
        require(holders[_to].balance + _value >= holders[_to].balance);  
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(_to);
        holders[msg.sender].balance -= _value;
        holders[_to].balance += _value;
        if (vesting[_to] < vesting[msg.sender]) {
            vesting[_to] = vesting[msg.sender];
        }
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(now > vesting[_from]);
        require(holders[_to].balance + _value >= holders[_to].balance);  
        require(allowed[_from][msg.sender] >= _value);
        beforeBalanceChanges(_from);
        beforeBalanceChanges(_to);
        holders[_from].balance -= _value;
        holders[_to].balance += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) public {
        require(holders[msg.sender].balance >= _value);
        beforeBalanceChanges(msg.sender);
        holders[msg.sender].balance -= _value;
        totalSupply -= _value;
        emit Burned(msg.sender, _value);
    }
}

contract Crowdsale is Token {

    address public backend;

    uint public stage;
    bool public started;
    uint public startTokenPriceWei;
    uint public tokensForSale;
    uint public startTime;
    uint public lastTokenPriceWei;
    uint public milliPercent;  
    uint public paymentsCount;  
    bool public sealed;
    modifier notSealed {
        require(sealed == false);
        _;
    }

    event Mint(address indexed _who, uint _tokens, uint _coinType, bytes32 _txHash);
    event Stage(uint _stage, bool startNotFinish);

    function Crowdsale() public Token() {
        totalSupply = 100000000*100000000;
        holders[this].balance = totalSupply;
    }

    function startStage(uint _startTokenPriceWei, uint _tokensForSale, uint _milliPercent) public onlyOwner notSealed {
        require(!started);
        require(_startTokenPriceWei >= lastTokenPriceWei);
        startTokenPriceWei = _startTokenPriceWei;
        tokensForSale = _tokensForSale * 100000000;
        if(tokensForSale > holders[this].balance) {
            tokensForSale = holders[this].balance;
        }
        milliPercent = _milliPercent;
        startTime = now;
        started = true;
        paymentsCount = 0;
        emit Stage(stage, started);
    }
    
    function currentTokenPrice() public constant returns(uint) {
        uint price;
        if(!sealed && started) {
            uint d = (now - startTime) / 1 days;
            price = startTokenPriceWei;
            price += startTokenPriceWei * d * milliPercent / 100;
        }
        return price;
    }
    
    function stopStage() public onlyOwner notSealed {
        require(started);
        started = false;
        lastTokenPriceWei = currentTokenPrice();
        emit Stage(stage, started);
        ++stage;
    }
    
    function () payable public notSealed {
        require(started);
        uint price = currentTokenPrice();
        if(paymentsCount < 100) {
            price = price * 90 / 100;
        }
        ++paymentsCount;
        uint tokens = 100000000 * msg.value / price;
        if(tokens > tokensForSale) {
            tokens = tokensForSale;
            uint sumWei = tokens * lastTokenPriceWei / 100000000;
            require(msg.sender.call.gas(3000000).value(msg.value - sumWei)());
        }
        require(tokens > 0);
        require(holders[msg.sender].balance + tokens > holders[msg.sender].balance);  
        tokensForSale -= tokens;
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(this);
        holders[msg.sender].balance += tokens;
        holders[this].balance -= tokens;
        emit Transfer(this, msg.sender, tokens);
    }

    function mintTokens1(address _who, uint _tokens, uint _coinType, bytes32 _txHash) public notSealed {
        require(msg.sender == owner || msg.sender == backend);
        require(started);
        _tokens *= 100000000;
        if(_tokens > tokensForSale) {
            _tokens = tokensForSale;
        }
        require(_tokens > 0);
        require(holders[_who].balance + _tokens > holders[_who].balance);  
        tokensForSale -= _tokens;
        beforeBalanceChanges(_who);
        beforeBalanceChanges(this);
        holders[_who].balance += _tokens;
        holders[this].balance -= _tokens;
        emit Mint(_who, _tokens, _coinType, _txHash);
        emit Transfer(this, _who, _tokens);
    }
    
     
    function mintTokens2(address _who, uint _tokens, uint _vesting) public notSealed {
        require(msg.sender == owner || msg.sender == backend);
        require(!started);
        require(_tokens > 0);
        _tokens *= 100000000;
        require(_tokens <= holders[this].balance);
        require(holders[_who].balance + _tokens > holders[_who].balance);  
        if(_vesting != 0) {
            vesting[_who] = _vesting;
        }
        beforeBalanceChanges(_who);
        beforeBalanceChanges(this);
        holders[_who].balance += _tokens;
        holders[this].balance -= _tokens;
        emit Mint(_who, _tokens, 0, 0);
        emit Transfer(this, _who, _tokens);
    }

     
    function seal() public onlyOwner {
        sealed = true;
    }
}

contract Ehfirst is Crowdsale {

   function Ehfirst() payable public Crowdsale() {}

    function setBackend(address _backend) public onlyOwner {
        backend = _backend;
    }
    
    function withdraw() public onlyOwner {
        require(owner.call.gas(3000000).value(address(this).balance)());
    }
    
    function freezeTheMoment() public onlyOwner {
        freezedMoment = now;
    }

     
    function freezedBalanceOf(address _who) constant public returns(uint) {
        if (holders[_who].balanceUpdateTime <= freezedMoment) {
            return holders[_who].balance;
        } else {
            return holders[_who].balanceBeforeUpdate;
        }
    }
}