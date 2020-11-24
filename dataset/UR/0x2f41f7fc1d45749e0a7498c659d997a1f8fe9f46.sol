 

pragma solidity 0.5.6;

 
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

 
contract Ownable {
    address public owner; 
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); 

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 vaule);

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns(bool) {
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


contract DEJToken is StandardToken, Ownable {
    string public constant name = "DEHOME";  
    string public constant symbol = "DEJ";  
    uint8 public constant decimals = 18;  

    address public constant beneficiary = 0x505e83c8805DE632CA8d3d5d59701c1316136106;  
    uint256 public releasedTime;  
    uint256 public vestedAmount;  

    uint256 internal constant INIT_TOTALSUPPLY = 2000000000;  
     
    event ReleaseToken(address indexed beneficiary, uint256 vestedAmount);
    event TokenVesting(address indexed beneficiary, uint256 vestedAmount, uint256 releasedTime);
    
    constructor() public {
        owner = beneficiary;
        totalSupply = INIT_TOTALSUPPLY * 10 ** uint256(decimals);
        vestedAmount = 1000000000 * 10 ** uint256(decimals);
        uint256 ownerBalances = totalSupply.sub(vestedAmount);
        balances[owner] = ownerBalances;
        releasedTime = now.add(2*365 days);
        emit Transfer(address(0), owner, ownerBalances);
        emit TokenVesting(beneficiary, vestedAmount, releasedTime);
    }

     
    function releaseToken() public onlyOwner returns (bool) {
        require(now > releasedTime, "Not reaching release time");
        require(vestedAmount > 0, "Already released");
        balances[beneficiary] = balances[beneficiary].add(vestedAmount);
        emit ReleaseToken(beneficiary,vestedAmount);
        vestedAmount = 0;
        return true;
    }
}