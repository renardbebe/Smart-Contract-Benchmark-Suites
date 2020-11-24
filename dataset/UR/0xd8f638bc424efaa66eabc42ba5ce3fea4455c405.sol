 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        assert(c >= b);
        return c;
    }
}

 
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardERC20Token is ERC20Interface {

    using SafeMath for uint256;

     
    string public name;

     
    string public symbol;

     
    uint8 public decimals;

     
    uint256 internal supply;

     
    mapping(address => uint256) internal balances;

     
    mapping (address => mapping (address => uint256)) internal allowed;

     
    modifier onlyPayloadSize(uint256 size) {
        if(msg.data.length < size.add(4)) {
            revert();
        }
        _;
    }

     
    function () public payable {
        revert();
    }

     
    constructor(address _issuer, string _name, string _symbol, uint8 _decimals, uint256 _amount) public {
        require(_issuer != address(0));
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        require(_decimals <= 18);
        require(_amount > 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        supply = _amount.mul(10 ** uint256(decimals));
        balances[_issuer] = supply;
    }

     
    function totalSupply() public view returns (uint256) {
        return supply;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(64) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(96) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(64) public returns (bool) {
        require(_value > 0);
        require(allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) onlyPayloadSize(64) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _value) onlyPayloadSize(64) public returns (bool) {
        require(_value > 0);

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _value) onlyPayloadSize(64) public returns (bool) {
        require(_value > 0);

        uint256 value = allowed[msg.sender][_spender];

        if (_value >= value) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = value.sub(_value);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
contract LongHashERC20Token is StandardERC20Token {

     
    address public issuer;

     
    event Issuance(address indexed _from, uint256 _amount, uint256 _value);
    event Burn(address indexed _from, uint256 _amount, uint256 _value);

     
    modifier onlyIssuer() {
        if (msg.sender != issuer) {
            revert();
        }
        _;
    }

     
    constructor(address _issuer, string _name, string _symbol, uint8 _decimals, uint256 _amount) 
        StandardERC20Token(_issuer, _name, _symbol, _decimals, _amount) public {
        issuer = _issuer;
    }

     
    function issue(uint256 _amount) onlyIssuer() public returns (bool) {
        require(_amount > 0);
        uint256 value = _amount.mul(10 ** uint256(decimals));

        supply = supply.add(value);
        balances[issuer] = balances[issuer].add(value);

        emit Issuance(msg.sender, _amount, value);
        return true;
    }

     
    function burn(uint256 _amount) onlyIssuer() public returns (bool) {
        uint256 value;

        require(_amount > 0);
        value = _amount.mul(10 ** uint256(decimals));
        require(supply >= value);
        require(balances[issuer] >= value);

        supply = supply.sub(value);
        balances[issuer] = balances[issuer].sub(value);

        emit Burn(msg.sender, _amount, value);
        return true;
    }

     
    function changeIssuer(address _to, bool _transfer) onlyIssuer() public returns (bool) {
        require(_to != address(0));

        if (_transfer) {
            balances[_to] = balances[issuer];
            balances[issuer] = 0;
        }
        issuer = _to;

        return true;
    }
}