 

pragma solidity ^0.4.18;

 
library SafeMath {
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
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

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

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

 
contract ERC223 is ERC20 {
    function transfer(address to, uint value, bytes data) public returns (bool ok);

    function transferFrom(address from, address to, uint value, bytes data) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract Standard223Token is ERC223, StandardToken {
     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
         
        require(super.transfer(_to, _value));
         
        if (isContract(_to)) return contractFallback(msg.sender, _to, _value, _data);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool success) {
        require(super.transferFrom(_from, _to, _value));
         
        if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
        return true;
    }

     
    function contractFallback(address _from, address _to, uint _value, bytes _data) private returns (bool success) {
        ERC223Receiver receiver = ERC223Receiver(_to);
        return receiver.tokenFallback(_from, _value, _data);
    }

     
    function isContract(address _addr) internal view returns (bool is_contract) {
         
        uint length;
        assembly {length := extcodesize(_addr)}
        return length > 0;
    }
}

 
contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}


 
contract FrozenToken is Ownable {
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    modifier requireNotFrozen(address from){
        require(!frozenAccount[from]);
        _;
    }
}


contract ERC223Receiver {
     
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool ok);
}



 
contract SocialLendingToken is Pausable, BurnableToken, Standard223Token, FrozenToken {

    string public name;
    string public symbol;
    uint public decimals;
    address public airdroper;


    function SocialLendingToken(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        totalSupply_ = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        airdroper = msg.sender;
        balances[msg.sender] = _initialSupply;
        Transfer(0x0, msg.sender, _initialSupply);
    }

    function transfer(address _to, uint _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_to) returns (bool) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_from) requireNotFrozen(_to) returns (bool) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    function approve(address _spender, uint _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_to) returns (bool success) {
        return super.transfer(_to, _value, _data);
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_from) requireNotFrozen(_to) returns (bool success) {
        return super.transferFrom(_from, _to, _value, _data);
    }

    event Airdrop(address indexed from, uint addressCount, uint totalAmount);
    event AirdropDiff(address indexed from, uint addressCount, uint totalAmount);
    event SetAirdroper(address indexed airdroper);

    function setAirdroper(address _airdroper) public onlyOwner returns (bool){
        require(_airdroper != address(0) && _airdroper != airdroper);
        airdroper = _airdroper;
        SetAirdroper(_airdroper);
        return true;
    }

    modifier onlyAirdroper(){
        require(msg.sender == airdroper);
        _;
    }

     
    function airdrop(uint _value, address[] _addresses) public whenNotPaused onlyAirdroper returns (bool success){
        uint addressCount = _addresses.length;
        require(addressCount > 0 && addressCount <= 1000);
        uint totalAmount = _value.mul(addressCount);
        require(_value > 0 && balances[msg.sender] >= totalAmount);

        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        for (uint i = 0; i < addressCount; i++) {
            require(_addresses[i] != address(0));
            balances[_addresses[i]] = balances[_addresses[i]].add(_value);
            Transfer(msg.sender, _addresses[i], _value);
        }
        Airdrop(msg.sender, addressCount, totalAmount);
        return true;
    }

    function airdropDiff(uint[] _values, address[] _addresses) public whenNotPaused onlyAirdroper returns (bool success){
        uint addressCount = _addresses.length;

        require(addressCount == _values.length);
        require(addressCount > 0 && addressCount <= 1000);

        uint totalAmount = 0;
        for (uint i = 0; i < addressCount; i++) {
            require(_values[i] > 0);
            totalAmount = totalAmount.add(_values[i]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        for (uint j = 0; j < addressCount; j++) {
            require(_addresses[j] != address(0));
            balances[_addresses[j]] = balances[_addresses[j]].add(_values[j]);
            Transfer(msg.sender, _addresses[j], _values[j]);
        }
        AirdropDiff(msg.sender, addressCount, totalAmount);
        return true;
    }
}