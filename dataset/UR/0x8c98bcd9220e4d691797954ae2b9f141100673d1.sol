 

pragma solidity ^0.4.21;

 
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
         
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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



 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

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

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract Publyto is StandardToken, Ownable {

    using SafeMath for uint256;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event BurnFinished();
    event Retrieve(address indexed from, uint256 value);
    event RetrieveFinished();

    string public constant name = "Publyto";
    string public constant symbol = "PUB";
    uint8 public constant decimals = 18;
    uint256 public initialSupply = 1000000000;  
    uint256 public totalSupply =  initialSupply.mul(10 ** uint256(decimals));

    bool public burnFinished = false;
    bool public isLocked = true;
    bool public retrieveFinished = false;


    constructor() public {
        totalSupply_ = totalSupply;
        balances[msg.sender] = totalSupply;
    }


    modifier canBurn() {
        require(!burnFinished);
        _;
    }

     
    function unlock() external onlyOwner {
        isLocked = false;
    }

     
    function lock() external onlyOwner {
        isLocked = true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isLocked || msg.sender == owner);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isLocked || msg.sender == owner);
        return super.transfer(_to, _value);
    }


     
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        totalSupply = totalSupply_;

        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }


     
    function burn(uint256 _value) onlyOwner canBurn public {
        _burn(msg.sender, _value);
    }


    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        totalSupply = totalSupply_;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function finishBurning() onlyOwner public returns (bool) {
        burnFinished = true;
        emit BurnFinished();
        return true;
    }


     
    function retrieve(address _who, uint256 _value) onlyOwner public {
        require(!retrieveFinished);
        require(_who != address(0));
        require(_value <= balances[_who]);
        require(_value >= 0);

        balances[_who] = balances[_who].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);

        emit Retrieve(_who, _value);
        emit Transfer(_who, msg.sender, _value);
    }


     
    function finishRetrieving() onlyOwner public returns (bool) {
        retrieveFinished = true;
        emit RetrieveFinished();
        return true;
    }

}