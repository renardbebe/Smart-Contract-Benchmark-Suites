 

pragma solidity 0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract SKYFToken is Ownable {
    using SafeMath for uint256;
    
    enum State {Active, Finalized}
    State public state = State.Active;


     
    string public constant name = "SKYFchain";
    string public constant symbol = "SKYFT";
    uint8 public decimals = 18;

    uint256 public constant startTime = 1534334400;
    uint256 public constant airdropTime = startTime + 365 days;
    uint256 public constant shortAirdropTime = startTime + 182 days;
    
    
    uint256 public totalSupply_ = 1200 * 10 ** 24;

    uint256 public constant crowdsaleSupply = 528 * 10 ** 24;
    uint256 public constant networkDevelopmentSupply = 180 * 10 ** 24;
    uint256 public constant communityDevelopmentSupply = 120 * 10 ** 24;
    uint256 public constant reserveSupply = 114 * 10 ** 24; 
    uint256 public constant bountySupply = 18 * 10 ** 24;
    uint256 public constant teamSupply = 240 * 10 ** 24;
    

    address public crowdsaleWallet;
    address public networkDevelopmentWallet;
    address public communityDevelopmentWallet;
    address public reserveWallet;
    address public bountyWallet;
    address public teamWallet;

    address public siteAccount;

    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balances;
    mapping (address => uint256) airdrop;
    mapping (address => uint256) shortenedAirdrop;

        

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Airdrop(address indexed beneficiary, uint256 amount);

     
    constructor(address _crowdsaleWallet
                , address _networkDevelopmentWallet
                , address _communityDevelopmentWallet
                , address _reserveWallet
                , address _bountyWallet
                , address _teamWallet
                , address _siteAccount) public {
        require(_crowdsaleWallet != address(0));
        require(_networkDevelopmentWallet != address(0));
        require(_communityDevelopmentWallet != address(0));
        require(_reserveWallet != address(0));
        require(_bountyWallet != address(0));
        require(_teamWallet != address(0));

        require(_siteAccount != address(0));

        crowdsaleWallet = _crowdsaleWallet;
        networkDevelopmentWallet = _networkDevelopmentWallet;
        communityDevelopmentWallet = _communityDevelopmentWallet;
        reserveWallet = _reserveWallet;
        bountyWallet = _bountyWallet;
        teamWallet = _teamWallet;

        siteAccount = _siteAccount;

         
        _issueTokens(crowdsaleWallet, crowdsaleSupply);

         
        _issueTokens(networkDevelopmentWallet, networkDevelopmentSupply);

         
        _issueTokens(communityDevelopmentWallet, communityDevelopmentSupply);

         
        _issueTokens(reserveWallet, reserveSupply);

         
        _issueTokens(bountyWallet, bountySupply);

         
        _issueTokens(teamWallet, teamSupply);

        allowed[crowdsaleWallet][siteAccount] = crowdsaleSupply;
        emit Approval(crowdsaleWallet, siteAccount, crowdsaleSupply);
        allowed[crowdsaleWallet][owner] = crowdsaleSupply;
        emit Approval(crowdsaleWallet, owner, crowdsaleSupply);
    }

    function _issueTokens(address _to, uint256 _amount) internal {
        require(balances[_to] == 0);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function _airdropUnlocked(address _who) internal view returns (bool) {
        return now > airdropTime
        || (now > shortAirdropTime && airdrop[_who] == 0) 
        || !isAirdrop(_who);
    }

    modifier erc20Allowed() {
        require(state == State.Finalized || msg.sender == owner|| msg.sender == siteAccount || msg.sender == crowdsaleWallet);
        require (_airdropUnlocked(msg.sender));
        _;
    }

    modifier onlyOwnerOrSiteAccount() {
        require(msg.sender == owner || msg.sender == siteAccount);
        _;
    }
    
    function setSiteAccountAddress(address _address) public onlyOwner {
        require(_address != address(0));

        uint256 allowance = allowed[crowdsaleWallet][siteAccount];
        allowed[crowdsaleWallet][siteAccount] = 0;
        emit Approval(crowdsaleWallet, siteAccount, 0);
        allowed[crowdsaleWallet][_address] = allowed[crowdsaleWallet][_address].add(allowance);
        emit Approval(crowdsaleWallet, _address, allowed[crowdsaleWallet][_address]);
        siteAccount = _address;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public erc20Allowed returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_airdropUnlocked(_to));

        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);


        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public erc20Allowed returns (bool) {
        return _transferFrom(msg.sender, _from, _to, _value);
    }

    function _transferFrom(address _who, address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_airdropUnlocked(_to) || _from == crowdsaleWallet);

        uint256 _allowance = allowed[_from][_who];

        require(_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][_who] = _allowance.sub(_value);

        _recalculateAirdrop(_to);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public erc20Allowed returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public erc20Allowed returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public erc20Allowed returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public erc20Allowed {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function finalize() public onlyOwner {
        require(state == State.Active);
        require(now > startTime);
        state = State.Finalized;

        uint256 crowdsaleBalance = balanceOf(crowdsaleWallet);

        uint256 burnAmount = networkDevelopmentSupply.mul(crowdsaleBalance).div(crowdsaleSupply);
        _burn(networkDevelopmentWallet, burnAmount);

        burnAmount = communityDevelopmentSupply.mul(crowdsaleBalance).div(crowdsaleSupply);
        _burn(communityDevelopmentWallet, burnAmount);

        burnAmount = reserveSupply.mul(crowdsaleBalance).div(crowdsaleSupply);
        _burn(reserveWallet, burnAmount);

        burnAmount = bountySupply.mul(crowdsaleBalance).div(crowdsaleSupply);
        _burn(bountyWallet, burnAmount);

        burnAmount = teamSupply.mul(crowdsaleBalance).div(crowdsaleSupply);
        _burn(teamWallet, burnAmount);

        _burn(crowdsaleWallet, crowdsaleBalance);
    }
    
    function addAirdrop(address _beneficiary, uint256 _amount) public onlyOwnerOrSiteAccount {
        require(_beneficiary != crowdsaleWallet);
        require(_beneficiary != networkDevelopmentWallet);
        require(_beneficiary != communityDevelopmentWallet);
        require(_beneficiary != bountyWallet);
        require(_beneficiary != siteAccount);
        

         
        require(balances[_beneficiary] == 0 || isAirdrop(_beneficiary));

        if (shortenedAirdrop[_beneficiary] != 0) {
            shortenedAirdrop[_beneficiary] = shortenedAirdrop[_beneficiary].add(_amount);
        }
        else {
            airdrop[_beneficiary] = airdrop[_beneficiary].add(_amount);
        }
        
        _transferFrom(msg.sender, crowdsaleWallet, _beneficiary, _amount);
        emit Airdrop(_beneficiary, _amount);
    }

    function isAirdrop(address _who) public view returns (bool result) {
        return airdrop[_who] > 0 || shortenedAirdrop[_who] > 0;
    }

    function _recalculateAirdrop(address _who) internal {
        if(state == State.Active && isAirdrop(_who)) {
            uint256 initialAmount = airdrop[_who];
            if (initialAmount > 0) {
                uint256 rate = balances[_who].div(initialAmount);
                if (rate >= 4) {
                    delete airdrop[_who];
                } else if (rate >= 2) {
                    delete airdrop[_who];
                    shortenedAirdrop[_who] = initialAmount;
                }
            } else {
                initialAmount = shortenedAirdrop[_who];
                if (initialAmount > 0) {
                    rate = balances[_who].div(initialAmount);
                    if (rate >= 4) {
                        delete shortenedAirdrop[_who];
                    }
                }
            }
        }
    }
   
}