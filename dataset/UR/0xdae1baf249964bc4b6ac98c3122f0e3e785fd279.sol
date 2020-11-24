 

pragma solidity 0.4.18;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
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

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
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

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
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

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract TokiaToken is StandardToken, Owned {
    string public constant name = "TokiaToken";
    string public constant symbol = "TKA";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 62500000 * 10**uint256(decimals);

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 50000000 * 10**uint256(decimals);

     
    uint256 public constant BASE_RATE = 714;

     
     
    uint64 private constant date04Dec2017 = 1512345600;

     
    uint64 private constant date01Jan2018 = 1514764800;

     
    uint64 private constant date01Feb2018 = 1517443200;

     
    uint64 private constant date15Feb2018 = 1518652800;

     
    uint64 private constant date01Mar2018 = 1519862400;

     
    uint64 private constant date15Mar2018 = 1521072000;

     
    uint64 private constant date01Jan2019 = 1546300800;

     
    uint64 private constant date01May2018 = 1525219199;

     
    bool public tokenSaleClosed = false;

     
    address public timelockContractAddress;

     
    uint64 public issueIndex = 0;

     
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP
            && !tokenSaleClosed);
        _;
    }

     
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

     
    modifier tradingOpen {
        require(uint64(block.timestamp) > date01May2018);
        _;
    }

    function TokiaToken() public {
    }

     
     
    function () public payable {
        purchaseTokens(msg.sender);
    }

     
     
    function purchaseTokens(address _beneficiary) public payable inProgress {
         
        require(msg.value >= 0.01 ether);

        uint256 tokens = computeTokenAmount(msg.value);
        doIssueTokens(_beneficiary, tokens);

         
        owner.transfer(this.balance);
    }

     
     
     
    function issueTokensMulti(address[] _addresses, uint256[] _tokens) public onlyOwner inProgress {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            doIssueTokens(_addresses[i], _tokens[i].mul(10**uint256(decimals)));
        }
    }

     
     
     
    function issueTokens(address _beneficiary, uint256 _tokens) public onlyOwner inProgress {
        doIssueTokens(_beneficiary, _tokens.mul(10**uint256(decimals)));
    }

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));

         
        uint256 increasedTotalSupply = totalSupply.add(_tokens);
         
        require(increasedTotalSupply <= TOKENS_SALE_HARD_CAP);

         
        totalSupply = increasedTotalSupply;
         
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);

         
        Issue(
            issueIndex++,
            _beneficiary,
            _tokens
        );
    }

     
    function price() public view returns (uint256 tokens) {
        return computeTokenAmount(1 ether);
    }

     
     
     
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint8[5] memory roundDiscountPercentages = [47, 35, 25, 15, 5];

        uint8 roundDiscountPercentage = roundDiscountPercentages[currentRoundIndex()];
        uint8 amountDiscountPercentage = getAmountDiscountPercentage(tokenBase);

        tokens = tokenBase.mul(100).div(100 - (roundDiscountPercentage + amountDiscountPercentage));
    }

     
     
     
    function getAmountDiscountPercentage(uint256 tokenBase) internal pure returns (uint8) {
        if(tokenBase >= 1500 * 10**uint256(decimals)) return 9;
        if(tokenBase >= 1000 * 10**uint256(decimals)) return 5;
        if(tokenBase >= 500 * 10**uint256(decimals)) return 3;
        return 0;
    }

     
     
    function currentRoundIndex() internal view returns (uint8 roundNum) {
        roundNum = currentRoundIndexByDate();

         
        uint256[5] memory roundCaps = [
            10000000 * 10**uint256(decimals),
            22500000 * 10**uint256(decimals),  
            35000000 * 10**uint256(decimals),  
            40000000 * 10**uint256(decimals),  
            50000000 * 10**uint256(decimals)   
        ];

         
        while(roundNum < 4 && totalSupply > roundCaps[roundNum]) {
            roundNum++;
        }
    }

     
     
    function currentRoundIndexByDate() internal view returns (uint8 roundNum) {
        uint64 _now = uint64(block.timestamp);
        require(_now <= date15Mar2018);

        roundNum = 0;
        if(_now > date01Mar2018) roundNum = 4;
        if(_now > date15Feb2018) roundNum = 3;
        if(_now > date01Feb2018) roundNum = 2;
        if(_now > date01Jan2018) roundNum = 1;
        return roundNum;
    }

     
    function close() public onlyOwner beforeEnd {
         
        uint256 teamTokens = totalSupply.mul(25).div(100);

         
        if(totalSupply.add(teamTokens) > HARD_CAP) {
            teamTokens = HARD_CAP.sub(totalSupply);
        }

         
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, date01Jan2019);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(teamTokens);
         
        totalSupply = totalSupply.add(teamTokens);
         
        Issue(
            issueIndex++,
            timelockContractAddress,
            teamTokens
        );

         
        tokenSaleClosed = true;

         
        owner.transfer(this.balance);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }
}