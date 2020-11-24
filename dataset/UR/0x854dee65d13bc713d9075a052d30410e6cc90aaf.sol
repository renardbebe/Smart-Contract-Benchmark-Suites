 

pragma solidity ^0.4.24;


 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    ); 

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract Blacklist is Pausable{
    mapping (address => bool)  _blacklist;

    modifier whiteAddress() {
        require(_blacklist[msg.sender] == false);
        _;
    }

    function blacklist(address _spender) public view returns (bool) {
        return _blacklist[_spender];
    }

    function addBlacklist(address _spender) public onlyOwner {
        _blacklist[_spender] = true;
    }

    function removeBlacklist(address _spender) public onlyOwner {
        _blacklist[_spender] = false;
    }
}


 
contract StandardToken is ERC20,Blacklist {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused whiteAddress public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )   
        whenNotPaused
        whiteAddress
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));


        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused whiteAddress public returns (bool) {
        require(_value == 0 || (allowed[msg.sender][_spender] == 0));
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )   
        whenNotPaused
        whiteAddress
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        whenNotPaused
        whiteAddress
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract BANK is StandardToken {
     
    function () public {
        revert();
    }

    string public constant name = "Bank";
    string public constant symbol = "BANK";
    uint8 public constant decimals = 18;
    uint256 public constant initial_supply = 1000000000;

    
     
    constructor() public {
        totalSupply_ = initial_supply * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
}