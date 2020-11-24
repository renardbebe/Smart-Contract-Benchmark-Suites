 

pragma solidity ^0.5.1;

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

contract VTRUSTToken is IERC20, Owned {
    using SafeMath for uint256;
    
     
    constructor() public {
        owner = 0xdA7F9Fd3ca8C292600647807a8298C3c0cb7c74F;
        contractAddress = address(this);
        _balances[owner] = 49500000000 * 10 ** decimals;
        _balances[contractAddress] = 500000000 * 10 ** decimals;
        emit Transfer(address(0), owner, 4950000000 * 10 ** decimals);
        emit Transfer(address(0), contractAddress, 50000000 * 10 ** decimals);
    }
    
     
    event Error(string err);
    event Mint(uint mintAmount, address to);
    event Burn(uint burnAmount, address from);
    
     
    string public constant name = "Vessel Investment Trust";
    string public constant symbol = "VTRUST";
    uint256 public constant decimals = 5;
    uint256 public supply = 50000000000 * 10 ** decimals;
    
    address private contractAddress;
    uint256 public ICOPrice;
    
     
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
        require(to != contractAddress);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     
    function approve(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     
    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from));
        require(value <= allowance(from, to));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][to] = _allowed[from][to].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
     
    function () external payable {
        revert();
    }
    
     
    function mint(uint256 amount, address to) public onlyOwner {
        _balances[to] = _balances[to].add(amount);
        supply = supply.add(amount);
        emit Mint(amount, to);
    }
    
     
    function burn(uint256 amount, address from) public onlyOwner {
        require(_balances[from] >= amount);
        _balances[from] = _balances[from].sub(amount);
        supply = supply.sub(amount);
        emit Burn(amount, from);
    }
    
     
    function setICOPrice(uint256 _newPrice) public onlyOwner {
        ICOPrice = _newPrice;
    }
    
     
    function getRemainingICOBalance() public view returns (uint256) {
        return _balances[contractAddress];
    }
    
     
    function topUpICO(uint256 _amount) public onlyOwner {
        require(_balances[owner] >= _amount);
        _balances[owner] = _balances[owner].sub(_amount);
        _balances[contractAddress] = _balances[contractAddress].add(_amount);
        emit Transfer(msg.sender, contractAddress, _amount);
    }
    
    
     
    function buyTokens() public payable {
        require(ICOPrice > 0);
        require(msg.value >= ICOPrice);
        uint256 affordAmount = msg.value / ICOPrice;
        require(_balances[contractAddress] >= affordAmount * 10 ** decimals);
        _balances[contractAddress] = _balances[contractAddress].sub(affordAmount * 10 ** decimals);
        _balances[msg.sender] = _balances[msg.sender].add(affordAmount * 10 ** decimals);
        emit Transfer(contractAddress, msg.sender, affordAmount * 10 ** decimals);
    }
    
     
    function withdrawContractBalance() public onlyOwner {
        msg.sender.transfer(contractAddress.balance);
    }
    
     
    function withdrawContractTokens(uint256 _amount) public onlyOwner {
        require(_balances[contractAddress] >= _amount);
        _balances[contractAddress] = _balances[contractAddress].sub(_amount);
        _balances[owner] = _balances[owner].add(_amount);
        emit Transfer(contractAddress, owner, _amount);
    }
}