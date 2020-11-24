 

pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract ERC20 is owned {
     
    string public name = "PerfectChain Network";
    string public symbol = "PNN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * 10 ** uint256(decimals);

    bool public released = false;

     
    address public ICO_Contract;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
   
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
     
    event FrozenFunds(address target, bool frozen);

     
    constructor () public {
        balanceOf[owner] = totalSupply;
    }
    modifier canTransfer() {
        require(released ||  msg.sender == ICO_Contract || msg.sender == owner);
       _;
     }

    function releaseToken() public onlyOwner {
        released = true;
    }
     
    function _transfer(address _from, address _to, uint256 _value) canTransfer internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        require(!frozenAccount[_from]);
         
        require(!frozenAccount[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     
     
    function setICO_Contract(address _ICO_Contract) onlyOwner public {
        ICO_Contract = _ICO_Contract;
    }
}

contract Killable is owned {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}

contract ERC20_ICO is owned, Killable {
     
    ERC20 public token;

     
    uint256 public startsAt = 1528489000;

     
    uint256 public endsAt = 1530000000;

     
    uint256 public TokenPerETH = 5600;

     
    bool public finalized = false;

     
    uint256 public tokensSold = 0;

     
    uint256 public weiRaised = 0;

     
    uint256 public investorCount = 0;

     
    uint256 public Soft_Cap = 40000000000000000000000000;

     
    uint256 public Hard_Cap = 140000000000000000000000000;

     
    mapping (address => uint256) public investedAmountOf;

     
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
     
    event StartsAtChanged(uint256 startsAt);
     
    event EndsAtChanged(uint256 endsAt);
     
    event RateChanged(uint256 oldValue, uint256 newValue);
     
    event Refund(address investor, uint256 weiAmount);

    constructor (address _token) public {
        token = ERC20(_token);
    }

    function investInternal(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);
        require(tokensSold <= Hard_Cap);
        require(msg.value >= 10000000000000000);

        if(investedAmountOf[receiver] == 0) {
             
            investorCount++;
        }

         
        uint256 tokensAmount = msg.value * TokenPerETH;
        investedAmountOf[receiver] += msg.value;
         
        tokensSold += tokensAmount;
        weiRaised += msg.value;

         
        emit Invested(receiver, msg.value, tokensAmount);

        if (msg.value >= 100000000000000000 && msg.value < 10000000000000000000 ) {
             
            tokensAmount = tokensAmount * 120 / 100;
        }
        if (msg.value >= 10000000000000000000 && msg.value < 30000000000000000000) {
             
            tokensAmount = tokensAmount * 130 / 100;
        }
        if (msg.value >= 30000000000000000000) {
             
            tokensAmount = tokensAmount * 140 / 100;
        }

        token.transfer(receiver, tokensAmount);

         
        owner.transfer(address(this).balance);

    }

    function buy() public payable {
        investInternal(msg.sender);
    }

    function setStartsAt(uint256 time) onlyOwner public {
        require(!finalized);
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    function setEndsAt(uint256 time) onlyOwner public {
        require(!finalized);
        endsAt = time;
        emit EndsAtChanged(endsAt);
    }
    function setRate(uint256 value) onlyOwner public {
        require(!finalized);
        require(value > 0);
        emit RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }

    function finalize() public onlyOwner {
         
        finalized = true;
    }
}