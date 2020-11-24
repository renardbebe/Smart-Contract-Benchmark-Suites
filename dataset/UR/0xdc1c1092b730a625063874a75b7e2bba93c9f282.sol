 

 

 
pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
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

 

 
pragma solidity ^0.5.0;


 
contract Pausable is Ownable {

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    event Paused(address account);
    event Unpaused(address account);
}

 

 
pragma solidity ^0.5.0;

 
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

 

 
pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
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

     
    function allowance(
        address owner,
        address spender
    )
      public
      view
      returns (uint256)
    {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
      public
      returns (bool)
    {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
      public
      returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
      public
      returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
  
}

 

 
pragma solidity ^0.5.0;


 
contract ERC20Mintable is ERC20 {
    
     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
        emit Mint(account, msg.sender, value);
    }

    event Mint(address indexed to, address indexed minter, uint256 value);
}

 

 
pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(value <= _balances[account]);

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
        emit Burn(account, msg.sender, value);
    }

    event Burn(address indexed from, address indexed burner, uint256 value);
}

 

 
pragma solidity ^0.5.0;


contract TokenDetails {

    string internal _name;
    string internal _symbol;
    
     
    function name() public view returns(string memory) {
        return _name;
    }

     
    function symbol() public view returns(string memory) {
        return _symbol;
    }

}

 

 
pragma solidity ^0.5.0;


contract ERC20Details is TokenDetails {

    uint8 internal _decimals;

     
    function decimals() public view returns(uint8) {
        return _decimals;
    }

}

 

 
pragma solidity ^0.5.0;






contract XmedBaseLoyaltyToken is Pausable, ERC20Mintable, ERC20Burnable, ERC20Details {

     
    constructor(
        string memory _tokenSymbol,
        string memory _tokenName,
        uint8 _tokenDecimals
        ) public {
        _symbol = _tokenSymbol;
        _name = _tokenName;
        _decimals = _tokenDecimals;
    }

     
     
     
    function onTotalSupplyChange() internal {
        emit TotalSupplyChanged();
    }

    function award(address to, uint256 loyaltyAmount) public onlyOwner {
        _mint(to, loyaltyAmount);
        emit Award(to, _symbol, loyaltyAmount);
        onTotalSupplyChange();
    }

    function redeem(address from, uint256 loyaltyAmount) public onlyOwner {
        _burn(from, loyaltyAmount);
        emit Redeem(from, _symbol, loyaltyAmount);
        onTotalSupplyChange();
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
        emit Burn(_symbol, amount);
        onTotalSupplyChange();
    }

     
    event Award(address to, string tokenSymbol, uint256 tokenAmount);
     
    event Redeem(address from, string tokenSymbol, uint256 tokenAmount);
     
    event Burn(string tokenSymbol, uint256 tokenAmount);
     
    event TotalSupplyChanged();
}

 

 
pragma solidity ^0.5.0;


contract XmedLoyaltyToken is XmedBaseLoyaltyToken {

     
    constructor(
        string memory _tokenSymbol,
        string memory _tokenName,
        uint8 _tokenDecimals
        ) XmedBaseLoyaltyToken(_tokenSymbol, _tokenName, _tokenDecimals) public {

        }

     
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
      public
      returns (bool)
    {
        if (msg.sender == owner()){
            _transfer(from, to, value);
            return true;
        }

        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
}