 

pragma solidity 0.4.18;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

 
contract TokenDeskToken is StandardToken, Owned {
    string public constant name = "TokenDesk";
    string public constant symbol = "TDS";
    uint256 public constant decimals = 18;

     
    uint256 public constant TOKENS_HARD_CAP = 20000000 * 10**decimals;

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 14000000 * 10**decimals;

    bool public tokenSaleClosed = false;

     
    address public timelockContractAddress;

     
    uint64 private date24Dec2017 = 1514073600;

     
    uint64 private date01Jan2019 = 1546300800;

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP && !tokenSaleClosed);
        _;
    }

    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

     
    modifier tradingOpen {
        require(tokenSaleClosed || (uint64(block.timestamp) > date24Dec2017));
        _;
    }

    function issueTokensMulti(address[] _addresses, uint256[] _tokensInteger) public onlyOwner inProgress {
        require(_addresses.length == _tokensInteger.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokensInteger.length; i = i.add(1)) {
            issueTokens(_addresses[i], _tokensInteger[i]);
        }
    }

    function issueTokens(address _investor, uint256 _tokensInteger) public onlyOwner inProgress {
        require(_investor != address(0));

        uint256 tokens = _tokensInteger.mul(10**decimals);
         
        uint256 increasedTotalSupply = totalSupply.add(tokens);
         
        require(increasedTotalSupply <= TOKENS_SALE_HARD_CAP);

         
        totalSupply = increasedTotalSupply;
         
        balances[_investor] = balances[_investor].add(tokens);
    }

    function close() public onlyOwner beforeEnd {
         
         
         
         
         

        uint256 teamTokens = totalSupply.mul(3).div(7);

         
        if(totalSupply.add(teamTokens) > TOKENS_HARD_CAP) {
            teamTokens = TOKENS_HARD_CAP.sub(totalSupply);
        }

         
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, date01Jan2019);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(teamTokens);
        
         
        totalSupply = totalSupply.add(teamTokens);

        tokenSaleClosed = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }
}