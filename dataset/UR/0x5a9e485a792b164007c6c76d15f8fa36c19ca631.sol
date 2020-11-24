 

pragma solidity ^0.4.20;

contract GenesisProtected {
    modifier addrNotNull(address _address) {
        require(_address != address(0));
        _;
    }
}


 
 
 
 
 
 
 
 

 
contract Ownable is GenesisProtected {
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function setOwner(address a) external onlyOwner addrNotNull(a) {
        owner = a;
        emit OwnershipReplaced(msg.sender, a);
    }

    event OwnershipReplaced(
        address indexed previousOwner,
        address indexed newOwner
    );
}


 
 
 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner)
        public constant returns (uint balance);
    function allowance(address tokenOwner, address spender)
        public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens)
        public returns (bool success);
    function transferFrom(address from, address to, uint tokens)
        public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint tokens
    );
}

contract Enums {
     
    enum BasketType {
        unknown,  
        team,  
        foundation,  
        arr,  
        advisors,  
        bounty,  
        referral,  
        referrer  
    }
}


contract WPTokensBaskets is Ownable, Enums {
     
    mapping (address => BasketType) internal types;

     
    address public team;
    address public foundation;
    address public arr;
    address public advisors;
    address public bounty;

     
    function WPTokensBaskets(
        address _team,
        address _foundation,
        address _arr,
        address _advisors,
        address _bounty
    )
        public
    {
        setTeam(_team);
        setFoundation(_foundation);
        setARR(_arr);
        setAdvisors(_advisors);
        setBounty(_bounty);
    }

     
    function () external payable {
        revert();
    }

     
     
     
     
    function transferEtherTo(address a) external onlyOwner addrNotNull(a) {
        a.transfer(address(this).balance);
    }

    function typeOf(address a) public view returns (BasketType) {
        return types[a];
    }

     
    function isUnknown(address a) public view returns (bool) {
        return types[a] == BasketType.unknown;
    }

    function isTeam(address a) public view returns (bool) {
        return types[a] == BasketType.team;
    }

    function isFoundation(address a) public view returns (bool) {
        return types[a] == BasketType.foundation;
    }

    function setTeam(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[team = a] = BasketType.team;
    }

    function setFoundation(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[foundation = a] = BasketType.foundation;
    }

    function setARR(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[arr = a] = BasketType.arr;
    }

    function setAdvisors(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[advisors = a] = BasketType.advisors;
    }

    function setBounty(address a) public onlyOwner addrNotNull(a) {
        require(types[a] == BasketType.unknown);
        types[bounty = a] = BasketType.bounty;
    }
}

 
 
 
 
 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0)
            return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Token is Ownable, ERC20Interface, Enums {
    using SafeMath for uint;

     
    string private constant NAME = "EnvisionX EXCHAIN Token";
     
    string private constant SYMBOL = "EXT";
     
    uint8 private constant DECIMALS = 18;

     
    uint public constant MAX_SUPPLY = 3000000000 * (10**uint(DECIMALS));

     
    mapping(address => uint) internal balances;

     
    mapping (address => mapping (address => uint)) internal allowed;

     
    uint internal _totalSupply;

     
    mapping(address => uint) internal etherFunds;
    uint internal _earnedFunds;
     
    mapping(address => bool) internal refunded;

     
    address public mintAgent;

     
    bool public isMintingFinished = false;
     
    uint public mintingStopDate;

     
     
     
    uint public teamTotal;
     
     
     
    uint public spentByTeam;

     
    WPTokensBaskets public wpTokensBaskets;

     
    function Token(WPTokensBaskets baskets) public {
        wpTokensBaskets = baskets;
        mintAgent = owner;
    }

     
    function () external payable {
        revert();
    }

     
     
     
     
    function transferEtherTo(address a) external onlyOwner addrNotNull(a) {
        a.transfer(address(this).balance);
    }

     

     
    function name() public pure returns (string) {
        return NAME;
    }

     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

     
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address _address) public constant returns (uint) {
        return balances[_address];
    }

     
    function transfer(address to, uint value)
        public
        addrNotNull(to)
        returns (bool)
    {
        if (balances[msg.sender] < value)
            return false;
        if (isFrozen(wpTokensBaskets.typeOf(msg.sender), value))
            return false;
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        saveTeamSpent(msg.sender, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
     
    function transferFrom(address from, address to, uint value)
        public
        addrNotNull(to)
        returns (bool)
    {
        if (balances[from] < value)
            return false;
        if (allowance(from, msg.sender) < value)
            return false;
        if (isFrozen(wpTokensBaskets.typeOf(from), value))
            return false;
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        saveTeamSpent(from, value);
        emit Transfer(from, to, value);
        return true;
    }

     
     
    function approve(address spender, uint value) public returns (bool) {
        if (msg.sender == spender)
            return false;
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
    function allowance(address _owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowed[_owner][spender];
    }

     

     
    function etherFundsOf(address _address) public constant returns (uint) {
        return etherFunds[_address];
    }

     
    function earnedFunds() public constant returns (uint) {
        return _earnedFunds;
    }

     
    function isRefunded(address _address) public view returns (bool) {
        return refunded[_address];
    }

     
     
    function setMintAgent(address a) public onlyOwner addrNotNull(a) {
        emit MintAgentReplaced(mintAgent, a);
        mintAgent = a;
    }

     
    function mint(address to, uint256 extAmount, uint256 etherAmount) public {
        require(!isMintingFinished);
        require(msg.sender == mintAgent);
        require(!refunded[to]);
        _totalSupply = _totalSupply.add(extAmount);
        require(_totalSupply <= MAX_SUPPLY);
        balances[to] = balances[to].add(extAmount);
        if (wpTokensBaskets.isUnknown(to)) {
            _earnedFunds = _earnedFunds.add(etherAmount);
            etherFunds[to] = etherFunds[to].add(etherAmount);
        } else if (wpTokensBaskets.isTeam(to)) {
            teamTotal = teamTotal.add(extAmount);
        }
        emit Mint(to, extAmount);
        emit Transfer(msg.sender, to, extAmount);
    }

     
     
     
     
     
     
     
     
     
    function burnTokensAndRefund(address _address)
        external
        payable
        addrNotNull(_address)
        onlyOwner()
    {
        require(msg.value > 0 && msg.value == etherFunds[_address]);
        _totalSupply = _totalSupply.sub(balances[_address]);
        balances[_address] = 0;
        _earnedFunds = _earnedFunds.sub(msg.value);
        etherFunds[_address] = 0;
        refunded[_address] = true;
        _address.transfer(msg.value);
    }

     
    function finishMinting() external onlyOwner {
        require(!isMintingFinished);
        isMintingFinished = true;
        mintingStopDate = now;
        emit MintingFinished();
    }

     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function isFrozen(
        BasketType _basketType,
        uint _value
    )
        public view returns (bool)
    {
        if (!isMintingFinished) {
             
            return true;
        }
        if (_basketType == BasketType.foundation) {
             
             
            return now < mintingStopDate + 48 weeks;
        }
        if (_basketType == BasketType.team) {
             
             
             
             
             
            if (mintingStopDate + 96 weeks <= now) {
                return false;
            }
            if (now < mintingStopDate + 24 weeks)
                return true;
             
             
             
            uint fractionSpent =
                spentByTeam.add(_value).mul(1000000000000).div(teamTotal);
            if (now < mintingStopDate + 48 weeks) {
                return 250000000000 < fractionSpent;
            }
            if (now < mintingStopDate + 72 weeks) {
                return 500000000000 < fractionSpent;
            }
             
            return 750000000000 < fractionSpent;
        }
         
        return false;
    }

     
     
     
    function saveTeamSpent(address _owner, uint _value) internal {
        if (wpTokensBaskets.isTeam(_owner)) {
            if (now < mintingStopDate + 96 weeks)
                spentByTeam = spentByTeam.add(_value);
        }
    }

     

     
     
    event MintAgentReplaced(
        address indexed previousMintAgent,
        address indexed newMintAgent
    );

     
    event Mint(address indexed to, uint256 amount);

     
    event MintingFinished();
}