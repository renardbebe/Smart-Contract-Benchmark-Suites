 

pragma solidity ^0.5.2;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

contract Owned {
    address public owner;
    address public newOwner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

contract Boxroi is IERC20, Owned {
    using SafeMath for uint256;
    
     
    constructor() public {
        owner = 0xaDdFB942659bDD72b389b50A8BEb3Dbb75C43780;
        _balances[owner] = 89000000 * 10 ** decimals;
        emit Transfer(address(0), owner, 89000000 * 10 ** decimals);
    }
    
     
    string public constant name = "Boxroi";
    string public constant symbol = "BXI";
    uint256 public constant decimals = 18;
    uint256 public supply = 89000000 * 10 ** decimals;
    uint256 private nonce;
    address public BXIT;
    
     
    mapping(address => uint256) _balances;
 
     
    mapping(address => mapping (address => uint256)) public _allowed;
 
     
    function totalSupply() public view returns (uint) {
        return supply;
    }
 
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }
 
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }
 
     
    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value);
        if (to == BXIT || to == address(this)) {
            _balances[msg.sender] = _balances[msg.sender].sub(value);
            supply = supply.sub(value);
            emit Transfer(msg.sender, address(0), value);
            burn(msg.sender, value);
            return true;
        } else {
            _balances[msg.sender] = _balances[msg.sender].sub(value);
            _balances[to] = _balances[to].add(value);
            emit Transfer(msg.sender, to, value);
            return true;
        }
    }
    
     
    function approve(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     
    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from));
        require(value <= allowance(from, to));
        if (to == BXIT || to == address(this)) {
            _balances[from] = _balances[from].sub(value);
            supply = supply.sub(value);
            emit Transfer(from, address(0), value);
            burn(from, value);
            return true;
        } else {
            _balances[from] = _balances[from].sub(value);
            _balances[to] = _balances[to].add(value);
            _allowed[from][to] = _allowed[from][to].sub(value);
            emit Transfer(from, to, value);
            return true;
        }
    }
    
     
    function () external payable {
        revert();
    }
    
     
    function mint(uint256 amount) public onlyOwner {
        require(amount <= (89000000 * 10 ** decimals) - supply);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        supply = supply.add(amount);
        emit Transfer(address(0), msg.sender, amount);
    }
    
     
     
    function burn(address burner, uint256 amount) internal {
        uint256 random = uint(keccak256(abi.encodePacked(block.difficulty,now,block.number, nonce))) % 999;
        nonce++;
        if (random > 983) {
            uint256 _amount = amount / 100;
            IERC20(BXIT).transfer(burner, _amount);
        }
    }
    
     
    function setBXITAddress(address _address) public onlyOwner {
        BXIT = _address;
    }
}