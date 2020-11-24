 

pragma solidity 0.4.23;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint64 public releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ReferralDiscountToken is StandardToken, Owned {
     
    mapping(address => address) referrerOf;
    address[] ownersIndex;

     
    event Referral(address indexed referred, address indexed referrer);

     
    function referralDiscountPercentage(address _owner) public view returns (uint256 percent) {
        uint256 total = 0;

         
        if(referrerOf[_owner] != address(0)) {
            total = total.add(10);
        }

         
        for(uint256 i = 0; i < ownersIndex.length; i++) {
            if(referrerOf[ownersIndex[i]] == _owner) {
                total = total.add(10);
                 
            }
        }

        return total;
    }

     
     
     
     
     
     
     
     
     
     
     
     

     
     

     
     
     

     
    function setReferrer(address _referred, address _referrer) onlyOwner public returns (bool success) {
        require(_referrer != address(0));
        require(_referrer != address(_referred));
         
         
        require(referrerOf[_referred] == address(0));

        ownersIndex.push(_referred);
        referrerOf[_referred] = _referrer;

        emit Referral(_referred, _referrer);
        return true;
    }
}

contract NaorisToken is ReferralDiscountToken {
    string public constant name = "NaorisToken";
    string public constant symbol = "NAO";
    uint256 public constant decimals = 18;

     
    address public saleTeamAddress;

     
    address public referalAirdropsTokensAddress;

     
    address public reserveFundAddress;

     
    address public thinkTankFundAddress;

     
    address public lockedBoardBonusAddress;

     
    address public treasuryTimelockAddress;

     
    bool public tokenSaleClosed = false;

     
    uint64 date01May2019 = 1556668800;

     
    uint256 public constant TOKENS_HARD_CAP = 400000000 * 10 ** decimals;

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 300000000 * 10 ** decimals;

     
    uint256 public constant REFERRAL_TOKENS = 10000000 * 10 ** decimals;

     
    uint256 public constant AIRDROP_TOKENS = 10000000 * 10 ** decimals;

     
    uint256 public constant THINK_TANK_FUND_TOKENS = 40000000 * 10 ** decimals;

     
    uint256 public constant NAORIS_TEAM_TOKENS = 20000000 * 10 ** decimals;

     
    uint256 public constant LOCKED_BOARD_BONUS_TOKENS = 20000000 * 10 ** decimals;

     
    modifier onlyTeam {
        assert(msg.sender == saleTeamAddress || msg.sender == owner);
        _;
    }

     
    modifier beforeEnd {
        assert(!tokenSaleClosed);
        _;
    }

    constructor(address _saleTeamAddress, address _referalAirdropsTokensAddress, address _reserveFundAddress,
    address _thinkTankFundAddress, address _lockedBoardBonusAddress) public {
        require(_saleTeamAddress != address(0));
        require(_referalAirdropsTokensAddress != address(0));
        require(_reserveFundAddress != address(0));
        require(_thinkTankFundAddress != address(0));
        require(_lockedBoardBonusAddress != address(0));

        saleTeamAddress = _saleTeamAddress;
        referalAirdropsTokensAddress = _referalAirdropsTokensAddress;
        reserveFundAddress = _reserveFundAddress;
        thinkTankFundAddress = _thinkTankFundAddress;
        lockedBoardBonusAddress = _lockedBoardBonusAddress;
                
         
        balances[saleTeamAddress] = TOKENS_SALE_HARD_CAP;
        totalSupply_ = TOKENS_SALE_HARD_CAP;
        emit Transfer(0x0, saleTeamAddress, TOKENS_SALE_HARD_CAP);

         
         
        balances[referalAirdropsTokensAddress] = REFERRAL_TOKENS;
        totalSupply_ = totalSupply_.add(REFERRAL_TOKENS);
        emit Transfer(0x0, referalAirdropsTokensAddress, REFERRAL_TOKENS);

        balances[referalAirdropsTokensAddress] = balances[referalAirdropsTokensAddress].add(AIRDROP_TOKENS);
        totalSupply_ = totalSupply_.add(AIRDROP_TOKENS);
        emit Transfer(0x0, referalAirdropsTokensAddress, AIRDROP_TOKENS);
    }

    function close() public onlyTeam beforeEnd {
         
        uint256 unsoldSaleTokens = balances[saleTeamAddress];
        if(unsoldSaleTokens > 0) {
            balances[saleTeamAddress] = 0;
            totalSupply_ = totalSupply_.sub(unsoldSaleTokens);
            emit Transfer(saleTeamAddress, 0x0, unsoldSaleTokens);
        }
        
         
        uint256 unspentReferalAirdropTokens = balances[referalAirdropsTokensAddress];
        if(unspentReferalAirdropTokens > 0) {
            balances[referalAirdropsTokensAddress] = 0;
            balances[reserveFundAddress] = balances[reserveFundAddress].add(unspentReferalAirdropTokens);
            emit Transfer(referalAirdropsTokensAddress, reserveFundAddress, unspentReferalAirdropTokens);
        }
        
         
        balances[thinkTankFundAddress] = balances[thinkTankFundAddress].add(THINK_TANK_FUND_TOKENS);
        totalSupply_ = totalSupply_.add(THINK_TANK_FUND_TOKENS);
        emit Transfer(0x0, thinkTankFundAddress, THINK_TANK_FUND_TOKENS);

         
        balances[owner] = balances[owner].add(NAORIS_TEAM_TOKENS);
        totalSupply_ = totalSupply_.add(NAORIS_TEAM_TOKENS);
        emit Transfer(0x0, owner, NAORIS_TEAM_TOKENS);

         
        TokenTimelock lockedTreasuryTokens = new TokenTimelock(this, lockedBoardBonusAddress, date01May2019);
        treasuryTimelockAddress = address(lockedTreasuryTokens);
        balances[treasuryTimelockAddress] = balances[treasuryTimelockAddress].add(LOCKED_BOARD_BONUS_TOKENS);
        totalSupply_ = totalSupply_.add(LOCKED_BOARD_BONUS_TOKENS);
        emit Transfer(0x0, treasuryTimelockAddress, LOCKED_BOARD_BONUS_TOKENS);

        require(totalSupply_ <= TOKENS_HARD_CAP);

        tokenSaleClosed = true;
    }

    function tokenDiscountPercentage(address _owner) public view returns (uint256 percent) {
        if(balanceOf(_owner) >= 1000000 * 10**decimals) {
            return 50;
        } else if(balanceOf(_owner) >= 500000 * 10**decimals) {
            return 30;
        } else if(balanceOf(_owner) >= 250000 * 10**decimals) {
            return 25;
        } else if(balanceOf(_owner) >= 100000 * 10**decimals) {
            return 20;
        } else if(balanceOf(_owner) >= 50000 * 10**decimals) {
            return 15;
        } else if(balanceOf(_owner) >= 10000 * 10**decimals) {
            return 10;
        } else if(balanceOf(_owner) >= 1000 * 10**decimals) {
            return 5;
        } else {
            return 0;
        }
    }

    function getTotalDiscount(address _owner) public view returns (uint256 percent) {
        uint256 total = 0;

        total += tokenDiscountPercentage(_owner);
        total += referralDiscountPercentage(_owner);

        return (total > 60) ? 60 : total;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(tokenSaleClosed) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(tokenSaleClosed || msg.sender == referalAirdropsTokensAddress
                        || msg.sender == saleTeamAddress) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}