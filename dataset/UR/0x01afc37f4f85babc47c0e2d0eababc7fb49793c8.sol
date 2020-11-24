 

 

pragma solidity ^0.4.2;

 
 

contract ERC20Constant {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance(address owner, address spender) constant returns (uint _allowance);
}
contract ERC20Stateful {
    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
}
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}
contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract ERC20Base is ERC20
{
    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    function ERC20Base( uint initial_balance ) {
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
    }
    function totalSupply() constant returns (uint supply) {
        return _supply;
    }
    function balanceOf( address who ) constant returns (uint value) {
        return _balances[who];
    }
    function transfer( address to, uint value) returns (bool ok) {
        if( _balances[msg.sender] < value ) {
            throw;
        }
        if( !safeToAdd(_balances[to], value) ) {
            throw;
        }
        _balances[msg.sender] -= value;
        _balances[to] += value;
        Transfer( msg.sender, to, value );
        return true;
    }
    function transferFrom( address from, address to, uint value) returns (bool ok) {
         
        if( _balances[from] < value ) {
            throw;
        }
         
        if( _approvals[from][msg.sender] < value ) {
            throw;
        }
        if( !safeToAdd(_balances[to], value) ) {
            throw;
        }
         
        _approvals[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        Transfer( from, to, value );
        return true;
    }
    function approve(address spender, uint value) returns (bool ok) {
        _approvals[msg.sender][spender] = value;
        Approval( msg.sender, spender, value );
        return true;
    }
    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return _approvals[owner][spender];
    }
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
}

contract ReducedToken {
    function balanceOf(address _owner) returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
    function migrate(uint256 _value);
}

contract DepositBrokerInterface {
    function clear();
}

contract TokenWrapperInterface is ERC20 {
    function withdraw(uint amount);

     
    function createBroker() returns (DepositBrokerInterface);

     
    function notifyDeposit(uint amount);

    function getBroker(address owner) returns (DepositBrokerInterface);
}

contract DepositBroker is DepositBrokerInterface {
    ReducedToken _g;
    TokenWrapperInterface _w;
    function DepositBroker( ReducedToken token ) {
        _w = TokenWrapperInterface(msg.sender);
        _g = token;
    }
    function clear() {
        var amount = _g.balanceOf(this);
        _g.transfer(_w, amount);
        _w.notifyDeposit(amount);
    }
}

contract TokenWrapperEvents {
    event LogBroker(address indexed broker);
}

 
contract TokenWrapper is ERC20Base(0), TokenWrapperInterface, TokenWrapperEvents {
    ReducedToken _unwrapped;
    mapping(address=>address) _broker2owner;
    mapping(address=>address) _owner2broker;
    function TokenWrapper( ReducedToken unwrapped) {
        _unwrapped = unwrapped;
    }
    function createBroker() returns (DepositBrokerInterface) {
        DepositBroker broker;
        if( _owner2broker[msg.sender] == address(0) ) {
            broker = new DepositBroker(_unwrapped);
            _broker2owner[broker] = msg.sender;
            _owner2broker[msg.sender] = broker;
            LogBroker(broker);
        }
        else {
            broker = DepositBroker(_owner2broker[msg.sender]);
        }
        
        return broker;
    }
    function notifyDeposit(uint amount) {
        var owner = _broker2owner[msg.sender];
        if( owner == address(0) ) {
            throw;
        }
        _balances[owner] += amount;
        _supply += amount;
    }
    function withdraw(uint amount) {
        if( _balances[msg.sender] < amount ) {
            throw;
        }
        _balances[msg.sender] -= amount;
        _supply -= amount;
        _unwrapped.transfer(msg.sender, amount);
    }
    function getBroker(address owner) returns (DepositBrokerInterface) {
        return DepositBroker(_owner2broker[msg.sender]);
    }
}