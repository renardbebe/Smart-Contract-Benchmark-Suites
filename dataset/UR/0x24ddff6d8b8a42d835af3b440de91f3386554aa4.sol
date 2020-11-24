 

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

contract IungoToken is StandardToken, Owned {
    string public constant name = "IUNGO token";
    string public constant symbol = "ING";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 100000000 * 10**uint256(decimals);

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 64000000 * 10**uint256(decimals);

     
    address public foundersFundAddress;

     
    address public teamFundAddress;

     
    address public reserveFundAddress;

     
    address public fundsTreasury;

     
     
    address public foundersFundTimelock1Address;

     
     
    address public foundersFundTimelock2Address;

     
     
    address public foundersFundTimelock3Address;

     
     
    uint64 private constant date06Dec2017 = 1512561600;

     
     
    uint64 private constant date21Dec2017 = 1513864800;

     
     
    uint64 private constant date12Jan2018 = 1515765600;

     
     
    uint64 private constant date21Jan2018 = 1516543200;

     
     
    uint64 private constant date31Jan2018 = 1517443199;

     
    uint256 public constant BASE_RATE = 1000;

     
    bool public tokenSaleClosed = false;

     
    uint256 public issueIndex = 0;

     
    event Issue(uint _issueIndex, address addr, uint tokenAmount);

     
    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP
                && !tokenSaleClosed
                && !saleDue());
        _;
    }

     
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

     
    modifier tradingOpen {
        require(saleDue());
        _;
    }

     
    function IungoToken (address _foundersFundAddress, address _teamFundAddress,
                         address _reserveFundAddress, address _fundsTreasury) public {
        foundersFundAddress = 0x9CB0016511Fb93EAc7bC585A2bc2f0C34DEcEa15;
        teamFundAddress = 0xDda7003998244f6161A5BBAf0F4ed5a40E908b51;
        reserveFundAddress = 0x9186b48Db83E63adEDaB43C19345f39c83928E3f;
        fundsTreasury = 0x31a633c4eE2C317DE2C65beb00593EAdD9f172d6;
    }

     
    function price() public view returns (uint256 tokens) {
        return computeTokenAmount(1 ether);
    }

     
     
    function () public payable {
        purchaseTokens(msg.sender);
    }

     
     
    function purchaseTokens(address _beneficiary) public payable inProgress {
         
        require(msg.value >= 0.01 ether);

        uint256 tokens = computeTokenAmount(msg.value);
        doIssueTokens(_beneficiary, tokens);

         
        fundsTreasury.transfer(msg.value);
    }

     
     
     
    function issueTokensMulti(address[] _addresses, uint256[] _tokens) public onlyOwner inProgress {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            doIssueTokens(_addresses[i], _tokens[i]);
        }
    }

     
     
     
    function issueTokens(address _beneficiary, uint256 _tokensAmount) public onlyOwner inProgress {
        doIssueTokens(_beneficiary, _tokensAmount);
    }

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokensAmount) internal {
        require(_beneficiary != address(0));

         
        uint256 increasedTotalSupply = totalSupply.add(_tokensAmount);
         
        require(increasedTotalSupply <= TOKENS_SALE_HARD_CAP);

         
        totalSupply = increasedTotalSupply;
         
        balances[_beneficiary] = balances[_beneficiary].add(_tokensAmount);
         
        Issue(
            issueIndex++,
            _beneficiary,
            _tokensAmount
        );
    }

     
     
     
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
         
        uint64 discountPercentage = currentTierDiscountPercentage();

        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint256 tokenBonus = tokenBase.mul(discountPercentage).div(100);

        tokens = tokenBase.add(tokenBonus);
    }

     
     
    function currentTierDiscountPercentage() internal view returns (uint64) {
        uint64 _now = uint64(block.timestamp);
        require(_now <= date31Jan2018);

        if(_now > date21Jan2018) return 0;
        if(_now > date12Jan2018) return 15;
        if(_now > date21Dec2017) return 35;
        return 50;
    }

     
     
     
     
     
     
     

     
    function close() public onlyOwner beforeEnd {
        uint64 _now = uint64(block.timestamp);

         
         
         
        uint256 totalTokens = totalSupply.add(totalSupply.mul(5625).div(10000));

         
        uint256 reserveFundTokens = totalTokens.mul(12).div(100);
        balances[reserveFundAddress] = balances[reserveFundAddress].add(reserveFundTokens);
        totalSupply = totalSupply.add(reserveFundTokens);
         
        Issue(
            issueIndex++,
            reserveFundAddress,
            reserveFundTokens
        );

         
        uint256 teamFundTokens = totalTokens.mul(12).div(100);
        balances[teamFundAddress] = balances[teamFundAddress].add(teamFundTokens);
        totalSupply = totalSupply.add(teamFundTokens);
         
        Issue(
            issueIndex++,
            teamFundAddress,
            teamFundTokens
        );

         
         
         
        TokenTimelock lock1_6months = new TokenTimelock(this, foundersFundAddress, _now + 183*24*60*60);
        foundersFundTimelock1Address = address(lock1_6months);
        uint256 foundersFund1Tokens = totalTokens.mul(4).div(100);
         
        balances[foundersFundTimelock1Address] = balances[foundersFundTimelock1Address].add(foundersFund1Tokens);
         
        totalSupply = totalSupply.add(foundersFund1Tokens);
         
        Issue(
            issueIndex++,
            foundersFundTimelock1Address,
            foundersFund1Tokens
        );

         
        TokenTimelock lock2_12months = new TokenTimelock(this, foundersFundAddress, _now + 365*24*60*60);
        foundersFundTimelock2Address = address(lock2_12months);
        uint256 foundersFund2Tokens = totalTokens.mul(4).div(100);
        balances[foundersFundTimelock2Address] = balances[foundersFundTimelock2Address].add(foundersFund2Tokens);
         
        totalSupply = totalSupply.add(foundersFund2Tokens);
         
        Issue(
            issueIndex++,
            foundersFundTimelock2Address,
            foundersFund2Tokens
        );

         
        TokenTimelock lock3_18months = new TokenTimelock(this, foundersFundAddress, _now + 548*24*60*60);
        foundersFundTimelock3Address = address(lock3_18months);
        uint256 foundersFund3Tokens = totalTokens.mul(4).div(100);
        balances[foundersFundTimelock3Address] = balances[foundersFundTimelock3Address].add(foundersFund3Tokens);
         
        totalSupply = totalSupply.add(foundersFund3Tokens);
         
        Issue(
            issueIndex++,
            foundersFundTimelock3Address,
            foundersFund3Tokens
        );

         
        tokenSaleClosed = true;

         
        fundsTreasury.transfer(this.balance);
    }

     
    function saleDue() public view returns (bool) {
        return date31Jan2018 < uint64(block.timestamp);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }
}