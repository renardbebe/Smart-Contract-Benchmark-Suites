 

pragma solidity ^0.4.25;

 
 
 
 
 

 
library SafeMath {

   
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
        if (_a == 0) {
            return 0;
    }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

   
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
        return _a / _b;
    }

   
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

   
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

 
contract ERC20Basic {
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;


   
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender],"Not enough tokens left");
        require(_to != address(0),"Address is empty");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

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

   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
    } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Token is StandardToken {

    uint256 public decimals = 8;
    uint256 public totalSupply = 100e14;
    string public name = "List101 Token";
    string public symbol = "LST";
    address public ico;
    address public owner;

    modifier onlyICO {
        require(msg.sender == ico);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function setUpICOAddress(address _ico) public onlyOwner {
        require(_ico != address(0),"Address is empty");
        ico = _ico;
    }
    
    function distributeICOTokens(address _buyer, uint256 _tokensToBuy) public onlyICO {  
        require(_buyer != address(0),"Address is empty");
        require(_tokensToBuy > 0,"You need to buy at least 1 token");
        balances[owner] = balances[owner].sub(_tokensToBuy);
        balances[_buyer] = balances[_buyer].add(_tokensToBuy); 
    }

     
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0),"Address is empty");
        owner = newOwner;
    }
}