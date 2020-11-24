 

pragma solidity 0.5.4;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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


contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed owner,uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 vaule);

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns(bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        totalSupply = totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
        emit Burn(account, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
         
         
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }

}


contract BurnableToken is StandardToken {

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


 
contract PausableToken is StandardToken, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract Token is PausableToken, BurnableToken {
    string public constant name = "Ti Value ERC20";  
    string public constant symbol = "TV";  
    uint8 public constant decimals = 8;

    uint256 internal constant INIT_TOTALSUPPLY = 289732065;  

    constructor() public {
        totalSupply = INIT_TOTALSUPPLY * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
}

 
interface PairContract {
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) external;
    function transfer(address _to, uint256 _value) external returns (bool);
    function decimals() external returns (uint8);
}

contract TV is Token {
     
    PairContract public pairInstance;
     
     
    uint public rate = 10000;   
    uint public constant RATE_PRECISE = 10000;

     
    event ExchangePair(address indexed from, uint256 value);
    event SetPairContract(address PairToken);
    event RateChanged(uint256 previousOwner,uint256 newRate);

     
    modifier onlyPairContract() {
        require(msg.sender == address(pairInstance));
        _;
    }

     
    function setPairContract(address pairAddress) public onlyOwner {
        require(pairAddress != address(0));
        pairInstance = PairContract(pairAddress);
        emit SetPairContract(pairAddress);
    }

     
     function setRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0);
        emit RateChanged(rate,_newRate);
        rate = _newRate;
     }

     
    function transfer(address to, uint value) public returns (bool) {
        super.transfer(to, value);  
        if(to == address(pairInstance)) {
            pairInstance.tokenFallback(msg.sender, value, bytes(""));  
            emit ExchangePair(msg.sender, value);
        }
        return true;
    }

     
    function transferFrom(address from, address to, uint value) public returns (bool) {
        super.transferFrom(from, to, value);  
        if(to == address(pairInstance)) {
            pairInstance.tokenFallback(from, value, bytes(""));  
            emit ExchangePair(from, value);
        }
        return true;
    }

     
    function tokenFallback(address from, uint256 value, bytes calldata) external onlyPairContract {
        require(from != address(0));
        require(value != uint256(0));
        require(pairInstance.transfer(owner,value));  
        uint256 TVValue = value.mul(10**uint256(decimals)).mul(rate).div(RATE_PRECISE).div(10**uint256(pairInstance.decimals()));  
        require(TVValue <= balances[owner]);
        balances[owner] = balances[owner].sub(TVValue);
        balances[from] = balances[from].add(TVValue); 
        emit Transfer(owner, from, TVValue);
    }
    
     
    function withdrawToken(uint256 value) public onlyOwner {
        require(pairInstance.transfer(owner,value));
    }    
}