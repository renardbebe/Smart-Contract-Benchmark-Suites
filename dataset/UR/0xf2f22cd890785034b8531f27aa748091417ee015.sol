 

pragma solidity 0.5.8;

 
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

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool); 

    function approve(address spender, uint256 value) external returns (bool); 

    function transferFrom(address from, address to, uint256 value) external returns (bool); 

    function totalSupply() external view returns (uint256); 

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256); 

    event Transfer(address indexed from, address indexed to, uint256 value); 

    event Approval(address indexed owner, address indexed spender, uint256 value); 
}

 
contract Ownable {
    address internal _owner; 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); 

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "The caller must be owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner); 
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Cannot transfer control of the contract to the zero address");
        emit OwnershipTransferred(_owner, newOwner); 
        _owner = newOwner; 
    }
}

 
contract StandardToken is IERC20 {
    using SafeMath for uint256; 
    
    mapping (address => uint256) internal _balances; 
    mapping (address => mapping (address => uint256)) internal _allowed; 
    
    uint256 internal _totalSupply; 
    
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply; 
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value); 
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value); 
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value)); 
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue)); 
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Cannot transfer to the zero address"); 
        _balances[from] = _balances[from].sub(value); 
        _balances[to] = _balances[to].add(value); 
        emit Transfer(from, to, value); 
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0), "Cannot approve to the zero address"); 
        require(owner != address(0), "Setter cannot be the zero address"); 
	    _allowed[owner][spender] = value;
        emit Approval(owner, spender, value); 
    }

}

 
contract Pausable is Ownable {
    event Pause(); 
    event Unpause(); 
    
    bool public paused = false; 
    


     
    modifier whenNotPaused() {
        require(!paused, "Only when the contract is not paused"); 
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Only when the contract is paused"); 
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true; 
        emit Pause(); 
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false; 
        emit Unpause(); 
    }
}

 
contract PausableToken is StandardToken, Pausable {
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value); 
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value); 
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value); 
    }
    
    function increaseAllowance(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(_spender, _addedValue); 
    }
    
    function decreaseAllowance(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(_spender, _subtractedValue); 
    }
}

 
contract BurnableToken is StandardToken {

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

     
    function burnFrom(address _from, uint256 _value) public {
        _approve(_from, msg.sender, _allowed[_from][msg.sender].sub(_value));
        _burn(_from, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= _balances[_who], "Not enough token balance");
         
         
        _balances[_who] = _balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Transfer(_who, address(0), _value);
    }
}

contract VFDToken is BurnableToken, PausableToken {
    string public constant name = "Micro Payment Shield";  
    string public constant symbol = "VFD";  
    uint8 public constant decimals = 18;
    uint256 internal constant INIT_TOTALSUPPLY = 65000000; 
    
     
    constructor() public {
        _owner = 0x2CcaFDD16aA603Bbc8026711dd2E838616c010c3;
        emit OwnershipTransferred(address(0), _owner);
        _totalSupply = INIT_TOTALSUPPLY * 10 ** uint256(decimals);
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }
}