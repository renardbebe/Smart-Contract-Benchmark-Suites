 

 

pragma solidity ^0.4.4;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function name() public constant returns(string);
    function symbol() public constant returns(string);

    function totalSupply() public constant returns(uint256 supply);
    function balanceOf(address _owner) public constant returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public constant returns(uint256 remaining);
    function decimals() public constant returns(uint8);
}

 
contract TokenHolders {
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     

    function validate() external constant returns (bool);

    function setBalance(address _to, uint256 _value) external;

     
    function transfer(address _from, address _to, uint256 _value) public returns(bool success);

     
    function approve(address _sender, address _spender, uint256 _value) public returns(bool success);

     
    function transferWithAllowance(address _origin, address _from, address _to, uint256 _value)
    public returns(bool success);
}

 
contract OptionToken {
    string public standard = 'ERC20';
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;

     
    uint256 public expiration = 1512172800;  
    uint256 public strike = 20000000000;

    ERC20 public baseToken;
    TokenHolders public tokenHolders;

    bool _initialized = false;


     
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

     
    event Deposit(address indexed from, uint256 value);
    event Redeem(address indexed from, uint256 value, uint256 ethvalue);
    event Issue(address indexed issuer, uint256 value);

     
    function OptionToken() public {
        owner = msg.sender;
    }

     
    function balanceOf(address _owner) public constant returns(uint256 balance) {
        return tokenHolders.balanceOf(_owner);
    }

    function totalSupply() public constant returns(uint256 supply) {
         
        return baseToken.balanceOf(this);
    }

     
    function transfer(address _to, uint256 _value) public returns(bool success) {
        if(now > expiration)
            return false;

        if(!tokenHolders.transfer(msg.sender, _to, _value))
            return false;

        Transfer(msg.sender, _to, _value);  
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool success) {
        if(now > expiration)
            return false;

        if(!tokenHolders.approve(msg.sender, _spender, _value))
            return false;

        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if(now > expiration)
            return false;

        if(!tokenHolders.transferWithAllowance(msg.sender, _from, _to, _value))
            return false;

        Transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return tokenHolders.allowance(_owner, _spender);
    }

     

     
    function init(ERC20 _baseToken, TokenHolders _tokenHolders, string _name, string _symbol,
                uint256 _exp, uint256 _strike) public returns(bool success) {
        require(msg.sender == owner && !_initialized);

        baseToken = _baseToken;
        tokenHolders = _tokenHolders;

         
        assert(baseToken.totalSupply() != 0);
         
        assert(tokenHolders.validate());

        name = _name;
        symbol = _symbol;
        expiration = _exp;
        strike = _strike;

        decimals = baseToken.decimals();

        _initialized = true;
        return true;
    }

     
    function issue(uint256 _value) public returns(bool success) {
        require(now <= expiration && _initialized);

        uint256 receiver_balance = balanceOf(msg.sender) + _value;
        assert(receiver_balance >= _value);

         
        if(!baseToken.transferFrom(msg.sender, this, _value))
            revert();

        tokenHolders.setBalance(msg.sender, receiver_balance);
        Issue(msg.sender, receiver_balance);

        return true;
    }

     
    function() public payable {
        require(now <= expiration && _initialized);  
        uint256 available = balanceOf(msg.sender);  

         
        require(available > 0);

        uint256 tokens = msg.value / (strike);
        assert(tokens > 0 && tokens <= msg.value);

        uint256 change = 0;
        uint256 eth_to_transfer = 0;

        if(tokens > available) {
            tokens = available;  
        }

         
        eth_to_transfer = tokens * strike;
        assert(eth_to_transfer >= tokens);
        change = msg.value - eth_to_transfer;
        assert(change < msg.value);

        if(!baseToken.transfer(msg.sender, tokens)) {
            revert();  
        }

        uint256 new_balance = balanceOf(msg.sender) - tokens;
        tokenHolders.setBalance(msg.sender, new_balance);

         
        assert(balanceOf(msg.sender) < available);

        if(change > 0) {
            msg.sender.transfer(change);  
        }

        if(eth_to_transfer > 0) {
            owner.transfer(eth_to_transfer);  
        }

        Redeem(msg.sender, tokens, eth_to_transfer);
    }

     
    function withdraw() public returns(bool success) {
        require(msg.sender == owner);
        if(now <= expiration || !_initialized)
            return false;

         
        baseToken.transfer(owner, totalSupply());

         
        baseToken = ERC20(0);
        tokenHolders = TokenHolders(0);
        _initialized = false;
        return true;
    }
}