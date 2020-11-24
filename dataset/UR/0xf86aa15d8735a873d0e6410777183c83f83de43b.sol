 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
   
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() public  {
        owner = msg.sender;
    }


   
    modifier onlyOwner() {
        require(msg.sender == owner,"owner Must Eq Msg.sender");
        _;
    }


   
    function transferOwnership(address newOwner) public onlyOwner  {
        require(newOwner != address(0),"newOwner Must Not Eq 0");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal  pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal  pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal  pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

   
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0),"toaddress Must No Eq 0");

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0),"toaddress Must Not Eq 0");

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused,"No Paused");
        _;
    }

     
    modifier whenPaused() {
        require(paused,"Paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused  {
        paused = true;
        emit Pause();
    }

  
     
    function unpause() public onlyOwner whenPaused  {
        paused = false;
        emit Unpause();
    }
}



 
contract TRToken is StandardToken, Pausable {

    string public constant name = "TR Coin";                     
    string public constant symbol = "TR";                                   
    uint8 public constant decimals = 18;                                      
    uint256 public constant INITIAL_SUPPLY =  10000000000 * 10**uint256(decimals);

     
    modifier rejectTokensToContract(address _to) {
        require(_to != address(this),"reject Token To Contract");
        _;
    }

     
    constructor() public {
        totalSupply = INITIAL_SUPPLY;                                
        balances[msg.sender] = INITIAL_SUPPLY;                       
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

     
    function transfer(address _to, uint256 _value) public rejectTokensToContract(_to) whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public rejectTokensToContract(_to)  whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
     
     
    address public destroyer;
    event Burn(uint256 amount);

    modifier onlyDestroyer() {
        require(msg.sender == destroyer,"The destroyer must be equal to the sender");
        _;
    }

    function setDestroyer(address _destroyer) public whenNotPaused onlyOwner  returns( bool success) {
        destroyer = _destroyer;
        return true;
    }

    function burn(uint256 _amount) public  whenNotPaused onlyDestroyer  returns (bool success) {
        require(balances[destroyer] >= _amount && _amount > 0,"balance is not enough and destroy value must greater than 0");
        balances[destroyer] = balances[destroyer].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        emit Burn(_amount);
        return true;
    }

}