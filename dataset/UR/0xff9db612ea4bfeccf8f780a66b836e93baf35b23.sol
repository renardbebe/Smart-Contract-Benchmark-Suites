 

pragma solidity 0.5.7;

contract InternetCoin {
    using SafeMath for uint256;

    string constant public name = "Internet Coin" ;                               
    string constant public symbol = "ITN";           
    uint8 constant public decimals = 18;            

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public constant totalSupply = 200*10**24;  

    address public owner  = address(0x000000000000000000000000000000000000dEaD);

    modifier validAddress {
        assert(address(0x000000000000000000000000000000000000dEaD) != msg.sender);
        assert(address(0x0) != msg.sender);
        assert(address(this) != msg.sender);
        _;
    }

    constructor (address _addressFounder) validAddress public {
        require(owner == address(0x000000000000000000000000000000000000dEaD), "Owner cannot be re-assigned");
        owner = _addressFounder;
        balanceOf[_addressFounder] = totalSupply;
        emit Transfer(0x000000000000000000000000000000000000dEaD, _addressFounder, totalSupply);
    }

    function transfer(address _to, uint256 _value) validAddress public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) validAddress public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value)>= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) validAddress public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
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

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}