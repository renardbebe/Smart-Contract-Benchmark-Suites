 

pragma solidity ^0.4.19;

contract ERC20 {


    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external constant returns (uint);

    function balanceOf(address _owner) external constant returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external constant returns (uint256);

}

library SafeMath {

     
    function ADD (uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function SUB (uint256 a, uint256 b) pure internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
}

contract Ownable {


    address owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    function Ownable() public {
        owner = msg.sender;
        OwnershipTransferred (address(0), owner);
    }

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        notZeroAddress(_newOwner)
    {
        owner = _newOwner;
        OwnershipTransferred(msg.sender, _newOwner);
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0));
        _;
    }

}

 
contract Trustable is Ownable {


     
    mapping (address => bool) trusted;

    event AddTrusted (address indexed _trustable);
    event RemoveTrusted (address indexed _trustable);

    function Trustable() public {
        trusted[msg.sender] = true;
        AddTrusted(msg.sender);
    }

     
    function addTrusted(address _address)
        external
        onlyOwner
        notZeroAddress(_address)
    {
        trusted[_address] = true;
        AddTrusted(_address);
    }

     
    function removeTrusted(address _address)
        external
        onlyOwner
        notZeroAddress(_address)
    {
        trusted[_address] = false;
        RemoveTrusted(_address);
    }

}

contract Pausable is Trustable {


     
    bool public paused;
     
    uint256 public pauseBlockNumber;
     
    uint256 public resumeBlockNumber;

    event Pause(uint256 _blockNumber);
    event Unpause(uint256 _blockNumber);

    function pause()
        public
        onlyOwner
        whenNotPaused
    {
        paused = true;
        pauseBlockNumber = block.number;
        resumeBlockNumber = 0;
        Pause(pauseBlockNumber);
    }

    function unpause()
        public
        onlyOwner
        whenPaused
    {
        paused = false;
        resumeBlockNumber = block.number;
        pauseBlockNumber = 0;
        Unpause(resumeBlockNumber);
    }

    modifier whenNotPaused {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

}

 
contract Token is ERC20, Pausable{


    using SafeMath for uint256;

     
    uint256 _totalSupply = 56000000000000000; 

     
    mapping (address => uint256)  balances;
     
    mapping (address => mapping (address => uint256)) allowed;

     
    event Burn(address indexed _from, uint256 _value);
     
    event CrowdsaleEndChanged (uint256 _crowdsaleEnd, uint256 _newCrowdsaleEnd);

     
    function totalSupply() external constant returns (uint256 totalTokenSupply) {
        totalTokenSupply = _totalSupply;
    }

     
    function balanceOf(address _owner)
        external
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount)
        external
        notZeroAddress(_to)
        whenNotPaused
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].SUB(_amount);
        balances[_to] = balances[_to].ADD(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        external
        notZeroAddress(_to)
        whenNotPaused
        returns (bool success)
    {
         
        require(allowed[_from][msg.sender] >= _amount);
        balances[_from] = balances[_from].SUB(_amount);
        balances[_to] = balances[_to].ADD(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
     
    function approve(address _spender, uint256 _amount)
        external
        whenNotPaused
        notZeroAddress(_spender)
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        external
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        external
        whenNotPaused
        returns (bool success)
    {
        uint256 increased = allowed[msg.sender][_spender].ADD(_addedValue);
        require(increased <= balances[msg.sender]);
         
        allowed[msg.sender][_spender] = increased;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        external
        whenNotPaused
        returns (bool success)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.SUB(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        require(trusted[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].SUB(_value);
         
        _totalSupply = _totalSupply.SUB(_value);
        Burn(msg.sender, _value);
        return true;
    }

}

 
contract OutingToken is Token{

     
    string public constant name = "Outing";
     
    string public constant symbol = "OTG";
     
    uint8 public constant decimals = 8;

     
     
    address public constant OUTINGRESERVE = 0xB8E6C4Eab5BC0eAF1f3D8A9a59a8A26112a56fE2;
     

    address public constant TEAM = 0x0702dd2f7DC2FF1dCc6beC2De9D1e6e0d467AfaC;
     
    uint256 public UNLOCK_OUTINGRESERVE = now + 262800 minutes;
     
    uint256 public UNLOCK_TEAM = now + 525600 minutes;
     
    uint256 public outingreserveBalance;
     
    uint256 public teamBalance;

     
    uint256 private constant OUTINGRESERVE_THOUSANDTH = 560;
     
    uint256 private constant TEAM_THOUSANDTH = 70;
     
    uint256 private constant ICO_THOUSANDTH = 370;
     
    uint256 private constant DENOMINATOR = 1000;

    function OutingToken() public {
         
        balances[msg.sender] = _totalSupply * ICO_THOUSANDTH / DENOMINATOR;
         
        outingreserveBalance = _totalSupply * OUTINGRESERVE_THOUSANDTH / DENOMINATOR;
         
        teamBalance = _totalSupply * TEAM_THOUSANDTH / DENOMINATOR;

        Transfer (this, msg.sender, balances[msg.sender]);
    }

     
    function unlockTokens(address _address) external {
        if (_address == OUTINGRESERVE) {
            require(UNLOCK_OUTINGRESERVE <= now);
            require (outingreserveBalance > 0);
            balances[OUTINGRESERVE] = outingreserveBalance;
            outingreserveBalance = 0;
            Transfer (this, OUTINGRESERVE, balances[OUTINGRESERVE]);
        } else if (_address == TEAM) {
            require(UNLOCK_TEAM <= now);
            require (teamBalance > 0);
            balances[TEAM] = teamBalance;
            teamBalance = 0;
            Transfer (this, TEAM, balances[TEAM]);
        }
    }
}