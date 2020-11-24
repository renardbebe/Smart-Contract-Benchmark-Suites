 

pragma solidity 0.4.25;

contract Ownable {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
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

library ContractLib {
     
    function isContract(address _addr) internal view returns (bool) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

 
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

 
 
 
 
contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint);
    function allowance(address tokenOwner, address spender) public constant returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool);

    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


 

 
contract ERC223 is ERC20Interface {

    function transfer(address to, uint value, bytes data) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

}

contract LANDA is ERC223, Pausable {

    using SafeMath for uint256;
    using ContractLib for address;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Burn(address indexed from, uint256 value);

     
     
     
    constructor() public {
        symbol      = "LANDA";
        name        = "LANDA";
        decimals    = 18;
        totalSupply = 20000000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply;
         
    }

     
    function name() public constant returns (string) {
        return name;
    }

     
    function symbol() public constant returns (string) {
        return symbol;
    }

     
    function decimals() public constant returns (uint8) {
        return decimals;
    }

     
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

     
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
         
        if(_to.isContract()) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
     
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
         
         
         

        bytes memory empty;
        if(_to.isContract()) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to]        = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        balances[msg.sender]      = balanceOf(msg.sender).sub(_value);
        balances[_to]             = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }  

    function burn(uint256 _value) public whenNotPaused returns (bool) {
        require (_value > 0); 
        require (balanceOf(msg.sender) >= _value);                       
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);        
        totalSupply = totalSupply.sub(_value);                           
        emit Burn(msg.sender, _value);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public whenNotPaused returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function increaseApproval (address _spender, uint _addedValue) public whenNotPaused
        returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused
        returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[from]            = balances[from].sub(tokens);
        balances[to]              = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint) {
        return allowed[tokenOwner][spender];
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}