 

pragma solidity ^0.4.23;

 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);    

    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract DatEatToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) public freezedAccounts;

    uint256 totalSupply_;
    string public constant name = "DatEatToken";  
    string public constant symbol = "DTE";  
    uint8 public constant decimals = 18;  

    uint256 constant icoSupply = 200000000 * (10 ** uint256(decimals));
    uint256 constant founderSupply = 60000000 * (10 ** uint256(decimals));
    uint256 constant defoundSupply = 50000000 * (10 ** uint256(decimals));
    uint256 constant year1Supply = 75000000 * (10 ** uint256(decimals));
    uint256 constant year2Supply = 75000000 * (10 ** uint256(decimals));
    uint256 constant bountyAndBonusSupply = 40000000 * (10 ** uint256(decimals));

    uint256 constant founderFrozenUntil = 1559347200;  
    uint256 constant defoundFrozenUntil = 1546300800;  
    uint256 constant year1FrozenUntil = 1559347200;  
    uint256 constant year2FrozenUntil = 1590969600;  

    event Burn(address indexed burner, uint256 value);

    constructor(
        address _icoAddress, 
        address _founderAddress,
        address _defoundAddress, 
        address _year1Address, 
        address _year2Address, 
        address _bountyAndBonusAddress
    ) public {
        totalSupply_ = 500000000 * (10 ** uint256(decimals));
        balances[_icoAddress] = icoSupply;
        balances[_bountyAndBonusAddress] = bountyAndBonusSupply;
        emit Transfer(address(0), _icoAddress, icoSupply);
        emit Transfer(address(0), _bountyAndBonusAddress, bountyAndBonusSupply);

        _setFreezedBalance(_founderAddress, founderSupply, founderFrozenUntil);
        _setFreezedBalance(_defoundAddress, defoundSupply, defoundFrozenUntil);
        _setFreezedBalance(_year1Address, year1Supply, year1FrozenUntil);
        _setFreezedBalance(_year2Address, year2Supply, year2FrozenUntil);
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
         
        require(freezedAccounts[msg.sender] == 0 || freezedAccounts[msg.sender] < block.timestamp);
         
        require(freezedAccounts[_to] == 0 || freezedAccounts[_to] < block.timestamp);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function batchTransfer(address[] _tos, uint256[] _values) public returns (bool) {
        require(_tos.length == _values.length);
        uint256 arrayLength = _tos.length;
        for(uint256 i = 0; i < arrayLength; i++) {
            transfer(_tos[i], _values[i]);
        }
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
         
        require(freezedAccounts[_from] == 0 || freezedAccounts[_from] < block.timestamp);
         
        require(freezedAccounts[_to] == 0 || freezedAccounts[_to] < block.timestamp);

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

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function _setFreezedBalance(address _owner, uint256 _amount, uint _lockedUntil) internal {
        require(_owner != address(0));
        require(balances[_owner] == 0);
        freezedAccounts[_owner] = _lockedUntil;
        balances[_owner] = _amount;     
    }

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function () external payable {
        revert();
    }
}