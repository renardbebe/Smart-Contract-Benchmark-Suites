 

pragma solidity 0.5.1; 


library SafeMath {

    uint256 constant internal MAX_UINT = 2 ** 256 - 1;  

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
        if (_a == 0) {
            return 0;
        }
        require(MAX_UINT / _a >= _b);
        return _a * _b;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b != 0);
        return _a / _b;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        return _a - _b;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(MAX_UINT - _a >= _b);
        return _a + _b;
    }

}


contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
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


contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    mapping (address => bool) public frozenAccount;

    uint256 internal totalSupply_;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vaule
    );

    event FrozenFunds(
        address indexed _account, 
        bool _frozen
    );

     
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns(bool) {
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


contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed account, uint256 value);

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0)); 
        totalSupply_ = totalSupply_.sub(value);
        balances[account] = balances[account].sub(value);
        emit Burn(account, value);
        emit Transfer(account, address(0), value);
    }

     
    function burn(uint256 value) public onlyOwner {
        _burn(msg.sender, value);
    }
}


contract PausableToken is StandardToken, Pausable {
    function approve(
        address _spender,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    whenNotPaused
    returns(bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    whenNotPaused
    returns(bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


 
contract AQQToken is PausableToken, BurnableToken {
    using SafeMath for uint256;

    string public constant name = "AQQ";  
    string public constant symbol = "AQQ";  
    uint8 public constant decimals = 18;  

    uint256 internal vestingToken; 
    uint256 public initialCirculatingToken; 
    address constant wallet = 0xC151c00E83988ce3774Cde684f0209AD46C12aFC; 

    uint256 constant _INIT_TOTALSUPPLY = 100000000; 
    uint256 constant _INIT_VESTING_TOKEN = 60000000; 
    uint256 constant _INIT_CIRCULATE_TOKEN = 10000000;

   
    constructor() public {
        totalSupply_ = _INIT_TOTALSUPPLY * 10 ** uint256(decimals);  
        vestingToken = _INIT_VESTING_TOKEN * 10 ** uint256(decimals);  
        initialCirculatingToken = _INIT_CIRCULATE_TOKEN * 10 ** uint256(decimals);  
        owner = wallet;  
        balances[wallet] = totalSupply_;
    }

   
    function getVestingToken() public view returns(uint256 amount){
        if(now < 1546272000) {  
            return vestingToken;
        }else if(now < 1577808000) {  
            return vestingToken.sub(20000000 * 10 ** uint256(decimals));
        }else if(now < 1609430400) {  
            return vestingToken.sub(40000000 * 10 ** uint256(decimals));
        }else {
            return 0;
        }
    }

   
    function _validate(address _addr, uint256 _value) internal view {
        uint256 vesting = getVestingToken();
        require(balances[_addr] >= vesting.add(_value));
    }

     
    function transfer(
        address _to, 
        uint256 _value
    ) 
    public 
    whenNotPaused 
    returns(bool) {
        require(_to != address(0));
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);
        require(_value <= balances[msg.sender]);
        if(msg.sender == wallet) {
            _validate(msg.sender, _value);
        }
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
    public
    whenNotPaused
    returns(bool) {
        require(_to != address(0));
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        if(_from == wallet) {
            _validate(_from, _value);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function freezeAccount(address _account, bool _freeze) public onlyOwner returns(bool) {
        frozenAccount[_account] = _freeze;
        emit FrozenFunds(_account, _freeze);    
        return true;    
    }

   
    function _batchTransfer(address[] memory _to, uint256[] memory _amount) internal whenNotPaused {
        require(_to.length == _amount.length);
        uint256 sum = 0; 
        for(uint256 i = 0;i < _to.length;i += 1){
            require(_to[i] != address(0)); 
            require(!frozenAccount[_to[i]]); 
            sum = sum.add(_amount[i]);
            require(sum <= balances[msg.sender]);  
            balances[_to[i]] = balances[_to[i]].add(_amount[i]); 
            emit Transfer(msg.sender, _to[i], _amount[i]);
        } 
        _validate(msg.sender, sum);
        balances[msg.sender] = balances[msg.sender].sub(sum); 
    }

   
    function airdrop(address[] memory _to, uint256[] memory _amount) public onlyOwner returns(bool){
        _batchTransfer(_to, _amount);
        return true;
    }

   
    function burn(uint256 value) public onlyOwner {
        _validate(msg.sender, value);
        super.burn(value); 
    }
}