 

pragma solidity ^0.4.18;

 
library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b != 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) pure internal returns (uint256) {
      return div(mul(number, numerator), denominator);
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

  mapping(address => uint256) balances;

   
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



 
contract Pausable is Ownable {

   
  uint256 public blockedTimeForBountyTokens = 0;
  uint256 public blockedTimeForInvestedTokens = 0;

   
  uint256 constant MIN_blockedTimeForBountyTokens = 1524949200;  
  uint256 constant MIN_blockedTimeForInvestedTokens = 1521061200;  

   
  mapping(address => bool) preIcoAccounts;

   
  mapping(address => bool) bountyAccounts;

   
  mapping(address => uint) founderAccounts;  

  function Pausable() public {
    blockedTimeForBountyTokens = MIN_blockedTimeForBountyTokens;
    blockedTimeForInvestedTokens = MIN_blockedTimeForInvestedTokens;
  }

   
  function changeBlockedTimeForBountyTokens(uint256 _blockedTime) onlyOwner external {
    require(_blockedTime < MIN_blockedTimeForBountyTokens);
    blockedTimeForBountyTokens = _blockedTime;
  }

   
  function changeBlockedTimeForInvestedTokens(uint256 _blockedTime) onlyOwner external {
    require(_blockedTime < MIN_blockedTimeForInvestedTokens);
    blockedTimeForInvestedTokens = _blockedTime;
  }


   
  modifier whenNotPaused() {
    require(!getPaused());
    _;
  }

   
  modifier whenPaused() {
    require(getPaused());
    _;
  }

  function getPaused() internal returns (bool) {
    if (now > blockedTimeForBountyTokens && now > blockedTimeForInvestedTokens) {
      return false;
    } else {
      uint256 blockedTime = checkTimeForTransfer(msg.sender);
      return now < blockedTime;
    }
  }


   
  function addPreIcoAccounts(address _addr) onlyOwner internal {
    require(_addr != 0x0);
    preIcoAccounts[_addr] = true;
  }

   
  function addBountyAccounts(address _addr) onlyOwner internal {
    require(_addr != 0x0);
    preIcoAccounts[_addr] = true;
  }

   
  function addFounderAccounts(address _addr, uint _flag) onlyOwner external {
    require(_addr != 0x0);
    founderAccounts[_addr] = _flag;
  }

   
  function checkTimeForTransfer(address _account) internal returns (uint256) {
    if (founderAccounts[_account] == 1) {
      return blockedTimeForInvestedTokens;
    } else if(founderAccounts[_account] == 2) {
      return 1;  
    } else if (preIcoAccounts[_account]) {
      return blockedTimeForInvestedTokens;
    } else if (bountyAccounts[_account]) {
      return blockedTimeForBountyTokens;
    } else {
      return blockedTimeForInvestedTokens;
    }
  }
}



 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}




 

contract MintableToken is PausableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function multiMintPreico(address[] _dests, uint256[] _values) onlyOwner canMint public returns (uint256) {
    uint256 i = 0;
    uint256 count = _dests.length;
    while (i < count) {
      totalSupply = totalSupply.add(_values[i]);
      balances[_dests[i]] = balances[_dests[i]].add(_values[i]);
      addPreIcoAccounts(_dests[i]);
      Mint(_dests[i], _values[i]);
      Transfer(address(0), _dests[i], _values[i]);
      i += 1;
    }
    return(i);
  }

   
  function multiMintBounty(address[] _dests, uint256[] _values) onlyOwner canMint public returns (uint256) {
    uint256 i = 0;
    uint256 count = _dests.length;
    while (i < count) {
      totalSupply = totalSupply.add(_values[i]);
      balances[_dests[i]] = balances[_dests[i]].add(_values[i]);
      addBountyAccounts(_dests[i]);
      Mint(_dests[i], _values[i]);
      Transfer(address(0), _dests[i], _values[i]);
      i += 1;
    }
    return(i);
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}



 
contract TransferableByOwner is StandardToken, Ownable {

   
  uint256 constant public OWNER_TRANSFER_TOKENS = now + 1 years;

   
  function transferByOwner(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
    require(now < OWNER_TRANSFER_TOKENS);
    require(_to != address(0));
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }
}



contract ImmlaToken is MintableToken, TransferableByOwner {
    using SafeMath for uint256;

     
    string public constant name = "IMMLA";
    string public constant symbol = "IML";
    uint8 public constant decimals = 18;
}



