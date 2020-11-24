 

pragma solidity ^0.4.19;

 
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

 
contract VestedToken {
    using SafeMath for uint256;
    
     
    address public vestedAddress;
     
    uint private constant VESTING_DELAY = 1 years;  
     
    uint private constant TOKEN_TRADABLE_DELAY = 12 days;

     
    bool public asideTokensHaveBeenMinted = false;
     
    uint public asideTokensMintDate;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    modifier transferAllowed { require(asideTokensHaveBeenMinted && now > asideTokensMintDate + TOKEN_TRADABLE_DELAY); _; }
    
     
    function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }  

     
    function transfer(address _to, uint256 _value) transferAllowed public returns (bool success) {
        require(_to != 0x0);
        
         
        if (msg.sender == vestedAddress && (now < (asideTokensMintDate + VESTING_DELAY))) { revert(); }

        return privateTransfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferAllowed public returns (bool success) {
        require(_from != 0x0);
        require(_to != 0x0);
        
         
        if (_from == vestedAddress && (now < (asideTokensMintDate + VESTING_DELAY))) { revert(); }

        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function privateTransfer (address _to, uint256 _value) private returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract WhitelistsRegistration is Ownable {
     
    mapping(address => bool) silverWhiteList;
    
     
    mapping(address => bool) goldWhiteList;
    
     
    enum WhiteListState {
         
        None,
         
        Silver,
         
        Gold
    }
    
    address public whiteLister;

    event SilverWhitelist(address indexed _address, bool _isRegistered);
    event GoldWhitelist(address indexed _address, bool _isRegistered);  
    event SetWhitelister(address indexed newWhiteLister);
    
     
    modifier onlyOwnerOrWhiteLister() {
        require((msg.sender == owner) || (msg.sender == whiteLister));
    _;
    }
    
     
    function checkRegistrationStatus(address _address) public constant returns (WhiteListState) {
        if (goldWhiteList[_address]) { return WhiteListState.Gold; }
        if (silverWhiteList[_address]) { return WhiteListState.Silver; }
        return WhiteListState.None;
    }
    
     
    function changeRegistrationStatusForSilverWhiteList(address _address, bool _isRegistered) public onlyOwnerOrWhiteLister {
        silverWhiteList[_address] = _isRegistered;
        SilverWhitelist(_address, _isRegistered);
    }
    
     
    function changeRegistrationStatusForGoldWhiteList(address _address, bool _isRegistered) public onlyOwnerOrWhiteLister {
        goldWhiteList[_address] = _isRegistered;
        GoldWhitelist(_address, _isRegistered);
    }
    
     
    function massChangeRegistrationStatusForSilverWhiteList(address[] _targets, bool _isRegistered) public onlyOwnerOrWhiteLister {
        for (uint i = 0; i < _targets.length; i++) {
            changeRegistrationStatusForSilverWhiteList(_targets[i], _isRegistered);
        }
    } 
    
     
    function massChangeRegistrationStatusForGoldWhiteList(address[] _targets, bool _isRegistered) public onlyOwnerOrWhiteLister {
        for (uint i = 0; i < _targets.length; i++) {
            changeRegistrationStatusForGoldWhiteList(_targets[i], _isRegistered);
        }
    }
    
     
    function setWhitelister(address _newWhiteLister) public onlyOwnerOrWhiteLister {
      require(_newWhiteLister != address(0));
      SetWhitelister(_newWhiteLister);
      whiteLister = _newWhiteLister;
    }
}

 
contract BCDToken is VestedToken, WhitelistsRegistration {
    
    string public constant name = "Blockchain Certified Data Token";
    string public constant symbol = "BCDT";
    uint public constant decimals = 18;

     
    uint private constant MAX_ETHER_FOR_SILVER_WHITELIST = 10 ether;
    
     
    uint public rateETH_BCDT = 13000;

     
    uint public softCap = 1800 ether;

     
    uint public presaleCap = 1800 ether;
    
     
    uint public round1Cap = 3600 ether;    
    
     
    address public reserveAddress;
    address public communityAddress;

     
    enum State {
         
        Init,
         
        PresaleRunning,
         
        PresaleFinished,
         
        Round1Running,
         
        Round1Finished,
         
        Round2Running,
         
        Round2Finished
    }
    
     
    State public currentState = State.Init;
    
     
    uint256 public totalSupply = MAX_TOTAL_BCDT_TO_SELL;

     
    uint256 public tokensSold;
    
     
    uint256 private etherRaisedDuringICO;
    
     
    uint private constant MAX_TOTAL_BCDT_TO_SELL = 100000000 * 1 ether;

     
    uint private constant RESERVE_ALLOCATION_PER_MILLE_RATIO =  200;
    uint private constant COMMUNITY_ALLOCATION_PER_MILLE_RATIO =  103;
    uint private constant FOUNDERS_ALLOCATION_PER_MILLE_RATIO =  30;
    
     
    mapping(address => uint256) contributors;

     
    modifier inStateInit()
    {
        require(currentState == State.Init); 
        _; 
    }
	
    modifier inStateRound2Finished()
    {
        require(currentState == State.Round2Finished); 
        _; 
    }
    
     
    event AsideTokensHaveBeenAllocated(address indexed to, uint256 amount);
     
    event Withdraw(address indexed to, uint256 amount);
     
    event StateChanged(uint256 timestamp, State currentState);

     
    function BCDToken() public {
    }

    function() public payable {
        require(currentState == State.PresaleRunning || currentState == State.Round1Running || currentState == State.Round2Running);

         
        if (msg.value < 100 finney) { revert(); }

         
        if (!silverWhiteList[msg.sender] && !goldWhiteList[msg.sender]) {
            revert();
        }

         
        uint256 ethSent = msg.value;
        
         
        uint256 ethToUse = ethSent;

         
        if (!goldWhiteList[msg.sender]) {
             
            if (contributors[msg.sender] >= MAX_ETHER_FOR_SILVER_WHITELIST) {
                revert();
            }
             
            if (contributors[msg.sender].add(ethToUse) > MAX_ETHER_FOR_SILVER_WHITELIST) {
                ethToUse = MAX_ETHER_FOR_SILVER_WHITELIST.sub(contributors[msg.sender]);
            }
        }
        
          
        uint256 ethAvailable = getRemainingEthersForCurrentRound();
        uint rate = getBCDTRateForCurrentRound();

         
        if (ethAvailable <= ethToUse) {
             
            privateSetState(getEndedStateForCurrentRound());
             
            ethToUse = ethAvailable;
        }
        
         
        uint256 tokenToSend = ethToUse.mul(rate);
        
         
        tokensSold = tokensSold.add(tokenToSend);
         
        etherRaisedDuringICO = etherRaisedDuringICO.add(ethToUse);
         
        balances[msg.sender] = balances[msg.sender].add(tokenToSend);
         
        contributors[msg.sender] = contributors[msg.sender].add(ethToUse);
        
         
        if (ethToUse < ethSent) {
            msg.sender.transfer(ethSent.sub(ethToUse));
        }
         
        Transfer(0x0, msg.sender, tokenToSend); 
    }

     
    function withdraw() public inStateRound2Finished {
         
        if(contributors[msg.sender] == 0) { revert(); }
        
         
        require(etherRaisedDuringICO < softCap);
        
         
        uint256 ethToSendBack = contributors[msg.sender];
        
         
        contributors[msg.sender] = 0;
        
         
        msg.sender.transfer(ethToSendBack);
        
         
        Withdraw(msg.sender, ethToSendBack);
    }

     
    function mintAsideTokens() public onlyOwner inStateRound2Finished {

         
        require((reserveAddress != 0x0) && (communityAddress != 0x0) && (vestedAddress != 0x0));

         
        require(this.balance >= softCap);

         
        if (asideTokensHaveBeenMinted) { revert(); }

         
        asideTokensHaveBeenMinted = true;
        asideTokensMintDate = now;

         
        totalSupply = tokensSold.mul(15).div(10);

         
        uint256 _amountMinted = setAllocation(reserveAddress, RESERVE_ALLOCATION_PER_MILLE_RATIO);

         
        _amountMinted = _amountMinted.add(setAllocation(communityAddress, COMMUNITY_ALLOCATION_PER_MILLE_RATIO));

         
        _amountMinted = _amountMinted.add(setAllocation(vestedAddress, FOUNDERS_ALLOCATION_PER_MILLE_RATIO));
        
         
         
        totalSupply = tokensSold.add(_amountMinted);
         
        owner.transfer(this.balance);
    }
    
    function setTokenAsideAddresses(address _reserveAddress, address _communityAddress, address _founderAddress) public onlyOwner {
        require(_reserveAddress != 0x0 && _communityAddress != 0x0 && _founderAddress != 0x0);

         
        if (asideTokensHaveBeenMinted) { revert(); }

        reserveAddress = _reserveAddress;
        communityAddress = _communityAddress;
        vestedAddress = _founderAddress;
    }
    
    function updateCapsAndRate(uint _presaleCapInETH, uint _round1CapInETH, uint _softCapInETH, uint _rateETH_BCDT) public onlyOwner inStateInit {
            
         
        require(_round1CapInETH > _presaleCapInETH);
        require(_rateETH_BCDT != 0);
        
        presaleCap = _presaleCapInETH * 1 ether;
        round1Cap = _round1CapInETH * 1 ether;
        softCap = _softCapInETH * 1 ether;
        rateETH_BCDT = _rateETH_BCDT;
    }
    
    function getRemainingEthersForCurrentRound() public constant returns (uint) {
        require(currentState != State.Init); 
        require(!asideTokensHaveBeenMinted);
        
        if((currentState == State.PresaleRunning) || (currentState == State.PresaleFinished)) {
             
            return presaleCap.sub(etherRaisedDuringICO);
        }
        if((currentState == State.Round1Running) || (currentState == State.Round1Finished)) {
             
            return round1Cap.sub(etherRaisedDuringICO);
        }
        if((currentState == State.Round2Running) || (currentState == State.Round2Finished)) {
             
            uint256 remainingTokens = totalSupply.sub(tokensSold);
             
            return remainingTokens.div(rateETH_BCDT);
        }        
    }   

    function getBCDTRateForCurrentRound() public constant returns (uint) {
        require(currentState == State.PresaleRunning || currentState == State.Round1Running || currentState == State.Round2Running);              
        
         
        if(currentState == State.PresaleRunning) {
            return rateETH_BCDT + rateETH_BCDT * 20 / 100;
        }
         
        if(currentState == State.Round1Running) {
            return rateETH_BCDT + rateETH_BCDT * 10 / 100;
        }
        if(currentState == State.Round2Running) {
            return rateETH_BCDT;
        }        
    }  

    function setState(State _newState) public onlyOwner {
        privateSetState(_newState);
    }
    
    function privateSetState(State _newState) private {
         
        if(_newState <= currentState) { revert(); }
        
        currentState = _newState;
        StateChanged(now, currentState);
    }
    
    
    function getEndedStateForCurrentRound() private constant returns (State) {
        require(currentState == State.PresaleRunning || currentState == State.Round1Running || currentState == State.Round2Running);
        
        if(currentState == State.PresaleRunning) {
            return State.PresaleFinished;
        }
        if(currentState == State.Round1Running) {
            return State.Round1Finished;
        }
        if(currentState == State.Round2Running) {
            return State.Round2Finished;
        }        
    }   

    function setAllocation(address _to, uint _ratio) private onlyOwner returns (uint256) {
         
        uint256 tokenAmountToTransfert = totalSupply.mul(_ratio).div(1000);
        balances[_to] = balances[_to].add(tokenAmountToTransfert);
        AsideTokensHaveBeenAllocated(_to, tokenAmountToTransfert);
        Transfer(0x0, _to, tokenAmountToTransfert);
        return tokenAmountToTransfert;
    }
}