 

pragma solidity ^0.4.18;

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

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract EthRateOracle is Ownable {
    uint256 public ethUsdRate;

    function update(uint256 _newValue) public onlyOwner {
        ethUsdRate = _newValue;
    }
}

contract JokerToken is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;

    EthRateOracle public oracle;
    uint256 public soldTokensCount = 0;

     
    uint256 public tokenStartPrice;

     
    uint256 public tokenSecondPeriodPrice;

    uint256 public sPerDate;
    uint256 public sPeriodEndDate;
    uint256 public sPeriodSoldTokensLimit;

     
    uint256 public nfsPoolLeft;
    uint256 public nfsPoolCount;

    uint256 public transfersAllowDate;

    constructor() public {
        name = "Joker.buzz token";
        symbol = "JOKER";
        decimals = 18;
         
        tokenStartPrice = 40;
         
        nfsPoolCount = 10900000 * (uint256(10) ** decimals);
        nfsPoolLeft = nfsPoolCount;
         
        tokenSecondPeriodPrice = 200;
        sPerDate = now + 179 days;
        sPeriodEndDate = now + 284 days;
        sPeriodSoldTokensLimit = (totalSupply_ - nfsPoolCount) - 1200000 * (uint256(10) ** decimals);
         
        transfersAllowDate = now + 284 days;
        totalSupply_ = 20000000 * (uint256(10) ** decimals);
    }



    function nfsPoolTransfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(nfsPoolLeft >= _value, "Value more than tokens left");
        require(_to != address(0), "Not allowed send to trash tokens");

        nfsPoolLeft -= _value;
        balances[_to] = balances[_to].add(_value);

        emit Transfer(address(0), _to, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transfersAllowDate <= now, "Function cannot be called at this time.");

        return BasicToken.transfer(_to, _value);
    }

    function() public payable {
        uint256 tokensCount;
        require(150000000000000 <= msg.value, "min limit eth");
        uint256 ethUsdRate = oracle.ethUsdRate();
        require(sPeriodEndDate >= now, "Sell tokens all periods ended");
        bool isSecondPeriodNow = now >= sPerDate;
        bool isSecondPeriodTokensLimitReached = soldTokensCount >= (totalSupply_ - sPeriodSoldTokensLimit - nfsPoolCount);

        if (isSecondPeriodNow || isSecondPeriodTokensLimitReached) {
            tokensCount = msg.value * ethUsdRate / tokenSecondPeriodPrice;
        } else {
            tokensCount = msg.value * ethUsdRate / tokenStartPrice;

            uint256 sPeriodTokensCount = reminderCalc(soldTokensCount + tokensCount, totalSupply_ - sPeriodSoldTokensLimit - nfsPoolCount);

            if (sPeriodTokensCount > 0) {
                tokensCount -= sPeriodTokensCount;

                uint256 weiLeft = sPeriodTokensCount * tokenStartPrice / ethUsdRate;

                tokensCount += weiLeft * ethUsdRate / tokenSecondPeriodPrice;
            }
        }
        require(tokensCount > 0, "tokens count must be positive");
        require((soldTokensCount + tokensCount) <= (totalSupply_ - nfsPoolCount), "tokens limit");

        balances[msg.sender] += tokensCount;
        soldTokensCount += tokensCount;

        emit Transfer(address(0), msg.sender, tokensCount);
    }

    function reminderCalc(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y >= x) {
            return 0;
        }
        return x - y;
    }

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracle = EthRateOracle(_oracleAddress);
    }

    function weiBalance() public constant returns (uint weiBal) {
        return address(this).balance;
    }

    function weiToOwner(address _address, uint amount) public onlyOwner {
        require(amount <= address(this).balance);
        _address.transfer(amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transfersAllowDate <= now);

        return StandardToken.transferFrom(_from, _to, _value);
    }
}