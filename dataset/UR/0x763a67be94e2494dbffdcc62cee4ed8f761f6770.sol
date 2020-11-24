 

pragma solidity ^0.4.24;

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
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

contract BTNY is ERC20, Ownable {
  string public constant name = "Bitenny";
  string public constant symbol = "BTNY";
  uint32 public constant decimals = 18;
  
  address public saleContract;
  bool public saleContractActivated;
  uint256 internal _startTime;
  uint256 internal _foundation = uint256(9e7).mul(1 ether);
  uint256 internal _bounty = uint256(1e7).mul(1 ether);
  uint256 internal _tokensForSale = uint256(7e8).mul(1 ether);
  uint256 internal _tokensForTeamAndAdvisors = uint256(2e8).mul(1 ether);

  mapping(address => uint256) public team;
  mapping(address => uint256) public teamReleased;
  mapping(address => uint256) public advisors;
  mapping(address => uint256) public advisorsReleased;

  event SaleContractActivation(address saleContract, uint256 _tokensForSale);
  event VestedToTeam(address who, uint256 amount);
  event VestedToAdvisors(address who, uint256 amount);

  constructor(address _newOwner) public {
    _transferOwnership(_newOwner);
    _startTime = now;
    uint256 tokens = _foundation.add(_bounty);
    _foundation = 0;
    _bounty = 0;
    _mint(_newOwner, tokens);
  }

  function _teamToRelease(address who) internal view returns(uint256) {
    uint256 teamStage = now.sub(_startTime).div(365 days);
    if (teamStage > 3) teamStage = 3;
    uint256 teamTokens = team[who].mul(teamStage).div(3).sub(teamReleased[who]);
    return teamTokens;
  }

  function _advisorsToRelease(address who) internal view returns(uint256) {
    uint256 advisorsStage = now.sub(_startTime).div(91 days);
    if (advisorsStage > 4) advisorsStage = 4;
    uint256 advisorsTokens = advisors[who].mul(advisorsStage).div(4).sub(advisorsReleased[who]);
    return advisorsTokens;
  }

  function toRelease(address who) public view returns(uint256) {
    uint256 teamTokens = _teamToRelease(who);
    uint256 advisorsTokens = _advisorsToRelease(who);
    return teamTokens.add(advisorsTokens);
  }

  function release() public {
    address who = msg.sender;
    uint256 teamTokens = _teamToRelease(who);
    uint256 advisorsTokens = _advisorsToRelease(who);
    uint256 tokens = teamTokens.add(advisorsTokens);
    require(tokens > 0);
    if (teamTokens > 0)
        teamReleased[who] = teamReleased[who].add(teamTokens);
    if (advisorsTokens > 0)
        advisorsReleased[who] = advisorsReleased[who].add(advisorsTokens);
    _mint(who, tokens);
  }

  function vestToTeam (address who, uint256 amount) public onlyOwner {
    require(who != address(0));
    _tokensForTeamAndAdvisors = _tokensForTeamAndAdvisors.sub(amount);
    team[who] = team[who].add(amount);
    emit VestedToTeam(who, amount);
  }

  function vestToAdvisors (address who, uint256 amount) public onlyOwner {
    require(who != address(0));
    _tokensForTeamAndAdvisors = _tokensForTeamAndAdvisors.sub(amount);
    advisors[who] = advisors[who].add(amount);
    emit VestedToAdvisors(who, amount);
  }

  function activateSaleContract(address saleContractAddress) public onlyOwner {
    require(saleContractAddress != address(0));
    require(!saleContractActivated);
    saleContract = saleContractAddress;
    saleContractActivated = true;
    _mint(saleContract, _tokensForSale);
    _tokensForSale = 0;
    emit SaleContractActivation(saleContract, _tokensForSale);
  }

  function burnTokensForSale(uint256 amount) public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    _burn(saleContract, amount);
    return true;
  }
}