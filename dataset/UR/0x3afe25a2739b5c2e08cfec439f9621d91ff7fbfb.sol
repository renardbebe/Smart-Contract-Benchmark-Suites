 

pragma solidity ^0.5.10;

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
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }
  
}

contract ERC20Detailed is IERC20 {

  uint8 private _Tokendecimals;
  string private _Tokenname;
  string private _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
   _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
 
}

contract BLVD is ERC20Detailed {
     
     

    using SafeMath for uint256;

     
    address public oracle;
    
     
    address public maintainer;
    
     
    address public owner;

     
    uint256 public maxMintable;

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping (address => uint256)) private _allowed;
    
    string public constant tokenSymbol = "BLVD";
    string public constant tokenName = "BULVRD";
    uint8 public constant tokenDecimals = 18;
    uint256 public _totalSupply = 0;
    
     
    uint256 public limiter = 5;
    uint256 public referral = 35;
    uint256 public ar_drive = 15;
    uint256 public closure = 15;
    uint256 public map_drive = 10;
    uint256 public dash_drive = 10;
    uint256 public odb2_drive = 10;
    uint256 public police = 10;
    uint256 public hazard = 10;
    uint256 public accident = 10;
    uint256 public traffic = 5;
    uint256 public twitter_share = 5;
    uint256 public mastodon_share = 5;
    uint256 public base_report = 5;
    uint256 public validated_poi = 5;
    uint256 public speed_sign = 1;
    uint256 public report_init = 1;
 
     
    mapping(address => uint256) redeemedRewards;
    mapping(address => uint256) latestWithdrawBlock;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event RedeemRewards(address indexed addr, uint256 rewards);
    
    constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        owner = msg.sender;
        maintainer = msg.sender;
        oracle = msg.sender;
        maxMintable = 50000000000 * 10**uint256(tokenDecimals);
         
        redeemRewards(87500000000 * 10**uint256(tokenDecimals), owner);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        require(owner == msg.sender);
        return IERC20(tokenAddress).transfer(owner, tokens);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balanceOf[_owner];
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowed[_owner][spender];
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }
  
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
  
     function transfer(address to, uint tokens) public returns (bool success) {
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(tokens);
        _balanceOf[to] = _balanceOf[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        _balanceOf[from] = _balanceOf[from].sub(tokens);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);
        _balanceOf[to] = _balanceOf[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
     
    function transferOwnership(address newOwner) public {
        require(owner == msg.sender);
        require(newOwner != address(0));
        owner = newOwner;
    }
    
     
     
    function changeOracle(address newOracle) public {
        require(owner == msg.sender);
        require(oracle != address(0) && newOracle != address(0));
        oracle = newOracle;
    }
    
     
    function changeMaintainer(address newMaintainer) public {
        require(owner == msg.sender);
        maintainer = newMaintainer;
    }
    
     
    function redeemRewards(uint256 rewards, address destination) public {
        
         
        require(msg.sender == oracle, "Must be Oracle to complete");

         
        require(block.number > latestWithdrawBlock[destination], "Have not moved on from last block");
        
         
        uint256 reward = SafeMath.div(rewards, limiter);
        
         
        require(reward > redeemedRewards[destination], "Has not earned since last redeem");
        
         
        uint256 total = SafeMath.add(_totalSupply, reward);
        require(total <= maxMintable, "Max Mintable Reached");

         
        uint256 newUserRewards = SafeMath.sub(reward, redeemedRewards[destination]);
        
         
        _balanceOf[destination] = SafeMath.add(_balanceOf[destination], newUserRewards);
        
         
        _totalSupply = SafeMath.add(_totalSupply, newUserRewards);
        
         
        redeemedRewards[destination] = reward;
        
         
        latestWithdrawBlock[destination] = block.number;
        
         
        emit RedeemRewards(destination, newUserRewards);
         
        emit Transfer(oracle, destination, newUserRewards);
    }
    
     
     
    function redeemedRewardsOf(address destination) public view returns(uint256) {
        return redeemedRewards[destination];
    }
    
    
     
     function updateLimiter(uint256 value) public{
         require(maintainer == msg.sender);
         limiter = value;
     }
     
     function updateReferral(uint256 value) public {
         require(maintainer == msg.sender);
         referral = value;
     }
     
     function updateTwitterShare(uint256 value) public {
         require(maintainer == msg.sender);
         twitter_share = value;
     }
     
     function updateMastodonShare(uint256 value) public {
         require(maintainer == msg.sender);
         mastodon_share = value;
     }
     
     function updateArDrive(uint256 value) public {
         require(maintainer == msg.sender);
         ar_drive = value;
     }
     
     function updateMapDrive(uint256 value) public {
         require(maintainer == msg.sender);
         map_drive = value;
     }
    
    function updateDashDrive(uint256 value) public {
        require(maintainer == msg.sender);
         dash_drive = value;
     }
     
     function updateObd2Drive(uint256 value) public {
         require(maintainer == msg.sender);
         odb2_drive = value;
     }
     
     function updatePolice(uint256 value) public {
         require(maintainer == msg.sender);
         police = value;
     }
     
     function updateClosure(uint256 value) public {
        require(maintainer == msg.sender);
         closure = value;
     }
     
     function updateHazard(uint256 value) public {
         require(maintainer == msg.sender);
         hazard = value;
     }
     
     function updateTraffic(uint256 value) public {
         require(maintainer == msg.sender);
         traffic = value;
     }
     
     function updateAccident(uint256 value) public {
         require(maintainer == msg.sender);
         accident = value;
     }
     
     function updateSpeedSign(uint256 value) public {
         require(maintainer == msg.sender);
         speed_sign = value;
     }
     
     function updateBaseReport(uint256 value) public {
         require(maintainer == msg.sender);
         base_report = value;
     }
     
     function updateValidatedPoi(uint256 value) public {
         require(maintainer == msg.sender);
         validated_poi = value;
     }
     
     function updateReportInit(uint256 value) public {
         require(maintainer == msg.sender);
         report_init = value;
     }
}