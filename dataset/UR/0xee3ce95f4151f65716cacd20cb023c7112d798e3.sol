 

pragma solidity 0.5.11;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address payable public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    event FrozenFunds(address target, bool frozen);

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf(_from) >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


 
contract Pausable is StandardToken {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused || msg.sender == owner);
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


contract PausableToken is Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
     
     

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract INMGToken is PausableToken {

     
    uint256 MONTH = 2592000;

    string public name;
    string public symbol;
    uint8 public decimals;

    event TokensBurned(address indexed _owner, uint256 _tokens);

    address founder;
     
    constructor() public {
        name = "INMINING";
        symbol = "INMG";
        decimals = 18;
        totalSupply = 150000000 * 1000000000000000000;
        
        founder = 0x607804DF9171a14F08171D5Ff6AE383810aef404;
        balances[founder] = totalSupply;
        emit Transfer(address(0x0), founder, totalSupply);
         
    }

     
    function burnTokens(uint256 _tokens) public onlyOwner {
        require(balanceOf(msg.sender) >= _tokens);
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        emit TokensBurned(msg.sender, _tokens);
    }

     
    mapping(address=>uint256) assignedTokenBalances;
    
    mapping(address=>uint256) assignmentTimestamp;

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner).sub(getLockedAssignedBalance(_owner));
    }
    
     
    function getLockedAssignedBalance(address _holder) public view returns(uint256) {
        uint monthPassed = getMonthsPassed(getAssignmentTimestamp(_holder));
        uint256 percentUnlocked = monthPassed.div(6).mul(33);
        if(percentUnlocked>=99){
            percentUnlocked = 100;
        }
        uint percentLocked = uint(100).sub(percentUnlocked);
        return getAllAssignedBalance(_holder).div(100).mul(percentLocked);
    }

    function getAllAssignedBalance(address _holder) public view returns(uint256) {
        return assignedTokenBalances[_holder];
    }

    function getAssignmentTimestamp(address _holder) public view returns(uint256) {
        return assignmentTimestamp[_holder];
    }
    
     
    function getMonthsPassed(uint256 _since) internal view returns(uint256){
        return (block.timestamp.sub(_since)).div(MONTH);
    }
    
     
    function assignTokens(address _benefitiary, uint256 _amount) public onlyOwner {
        assignedTokenBalances[_benefitiary] =assignedTokenBalances[_benefitiary].add(_amount);
        assignmentTimestamp[_benefitiary]=block.timestamp;
        transfer(_benefitiary,_amount);
    }

    function selfdestruct() external onlyOwner{
        selfdestruct(owner);
    }
}