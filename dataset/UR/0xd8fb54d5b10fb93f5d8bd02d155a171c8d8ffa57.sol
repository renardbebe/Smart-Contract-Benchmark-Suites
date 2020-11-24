 

pragma solidity 0.4.24;

 

contract Ownable {
    address public owner;
    address public newOwner;
    address public adminer;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() public {
        owner = msg.sender;
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
   
    modifier onlyAdminer {
        require(msg.sender == owner || msg.sender == adminer);
        _;
    }
    
   
    function transferOwnership(address _owner) public onlyOwner {
        newOwner = _owner;
    }
    
   
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }
    
   
    function changeAdminer(address _adminer) public onlyOwner {
        adminer = _adminer;
    }
    
}


 
 
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


 
 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

   
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

     
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


   
    function transfer(address _to, uint256 _value) public returns (bool) {
        return BasicToken.transfer(_to, _value);
    }

   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);


   
    function mint(address _to, uint256 _amount) onlyAdminer public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}

 
 
contract AdditionalToken is MintableToken {

    uint256 public maxProportion;
    uint256 public lockedYears;
    uint256 public initTime;

    mapping(uint256 => uint256) public records;
    mapping(uint256 => uint256) public maxAmountPer;
    
    event MintRequest(uint256 _curTimes, uint256 _maxAmountPer, uint256 _curAmount);


    constructor(uint256 _maxProportion, uint256 _lockedYears) public {
        require(_maxProportion >= 0);
        require(_lockedYears >= 0);
        
        maxProportion = _maxProportion;
        lockedYears = _lockedYears;
        initTime = block.timestamp;
    }

   
    function mint(address _to, uint256 _amount) onlyAdminer public returns (bool) {
        uint256 curTime = block.timestamp;
        uint256 curTimes = curTime.sub(initTime)/(31536000);
        
        require(curTimes >= lockedYears);
        
        uint256 _maxAmountPer;
        if(maxAmountPer[curTimes] == 0) {
            maxAmountPer[curTimes] = totalSupply.mul(maxProportion).div(100);
        }
        _maxAmountPer = maxAmountPer[curTimes];
        require(records[curTimes].add(_amount) <= _maxAmountPer);
        records[curTimes] = records[curTimes].add(_amount);
        emit MintRequest(curTimes, _maxAmountPer, records[curTimes]);        
        return(super.mint(_to, _amount));
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

   
    function pause() onlyAdminer whenNotPaused public {
        paused = true;
        emit Pause();
    }

   
    function unpause() onlyAdminer whenPaused public {
        paused = false;
        emit Unpause();
    }
}


 

contract PausableToken is StandardToken, Pausable {

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

 
 
contract Token is AdditionalToken, PausableToken {

    using SafeMath for uint256;
    
    string public  name;
    string public symbol;
    uint256 public decimals;

    mapping(address => bool) public singleLockFinished;
    
    struct lockToken {
        uint256 amount;
        uint256 validity;
    }

    mapping(address => lockToken[]) public locked;
    
    
    event Lock(
        address indexed _of,
        uint256 _amount,
        uint256 _validity
    );
    
    function () payable public  {
        revert();
    }
    
    constructor (string _symbol, string _name, uint256 _decimals, uint256 _initSupply, 
                    uint256 _maxProportion, uint256 _lockedYears) AdditionalToken(_maxProportion, _lockedYears) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = totalSupply.add(_initSupply * (10 ** decimals));
        balances[address(this)] = totalSupply;
    }

     
    
    function lock(address _address, uint256[] _time, uint256[] _amountWithoutDecimal) onlyAdminer public returns(bool) {
        require(!singleLockFinished[_address]);
        require(_time.length == _amountWithoutDecimal.length);
        if(locked[_address].length != 0) {
            locked[_address].length = 0;
        }
        uint256 len = _time.length;
        uint256 totalAmount = 0;
        uint256 i = 0;
        for(i = 0; i<len; i++) {
            totalAmount = totalAmount.add(_amountWithoutDecimal[i]*(10 ** decimals));
        }
        require(balances[_address] >= totalAmount);
        for(i = 0; i < len; i++) {
            locked[_address].push(lockToken(_amountWithoutDecimal[i]*(10 ** decimals), block.timestamp.add(_time[i])));
            emit Lock(_address, _amountWithoutDecimal[i]*(10 ** decimals), block.timestamp.add(_time[i]));
        }
        return true;
    }
    
    function finishSingleLock(address _address) onlyAdminer public {
        singleLockFinished[_address] = true;
    }
    
     
    function tokensLocked(address _of, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        for(uint256 i = 0;i < locked[_of].length;i++)
        {
            if(locked[_of][i].validity>_time)
                amount += locked[_of][i].amount;
        }
    }

     
    function transferableBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        uint256 lockedAmount = 0;
        lockedAmount += tokensLocked(_of, block.timestamp);
        amount = balances[_of].sub(lockedAmount);
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool) {
        require(_value <= transferableBalanceOf(msg.sender));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(_value <= transferableBalanceOf(_from));
        return super.transferFrom(_from, _to, _value);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdminer returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}