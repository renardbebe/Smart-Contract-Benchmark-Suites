 

pragma solidity ^0.4.21;



 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;

        return c;
    }

    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    function plus(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

 

 
contract ERC20Token {
    uint256 public totalSupply;   

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



 

 
contract TokenSafe {
    using SafeMath for uint;

     
    ERC20Token token;

    struct Group {
         
         
        uint256 releaseTimestamp;
         
        uint256 remaining;
         
        mapping (address => uint) balances;
    }

     
    mapping (uint8 => Group) public groups;

     
    constructor(address _token) public {
        token = ERC20Token(_token);
    }

     
    function init(uint8 _id, uint _releaseTimestamp) internal {
        require(_releaseTimestamp > 0);

        Group storage group = groups[_id];
        group.releaseTimestamp = _releaseTimestamp;
    }

     
    function add(uint8 _id, address _account, uint _balance) internal {
        Group storage group = groups[_id];
        group.balances[_account] = group.balances[_account].plus(_balance);
        group.remaining = group.remaining.plus(_balance);
    }

     
    function release(uint8 _id, address _account) public {
        Group storage group = groups[_id];
        require(now >= group.releaseTimestamp);

        uint tokens = group.balances[_account];
        require(tokens > 0);

        group.balances[_account] = 0;
        group.remaining = group.remaining.minus(tokens);

        if (!token.transfer(_account, tokens)) {
            revert();
        }
    }
}






 

 
contract StandardToken is ERC20Token {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

     
    constructor(string _name, string _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        executeTransfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].minus(_value);
        executeTransfer(_from, _to, _value);

        return true;
    }

     
    function executeTransfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value != 0 && _value <= balances[_from]);

        balances[_from] = balances[_from].minus(_value);
        balances[_to] = balances[_to].plus(_value);

        emit Transfer(_from, _to, _value);
    }
}






 

 
contract MintableToken is StandardToken {
     
    address public minter;

     
    bool public mintingDisabled = false;

     
    event MintingDisabled();

     
    modifier canMint() {
        require(!mintingDisabled);
        _;
    }

     
    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

     
    constructor(address _minter) internal {
        minter = _minter;
    }

     
    function mint(address _to, uint256 _value) public onlyMinter canMint {
        totalSupply = totalSupply.plus(_value);
        balances[_to] = balances[_to].plus(_value);

        emit Transfer(0x0, _to, _value);
    }

     
    function disableMinting() public onlyMinter canMint {
        mintingDisabled = true;

        emit MintingDisabled();
    }
}

 

 
contract BurnableToken is StandardToken {
     
    event Burn(address indexed _from, uint256 _value);

     
    function burn(uint256 _value) public {
        require(_value != 0);

        address burner = msg.sender;
        require(_value <= balances[burner]);

        balances[burner] = balances[burner].minus(_value);
        totalSupply = totalSupply.minus(_value);

        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

 

 
contract HasOwner {
     
    address public owner;

     
    address public newOwner;

     
    constructor(address _owner) public {
        owner = _owner;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    event OwnershipTransfer(address indexed _oldOwner, address indexed _newOwner);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransfer(owner, newOwner);

        owner = newOwner;
    }
}

 

 
contract PausableToken is StandardToken, HasOwner {

     
    bool public paused = false;

     
    event Pause();

     
    event Unpause();

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner {
        require(paused);

        paused = false;
        emit Unpause();
    }

     

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}









 

contract StandardMintableToken is MintableToken {
    constructor(address _minter, string _name, string _symbol, uint8 _decimals)
        StandardToken(_name, _symbol, _decimals)
        MintableToken(_minter)
        public
    {
    }
}












 

contract CoinwareToken is MintableToken, BurnableToken, PausableToken {
    constructor(address _owner, address _minter)
        StandardToken(
            "CoinwareToken",    
            "CWT",  
            18   
        )
        HasOwner(_owner)
        MintableToken(_minter)
        public
    {
    }
}