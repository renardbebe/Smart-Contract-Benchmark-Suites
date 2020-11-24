 

pragma solidity ^0.5.0;

 
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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Interface {
     function totalSupply() public view returns (uint256);
     function balanceOf(address tokenOwner) public view returns (uint256 balance);
     function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
     function transfer(address to, uint256 tokens) public returns (bool success);
     function approve(address spender, uint256 tokens) public returns (bool success);
     function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

     event Transfer(address indexed from, address indexed to, uint256 tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract WeedConnect is ERC20Interface, Ownable{
     using SafeMath for uint256;

     uint256 private _totalSupply;
     mapping(address => uint256) private _balances;
     mapping(address => mapping (address => uint256)) private _allowed;

     string public constant symbol = "420";
     string public constant name = "WeedConnect";
     uint public constant decimals = 18;
     
     constructor () public {
          _totalSupply = 420000000 * (10 ** decimals);
          _balances[msg.sender] = _totalSupply;
          
          emit Transfer(address(0), msg.sender, _totalSupply);
     }

      
     function totalSupply() public view returns (uint256) {
          return _totalSupply;
     }

      
     function balanceOf(address owner) public view returns (uint256) {
          return _balances[owner];
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

      
     function allowance(address owner, address spender) public view returns (uint256) {
          return _allowed[owner][spender];
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
          require(to != address(0));

          _balances[from] = _balances[from].sub(value);
          _balances[to] = _balances[to].add(value);
          emit Transfer(from, to, value);
     }

      
     function _approve(address owner, address spender, uint256 value) internal {
          require(spender != address(0));
          require(owner != address(0));

          _allowed[owner][spender] = value;
          emit Approval(owner, spender, value);
     }

     function () external payable {
          revert();
     }
}