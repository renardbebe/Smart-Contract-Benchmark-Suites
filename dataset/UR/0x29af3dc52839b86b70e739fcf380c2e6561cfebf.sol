 

pragma solidity >=0.5.10;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
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

contract ShittyDice is Owned {
    using SafeMath for uint;

    event playerRoll(address player, uint256 amount, uint256 outcome);
    event playerWithdrawal(address player, uint256 amount);
    event playerDeposit(address player, uint256 amount);

    struct sidestruct {
        bool win;
        uint256 m;
        uint256 d;
    }

    uint256 sides;

    mapping(uint256 => sidestruct) sideoutcome;
    mapping(address => uint256) balance;

    uint256 seed;

    IERC20 SHIT = IERC20(0xaa7FB1c8cE6F18d4fD4Aabb61A2193d4D441c54F);

     
    function Roll(uint256 amount) public {
        require(amount <= balance[msg.sender]);
        require(balance[address(this)] >= amount * 5);
        uint256 _rnum = Random() % sides + 1;

        if (sideoutcome[_rnum].win == true) {
            balance[msg.sender] = balance[msg.sender].add(amount * sideoutcome[_rnum].m / sideoutcome[_rnum].d);
            balance[address(this)] = balance[address(this)].sub(amount * sideoutcome[_rnum].m / sideoutcome[_rnum].d);
        }
        else {
            balance[msg.sender] = balance[msg.sender].sub(amount * sideoutcome[_rnum].m / sideoutcome[_rnum].d);
            balance[address(this)] = balance[address(this)].add(amount * sideoutcome[_rnum].m / sideoutcome[_rnum].d);
        }
        emit playerRoll(msg.sender, amount, _rnum);
    }

    function deposit(uint256 amount) public {
        SHIT.transferFrom(msg.sender, address(this), amount);
        balance[msg.sender] = balance[msg.sender].add(amount);
        emit playerDeposit(msg.sender, amount);
    }

    function withdrawal(uint256 amount) public {
        require(balance[msg.sender] >= amount);
        balance[msg.sender] = balance[msg.sender].sub(amount);
        SHIT.transfer(msg.sender, amount);
        emit playerWithdrawal(msg.sender, amount);
    }
     
    function viewbal(address _addr) public view returns(uint256){
        return(balance[_addr]);
    }
     
    function Random() internal returns(uint256) {
        uint256 _seed = uint256(keccak256(abi.encodePacked(seed, msg.sender, block.timestamp, block.difficulty)));
        seed = _seed;
        return(_seed);
    }
     
    function setsides(uint256 _sides) public onlyOwner() {
        sides = _sides;
    }
    function setsideoutcome(uint256 _side, bool _win, uint256 _m, uint256 _d) public onlyOwner() {
        sideoutcome[_side].win = _win;
        sideoutcome[_side].m = _m;
        sideoutcome[_side].d = _d;
    }
    function admindeposit(IERC20 token, uint256 amount) public onlyOwner() {
        token.transferFrom(msg.sender, address(this), amount);
        if (token == SHIT) {
            balance[address(this)] = balance[address(this)].add(amount);
        }
    }
    function adminwithdrawal(IERC20 token, uint256 amount) public onlyOwner() {
        if (token == SHIT) {
            require(balance[address(this)] >= amount);
            balance[address(this)] = balance[address(this)].sub(amount);
        }
        token.transfer(msg.sender, amount);
    }
    function clearETH() public onlyOwner() {
      address payable _owner = msg.sender;
      _owner.transfer(address(this).balance);
    }
}