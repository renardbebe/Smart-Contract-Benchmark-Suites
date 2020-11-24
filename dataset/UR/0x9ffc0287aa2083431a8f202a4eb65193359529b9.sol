 

pragma solidity 0.5.10;
 
 
 
 
 

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;

  modifier whenNotPaused() {
    assert(!paused);
    _;
  }

  modifier whenPaused() {
    assert(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  function unpause() public onlyOwner whenPaused{
    paused = false;
    emit Unpause();
  }
}


contract TokenERC20 is Pausable {
     
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(allowance[_from][msg.sender] >= _value, "allowance[_from][msg.sender] < _value");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function _transfer(address _from, address _to, uint _value) internal whenNotPaused returns (bool success) {
         
        require(_to != address(0), "_to == address(0)");
         
        require(balanceOf[_from] >= _value, "balanceOf[_from] < _value");
         
        require(balanceOf[_to] + _value >= balanceOf[_to], "balanceOf[_to] + _value < balanceOf[_to]");
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        return true;
    }

}

 
 
 

contract MyAdvancedToken is TokenERC20 {
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply) TokenERC20(_name, _symbol, _decimals, _totalSupply) public {}

    function () external payable {
        assert(false);
    }

     
     
     
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
         
        require(!frozenAccount[_from], "frozenAccount[_from]");
         
        require(!frozenAccount[_to], "frozenAccount[_to]");

        return super._transfer(_from, _to, _value);
    }

}

contract PohcToken is MyAdvancedToken {
    mapping(address => uint) public lockdate;
    mapping(address => uint) public lockTokenBalance;

    event LockToken(address account, uint amount, uint unixtime);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply) MyAdvancedToken(_name, _symbol, _decimals, _totalSupply) public {}

    function lockTokenToDate(address _account, uint _amount, uint _unixtime) public onlyOwner {
        require(_unixtime >= lockdate[_account], "_unixtime < lockdate[_account]");
        require(_unixtime >= now, "_unixtime < now");
        if(balanceOf[_account] >= _amount) {
            lockdate[_account] = _unixtime;
            lockTokenBalance[_account] = _amount;
            emit LockToken(_account, _amount, _unixtime);
        }
    }

    function lockTokenDays(address _account, uint _amount, uint _days) public {
        uint unixtime = _days * 1 days + now;
        lockTokenToDate(_account, _amount, unixtime);
    }

    function getLockBalance(address _account) internal returns(uint) {
        if(now >= lockdate[_account]) {
            lockdate[_account] = 0;
            lockTokenBalance[_account] = 0;
        }
        return lockTokenBalance[_account];
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
        uint usableBalance = balanceOf[_from] - getLockBalance(_from);
        require(balanceOf[_from] >= usableBalance, "balanceOf[_from] < usableBalance");
        require(usableBalance >= _value, "usableBalance < _value");

        return super._transfer(_from, _to, _value);
    }

}