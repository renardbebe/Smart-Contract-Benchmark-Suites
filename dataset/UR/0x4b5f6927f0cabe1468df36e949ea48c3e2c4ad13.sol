 

pragma solidity ^0.4.18;


contract Owner {
    address public owner;

    function Owner() {
        owner = msg.sender;
    }

    modifier  onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function  transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract TokenRecipient { 
    function receiveApproval(
        address _from, 
        uint256 _value, 
        address _token, 
        bytes _extraData); 
}


contract Token {
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function Token (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        string standardStr
    ) {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
        standard = standardStr;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) {
            revert();            
        }
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert();  
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    returns (bool success) 
    {    
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                this,
                _extraData
            );
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) {
            revert();                                         
        }                 
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert();   
        }
        if (_value > allowance[_from][msg.sender]) {
            revert();    
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
}


 
contract EXToken is Token, Owner {
    uint256 public constant INITIAL_SUPPLY = 100 * 10000 * 10000 * 100000000;  
    string public constant NAME = "coinex8";  
    string public constant SYMBOL = "ex8";  
    string public constant STANDARD = "coinex8 1.0";
    uint8 public constant DECIMALS = 8;
    uint256 public constant BUY = 0;  
    uint256 constant RATE = 1 szabo;
    bool private couldTrade = false;

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint minBalanceForAccounts;

    mapping (address => bool) frozenAccount;

    event FrozenFunds(address indexed _target, bool _frozen);

    function EXToken() Token(INITIAL_SUPPLY, NAME, DECIMALS, SYMBOL, STANDARD) {
        balanceOf[msg.sender] = totalSupply;
        buyPrice = 100000000;
        sellPrice = 100000000;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) {
            revert();            
        }
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert();  
        }
        if (frozenAccount[msg.sender]) {
            revert();                 
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) {
            revert();                         
        }     
        if (balanceOf[_from] < _value) {
            revert();                  
        }
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert();   
        }
        if (_value > allowance[_from][msg.sender]) {
            revert();    
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function freezeAccount(address _target, bool freeze) onlyOwner {
        frozenAccount[_target] = freeze;
        FrozenFunds(_target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable returns (uint amount) {
        require(couldTrade);
        amount = msg.value * RATE / buyPrice;
        require(balanceOf[this] >= amount);
        require(balanceOf[msg.sender] + amount >= amount);
        balanceOf[this] -= amount;
        balanceOf[msg.sender] += amount;
        Transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint256 amountInWeiDecimalIs18) returns (uint256 revenue) {
        require(couldTrade);
        uint256 amount = amountInWeiDecimalIs18;
        require(balanceOf[msg.sender] >= amount);
        require(!frozenAccount[msg.sender]);

        revenue = amount * sellPrice / RATE;
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;
        require(msg.sender.send(revenue));
        Transfer(msg.sender, this, amount);
        return revenue;
    }

    function withdraw(uint256 amount) onlyOwner returns (bool success) {
        require(msg.sender.send(amount));
        return true;
    }

    function setCouldTrade(uint256 amountInWeiDecimalIs18) onlyOwner returns (bool success) {
        couldTrade = true;
        require(balanceOf[msg.sender] >= amountInWeiDecimalIs18);
        require(balanceOf[this] + amountInWeiDecimalIs18 >= amountInWeiDecimalIs18);
        balanceOf[msg.sender] -= amountInWeiDecimalIs18;
        balanceOf[this] += amountInWeiDecimalIs18;
        Transfer(msg.sender, this, amountInWeiDecimalIs18);
        return true;
    }

    function stopTrade() onlyOwner returns (bool success) {
        couldTrade = false;
        uint256 _remain = balanceOf[this];
        require(balanceOf[msg.sender] + _remain >= _remain);
        balanceOf[msg.sender] += _remain;
        balanceOf[this] -= _remain;
        Transfer(this, msg.sender, _remain);
        return true;
    }

    function () {
        revert();
    }
}