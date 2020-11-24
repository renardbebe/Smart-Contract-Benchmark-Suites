 

pragma solidity ^0.4.24;


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


contract ERC20 {

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract ERC223 {
    function transferdata(address to, uint value, bytes data) payable public;
    event Transferdata(address indexed from, address indexed to, uint value, bytes indexed data);
}


contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


contract ERCAddressFrozenFund is ERC20{

    using SafeMath for uint;

    struct LockedWallet {
        address owner;  
        uint256 amount;  
        uint256 start;  
        uint256 duration;  
        uint256 release;   
         
    }


    address public owner;

    uint256 _lockedSupply;

    mapping (address => LockedWallet) addressFrozenFund;  

    function mintToken(address _owner, uint256 amount) internal;
    function burnToken(address _owner, uint256 amount) internal;

    event LockBalance(address indexed addressOwner, uint256 releasetime, uint256 amount);
    event LockSubBalance(address indexed addressOwner, uint256 index, uint256 releasetime, uint256 amount);
    event UnlockBalance(address indexed addressOwner, uint256 releasetime, uint256 amount);
    event UnlockSubBalance(address indexed addressOwner, uint256 index, uint256 releasetime, uint256 amount);

    function lockedSupply() public view returns (uint256) {
        return _lockedSupply;
    }

    function releaseTimeOf(address _owner) public view returns (uint256 releaseTime) {
        return addressFrozenFund[_owner].release;
    }

    function lockedBalanceOf(address _owner) public view returns (uint256 lockedBalance) {
        return addressFrozenFund[_owner].amount;
    }

    function lockBalance(uint256 duration, uint256 amount) public{

        address _owner = msg.sender;

        require(address(0) != _owner && amount > 0 && duration > 0 && balanceOf(_owner) >= amount);
        require(addressFrozenFund[_owner].release <= now && addressFrozenFund[_owner].amount == 0);

        addressFrozenFund[_owner].start = now;
        addressFrozenFund[_owner].duration = duration;
        addressFrozenFund[_owner].release = addressFrozenFund[_owner].start + duration;
        addressFrozenFund[_owner].amount = amount;
        burnToken(_owner, amount);
        _lockedSupply = SafeMath.add(_lockedSupply, lockedBalanceOf(_owner));

        emit LockBalance(_owner, addressFrozenFund[_owner].release, amount);
    }

     
    function releaseLockedBalance() public {

        address _owner = msg.sender;

        require(address(0) != _owner && lockedBalanceOf(_owner) > 0 && releaseTimeOf(_owner) <= now);
        mintToken(_owner, lockedBalanceOf(_owner));
        _lockedSupply = SafeMath.sub(_lockedSupply, lockedBalanceOf(_owner));

        emit UnlockBalance(_owner, addressFrozenFund[_owner].release, lockedBalanceOf(_owner));

        delete addressFrozenFund[_owner];
    }

}

contract INTToken is ERC223, ERCAddressFrozenFund {

    using SafeMath for uint;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    address public fundsWallet;
    uint256 internal fundsWalletChanged;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;


    constructor() public {
        _symbol = 'INT';
        _name = 'inChat Token';
        _decimals = 8;
        _totalSupply = 10000000000000000;
        balances[msg.sender] = _totalSupply;
        fundsWallet = msg.sender;

        owner = msg.sender;

        fundsWalletChanged = 0;
    }

    function changeFundsWallet(address newOwner) public{
        require(msg.sender == fundsWallet && fundsWalletChanged == 0);

        balances[newOwner] = balances[fundsWallet];
        balances[fundsWallet] = 0;
        fundsWallet = newOwner;
        fundsWalletChanged = 1;
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mintToken(address _owner, uint256 amount) internal {
        balances[_owner] = SafeMath.add(balances[_owner], amount);
    }

    function burnToken(address _owner, uint256 amount) internal {
        balances[_owner] = SafeMath.sub(balances[_owner], amount);
    }

    function() payable public {

        require(msg.sender == address(0)); 
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            bytes memory _data = new bytes(1);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        if(_from == fundsWallet){
            require(_value <= balances[_from]);
        }

        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            bytes memory _data = new bytes(1);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);

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
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function transferdata(address _to, uint _value, bytes _data) public payable {
        require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transferdata(msg.sender, _to, _value, _data);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
         
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    function transferMultiple(address[] _tos, uint256[] _values, uint count)  payable public returns (bool) {
        uint256 total = 0;
        uint256 total_prev = 0;
        uint i = 0;

        for(i=0;i<count;i++){
            require(_tos[i] != address(0) && !isContract(_tos[i])); 

            if(isContract(_tos[i])) {
                ERC223ReceivingContract receiver = ERC223ReceivingContract(_tos[i]);
                bytes memory _data = new bytes(1);
                receiver.tokenFallback(msg.sender, _values[i], _data);
            }

            total_prev = total;
            total = SafeMath.add(total, _values[i]);
            require(total >= total_prev);
        }

        require(total <= balances[msg.sender]);

        for(i=0;i<count;i++){
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _values[i]);
            balances[_tos[i]] = SafeMath.add(balances[_tos[i]], _values[i]);
            emit Transfer(msg.sender, _tos[i], _values[i]);
        }

        return true;
    }
}