 

pragma solidity 0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
contract Pausable is Owned {
    bool public paused = false;

    event Pause();
    event Unpause();

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

 
 
 

contract CXToken is Pausable {
    using SafeMath for uint;  

    string public symbol;
    string public  name;
    uint8 public decimals = 18;
     
    uint public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public frozenAmount;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);

    event FrozenFunds(address target, bool frozen);
    event FrozenAmt(address target, uint256 value);
    event UnfrozenAmt(address target);

    constructor(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol
    ) public {
         
        totalSupply = initialSupply * 10 ** uint256(decimals);
         
        balanceOf[msg.sender] = totalSupply;
         
        name = tokenName;
         
        symbol = tokenSymbol;
    }

     
    function _transfer(address _from, address _to, uint _value) whenNotPaused internal {
        require (_to != 0x0);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        uint256 amount = balanceOf[_from].sub(_value);
        require(frozenAmount[_from] == 0 || amount >= frozenAmount[_from]);
        balanceOf[_from] = amount;
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value)
    public
    returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyOwner
    public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) onlyOwner
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value)
    public
    returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }


     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function freezeAmount(address target, uint256 _value) onlyOwner public {
        require(_value > 0);
        frozenAmount[target] = _value;
        emit FrozenAmt(target, _value);
    }

     
    function unfreezeAmount(address target) onlyOwner public {
        frozenAmount[target] = 0;
        emit UnfrozenAmt(target);
    }
}