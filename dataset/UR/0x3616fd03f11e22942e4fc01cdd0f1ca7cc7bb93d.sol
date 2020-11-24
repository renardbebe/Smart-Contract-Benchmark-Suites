 

pragma solidity >=0.4.22 <0.6.0;

 
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

contract DappToken {
    string  public name = "Block Chain Little Sister";
    string  public symbol = "BCLS";
    uint256 public totalSupply = 100000000000 * (10 ** 18);
    uint256 public decimals = 18;
    
    address public owner = 0xb2b9b6D9b0ae23C797faEa8694c8639e7BA785EB;
    address payable public beneficiary = 0xE2d19B66c02D64E8adF4D1cA8ff45679e30e4f71;
    
    uint256 public rate = 1000000;
    uint256 public zero = 2000 * (10 ** 18);
    
    using SafeMath for uint256;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public registered;
    
    constructor() public {
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function() payable external {
        uint256 out = 0;
        if(!registered[msg.sender]) {
            out = out.add(zero);
            registered[msg.sender] = true;
        }
        
        if (msg.value > 0) {
            out = out.add(msg.value.mul(rate));
        }
        
        balanceOf[owner] = balanceOf[owner].sub(out);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(out);
        
        emit Transfer(owner, msg.sender, out);
        
        if (msg.value > 0) {
            beneficiary.transfer(msg.value);
        }
    }
}