 

pragma solidity ^0.4.25;

 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function transfer(address to, uint256 tokenAmount) external returns (bool);
    function approve(address spender, uint256 tokenAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenAmount) external returns (bool);
    function burn(uint256 tokenAmount) external returns (bool success);
    function burnFrom(address from, uint256 tokenAmount) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokenAmount);
    event Approval(address indexed tokenHolder, address indexed spender, uint256 tokenAmount);
    event Burn(address indexed from, uint256 tokenAmount);
}

interface tokenRecipient {
    function receiveApproval(address from, uint256 tokenAmount, address token, bytes extraData) external;
}


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}



 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, "Multiplication overflow");

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, "Division by 0");  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Subtraction overflow");
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "Addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Dividing by 0");
        return a % b;
    }
}







contract BrewerscoinToken is owned, IERC20 {

    using SafeMath for uint256;

    uint256 private constant base = 1e18;
    uint256 constant MAX_UINT = 2**256 - 1;

     
    string public constant name = "Brewer's coin";
    string public constant symbol = "BREW";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1e26;               

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 tokenAmount);
    event Approval(address indexed tokenHolder, address indexed spender, uint256 tokenAmount);
    event Burn(address indexed from, uint256 tokenAmount);

     
    string private constant NOT_ENOUGH_TOKENS = "Not enough tokens";
    string private constant NOT_ENOUGH_ETHER = "Not enough ether";
    string private constant NOT_ENOUGH_ALLOWANCE = "Not enough allowance";
    string private constant ADDRESS_0_NOT_ALLOWED = "Address 0 not allowed";

     
    constructor() public {

         
        balances[msg.sender] = totalSupply;

         
        allowance[this][msg.sender] = MAX_UINT;
    }

     
    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

     
    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowance[tokenOwner][spender];
    }

     
    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }

     
    function transfer(address to, uint256 tokenAmount) external returns (bool) {
        _transfer(msg.sender, to, tokenAmount);

        return true;
    }

     
    function transferFrom(address from, address to, uint256 tokenAmount) external returns (bool) {

         
        require(tokenAmount <= allowance[from][msg.sender], NOT_ENOUGH_ALLOWANCE);

         
        _transfer(from, to, tokenAmount);

         
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(tokenAmount);

        return true;
    }

     
    function _transfer(address from, address to, uint256 tokenAmount) internal {

         
        require(tokenAmount <= balances[from], NOT_ENOUGH_TOKENS);

         
        require(to != address(0), ADDRESS_0_NOT_ALLOWED);

         
        balances[from] = balances[from].sub(tokenAmount);

         
        balances[to] = balances[to].add(tokenAmount);

         
        emit Transfer(from, to, tokenAmount);
    }

     
    function approve(address spender, uint256 tokenAmount) external returns (bool success) {
        return _approve(spender, tokenAmount);
    }

     
    function approveAndCall(address spender, uint256 tokenAmount, bytes extraData) external returns (bool success) {
        tokenRecipient _spender = tokenRecipient(spender);
        if (_approve(spender, tokenAmount)) {
            _spender.receiveApproval(msg.sender, tokenAmount, this, extraData);
            return true;
        }
        return false;
    }

     
    function _approve(address spender, uint256 tokenAmount) internal returns (bool success) {
        allowance[msg.sender][spender] = tokenAmount;
        emit Approval(msg.sender, spender, tokenAmount);
        return true;
    }

     
    function burn(uint256 tokenAmount) external returns (bool success) {

        _burn(msg.sender, tokenAmount);

        return true;
    }

     
    function burnFrom(address from, uint256 tokenAmount) public returns (bool success) {

         
        require(tokenAmount <= allowance[from][msg.sender], NOT_ENOUGH_ALLOWANCE);

         
        _burn(from, tokenAmount);

         
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(tokenAmount);

        return true;
    }

     
    function _burn(address from, uint256 tokenAmount) internal {

         
        require(tokenAmount <= balances[from], NOT_ENOUGH_TOKENS);

         
        balances[from] = balances[from].sub(tokenAmount);

         
        totalSupply = totalSupply.sub(tokenAmount);

         
        emit Burn(from, tokenAmount);
    }
}