 

pragma solidity ^0.5.3;

contract Token {

     
    function totalSupply() public view returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) public  returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Stoppable is Ownable {
    bool public stopped;
    
    constructor() public {
        stopped = false;
    }
    
    modifier stoppable() {
        if (stopped) {
            revert();
        }
        _;
    }
    
    function stop() public onlyOwner {
        stopped = true;
    }
    
    function start() public onlyOwner {
        stopped = false;
    }
}

contract StandardToken is Token, Stoppable {

    function transfer(address _to, uint256 _value) public stoppable returns (bool success) {
        if (_value > 0 && balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] && _value > 0) {
            allowed[_from][msg.sender] -= _value;
            balances[_from] -= _value;
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public stoppable returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public stoppable view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public _totalSupply;
}


contract CCCToken is StandardToken {

    function () external {
         
        revert();
    }


    string public name = 'Coinchat Coin';
    uint8 public decimals = 18;
    string public symbol = 'CCC';
    string public version = 'v201901311334';


    constructor() public {
        balances[msg.sender] = 21000000000000000000000000000;
        _totalSupply = 21000000000000000000000000000;
        name = "Coinchat Coin";
        decimals = 18;
        symbol = "CCC";
    }
}