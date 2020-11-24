 

pragma solidity >=0.4.22 <0.6.0;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract Token {

    using SafeMath for uint256;

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);


    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0), "Transfer: to address is the zero address");
        require(_value <= balanceOf[msg.sender], "Transfer: transfer value is more than your balance");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_to != address(0), "TransferFrom: to address is the zero address");
        require(_value <= balanceOf[_from], "TransferFrom: transfer value is more than the balance of the from address");
        require(_value <= allowance[_from][msg.sender], "TransferFrom: transfer value is more than your allowance");

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval( address _spender, uint256 _addedValue) public returns (bool) {

        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval( address _spender, uint256 _subtractedValue ) public returns (bool) {

        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
        allowance[msg.sender][_spender] = 0;
        } else {
        allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
}


contract SpotChainToken is Token {

    uint256 internal constant INIT_TOTALSUPLLY = 600000000;

    constructor() public {
        name = "SpotChain Token";
        symbol = "GSB";
        decimals = uint8(18);
        totalSupply = INIT_TOTALSUPLLY * uint256(10) ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}