contract ImmlaDistribution is Ownable {
    using SafeMath for uint256;

     
    uint256 constant RATE_MIN = 3640;

     
    uint256 constant public OWNER_TRANSFER_TOKENS = now + 1 years;

     
    ImmlaToken public token;

     
    uint256 public constant emissionLimit = 418124235 * 1 ether;

     
    uint256 public additionalEmission = 0;

     
    uint256 public availableEmission = 0;

    bool public mintingPreIcoFinish = false;
    bool public mintingBountyFinish = false;
    bool public mintingFoundersFinish = false;

     
    address public wallet;

     
    uint256 public rate;

    address constant public t_ImmlaTokenDepository = 0x64075EEf64d9E105A61227CcCd5fA9F6b54DB278;
    address constant public t_ImmlaTokenDepository2 = 0x2Faaf371Af6392fdd3016E111fB4b3B551Ee46aB;
    address constant public t_ImmlaBountyTokenDepository = 0x5AB08C5Dfd53b8f6f6C3e3bbFDb521170C3863B0;
    address constant public t_Andrey = 0x027810A9C17cb0E739a33769A9E794AAF40D2338;
    address constant public t_Michail = 0x00af06cF0Ae6BD83fC36b6Ae092bb4F669B6dbF0;
    address constant public t_Slava = 0x00c11E5B0b5db0234DfF9a357F56077c9a7A83D0;
    address constant public t_Andrey2 = 0xC7e788FeaE61503136021cC48a0c95bB66d0B9f2;
    address constant public t_Michail2 = 0xb6f4ED2CE19A08c164790419D5d87D3074D4Bd92;
    address constant public t_Slava2 = 0x00ded30026135fBC460c2A9bf7beC06c7F31101a;

     
    mapping(address => Proposal) public proposals;

    struct Proposal {
        address wallet;
        uint256 amount;
        uint256 numberOfVotes;
        mapping(address => bool) voted;
    }

     
    mapping(address => bool) public congress;

     
    uint256 public minimumQuorum = 1;

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    event ProposalAdded(address indexed congressman, address indexed wallet, uint256 indexed amount);

     
    event ProposalPassed(address indexed congressman, address indexed wallet, uint256 indexed amount);

     
    modifier whenNotPreIcoFinish() {
        require(!mintingPreIcoFinish);
        _;
    }

     
    modifier whenNotBountyFinish() {
        require(!mintingBountyFinish);
        _;
    }

     
    modifier whenNotMintingFounders() {
        require(!mintingFoundersFinish);
        _;
    }

     
    modifier onlyCongress {
        require (congress[msg.sender]);
        _;
    }

     
    function ImmlaDistribution(address _token) public payable {  
        token = ImmlaToken(_token);

         
        owner = 0x00c11E5B0b5db0234DfF9a357F56077c9a7A83D0;

        wallet = owner;
        rate = RATE_MIN;

        congress[t_Andrey] = true;
        congress[t_Michail] = true;
        congress[t_Slava] = true;
        minimumQuorum = 3;
    }

     
    function mintToFounders() onlyOwner whenNotMintingFounders public returns (bool) {
        mintToFounders(t_ImmlaTokenDepository, 52000 * 1 ether, 2);
        mintToFounders(t_ImmlaTokenDepository2, 0, 2);
        mintToFounders(t_ImmlaBountyTokenDepository, 0, 2);
        mintToFounders(t_Andrey,   525510849836086000000000, 1);
        mintToFounders(t_Michail,  394133137377065000000000, 1);
        mintToFounders(t_Slava,    394133137377065000000000, 1);
        mintToFounders(t_Andrey2,  284139016853060000000000, 2);
        mintToFounders(t_Michail2, 213104262639795000000000, 2);
        mintToFounders(t_Slava2,   213104262639795000000000, 2);
        mintingFoundersFinish = true;

        return true;
    }

     
    function () external payable {
        buyTokens();
    }

     
    function buyTokens() public payable {
        require(availableEmission > 0);
        require(msg.value != 0);

        address investor = msg.sender;
        uint256 weiAmount = msg.value;

        uint256 tokensAmount = weiAmount.mul(rate);

         
        uint256 tokensChange = 0;
        if (tokensAmount > availableEmission) {
            tokensChange = tokensAmount - availableEmission;
            tokensAmount = availableEmission;
        }

         
        uint256 weiChange = 0;
        if (tokensChange > 0) {
            weiChange = tokensChange.div(rate);
            investor.transfer(weiChange);
        }

        uint256 weiRaised = weiAmount - weiChange;

         
        additionalEmission = additionalEmission.add(tokensAmount);
        availableEmission = availableEmission.sub(tokensAmount);

         
        token.mint(investor, tokensAmount);
        TokenPurchase(investor, weiRaised, tokensAmount);
        mintBonusToFounders(tokensAmount);

         
        wallet.transfer(weiRaised);
    }

     
    function updateAdditionalEmission(uint256 _amount, uint256 _rate) onlyOwner public {  
        require(_amount > 0);
        require(_amount < (emissionLimit - additionalEmission));

        availableEmission = _amount;
        if (_rate > RATE_MIN) {
            rate = RATE_MIN;
        } else {
            rate = _rate;
        }
    }

     
    function stopPreIcoMint() onlyOwner whenNotPreIcoFinish public {
        mintingPreIcoFinish = true;
    }

     
    function stopBountyMint() onlyOwner whenNotBountyFinish public {
        mintingBountyFinish = true;
    }

     
    function multiMintPreIco(address[] _dests, uint256[] _values) onlyOwner whenNotPreIcoFinish public returns (bool) {
        token.multiMintPreico(_dests, _values);
        return true;
    }

     
    function multiMintBounty(address[] _dests, uint256[] _values) onlyOwner whenNotBountyFinish public returns (bool) {
        token.multiMintBounty(_dests, _values);
        return true;
    }

     
    function mintToFounders(address _dest, uint256 _value, uint _flag) internal {
        token.mint(_dest, _value);
        token.addFounderAccounts(_dest, _flag);
    }

     
    function mintBonusToFounders(uint256 _value) internal {

        uint256 valueWithCoefficient = (_value * 1000) / 813;
        uint256 valueWithMultiplier1 = valueWithCoefficient / 10;
        uint256 valueWithMultiplier2 = (valueWithCoefficient * 7) / 100;

        token.mint(t_Andrey, (valueWithMultiplier1 * 4) / 10);
        token.mint(t_Michail, (valueWithMultiplier1 * 3) / 10);
        token.mint(t_Slava, (valueWithMultiplier1 * 3) / 10);
        token.mint(t_Andrey2, (valueWithMultiplier2 * 4) / 10);
        token.mint(t_Michail2, (valueWithMultiplier2 * 3) / 10);
        token.mint(t_Slava2, (valueWithMultiplier2 * 3) / 10);
        token.mint(t_ImmlaBountyTokenDepository, (valueWithCoefficient * 15) / 1000);
    }

     
    function changeBlockedTimeForBountyTokens(uint256 _blockedTime) onlyOwner public {
        token.changeBlockedTimeForBountyTokens(_blockedTime);
    }

     
    function changeBlockedTimeForInvestedTokens(uint256 _blockedTime) onlyOwner public {
        token.changeBlockedTimeForInvestedTokens(_blockedTime);
    }

     
    function proposal(address _wallet, uint256 _amount) onlyCongress public {
        require(availableEmission > 0);
        require(_amount > 0);
        require(_wallet != 0x0);
        
        if (proposals[_wallet].amount > 0) {
            require(proposals[_wallet].voted[msg.sender] != true);  
            require(proposals[_wallet].amount == _amount);  

            proposals[_wallet].voted[msg.sender] = true;  
            proposals[_wallet].numberOfVotes++;  

             
            if (proposals[_wallet].numberOfVotes >= minimumQuorum) {
                if (_amount > availableEmission) {
                    _amount = availableEmission;
                }

                 
                additionalEmission = additionalEmission.add(_amount);
                availableEmission = availableEmission.sub(_amount);

                token.mint(_wallet, _amount);
                TokenPurchase(_wallet, 0, _amount);
                ProposalPassed(msg.sender, _wallet, _amount);

                mintBonusToFounders(_amount);
                delete proposals[_wallet];
            }

        } else {
            Proposal storage p = proposals[_wallet];

            p.wallet           = _wallet;
            p.amount           = _amount;
            p.numberOfVotes    = 1;
            p.voted[msg.sender] = true;

            ProposalAdded(msg.sender, _wallet, _amount);
        }
    }

     
    function transferTokens(address _from, address _to, uint256 _amount) onlyOwner public {
        require(_amount > 0);

         
        require(now < OWNER_TRANSFER_TOKENS);

         
        require(!congress[_from]);
        require(!congress[_to]);

        token.transferByOwner(_from, _to, _amount);
    }
}