 

pragma solidity ^0.4.25;


 
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

contract THB {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address owner;
    address[] admin_addrs;
    uint256[] admin_as;
    uint256 admin_needa;
    mapping(address => mapping(uint256 => uint256)) admin_tran_as;
    mapping(address => mapping(uint256 => address[])) admin_tran_addrs;

    mapping(address => uint256)  balances;
    mapping(address => mapping(address => uint256)) _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event PreTransfer(address _admin, uint256 _lastas, address indexed _to, uint256 _value);

    constructor (uint256 _initialSupply, string _name, string _symbol,
        address[] _admin_addrs, uint256[] _admin_as, uint256 _admin_needa) public {
        balances[msg.sender] = _initialSupply;
        owner = msg.sender;
        totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = 18;
        require(_admin_addrs.length > 0 && _admin_addrs.length == _admin_as.length);
        require(_admin_needa >= 1);
        for (uint i = 0; i < _admin_addrs.length; i++) {
            require(_admin_addrs[i] != address(0));
        }
        for (i = 0; i < _admin_as.length; i++) {
            require(_admin_as[i] >= 1);
        }
        admin_addrs = _admin_addrs;
        admin_as = _admin_as;
        admin_needa = _admin_needa;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(msg.sender != owner);
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transfer_admin(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_to != owner);
        require(_value > 0);

        uint256 _msgsendas = 0;
        for (uint i = 0; i < admin_addrs.length; i++) {
            if (admin_addrs[i] == msg.sender) {
                _msgsendas = admin_as[i];
                break;
            }
        }
        require(_msgsendas > 0);

        for (i = 0; i < admin_tran_addrs[_to][_value].length; i++) {
            require(admin_tran_addrs[_to][_value][i] != msg.sender);
        }

        uint256 _curr_as = admin_tran_as[_to][_value];

        if (_curr_as < admin_needa) {
            _curr_as = _curr_as.add(_msgsendas);
            if (_curr_as < admin_needa) {
                admin_tran_as[_to][_value] = _curr_as;
                admin_tran_addrs[_to][_value].push(msg.sender);
                emit PreTransfer(msg.sender, _curr_as, _to, _value);
                return true;
            }
            return transfer_admin_f(_to, _value);
        }
         
        require(false);
    }

    function transfer_admin_f(address _to, uint256 _value) internal returns (bool success) {
        require(balances[owner] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        admin_tran_as[_to][_value] = 0;
        admin_tran_addrs[_to][_value] = new address[](0);
        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(owner, _to, _value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_from != owner);
        require(_value > 0);
        uint256 _allow = _allowed[_from][msg.sender];
        require(_value <= _allow);
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        _allowed[_from][msg.sender] = _allow.sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(msg.sender != owner);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner);
        owner.transfer(amount);
    }

    function() public payable {
    }
}