 

pragma solidity 0.4.21;

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) public {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



 
 
contract TeuToken is StandardToken, Ownable{
  string public name = "20-footEqvUnit";
  string public symbol = "TEU";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() public {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

   
  function burn(uint _value) onlyOwner public {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

 
contract teuInitialTokenSale is Ownable {
	using SafeMath for uint256;

    event LogContribution(address indexed _contributor, uint256 _etherAmount, uint256 _basicTokenAmount, uint256 _timeBonusTokenAmount, uint256 _volumeBonusTokenAmount);
    event LogContributionBitcoin(address indexed _contributor, uint256 _bitcoinAmount, uint256 _etherAmount, uint256 _basicTokenAmount, uint256 _timeBonusTokenAmount, uint256 _volumeBonusTokenAmount, uint _contributionDatetime);
    event LogOffChainContribution(address indexed _contributor, uint256 _etherAmount, uint256 _tokenAmount);
    event LogReferralAward(address indexed _refereeWallet, address indexed _referrerWallet, uint256 _referralBonusAmount);
    event LogTokenCollected(address indexed _contributor, uint256 _collectedTokenAmount);
    event LogClientIdentRejectListChange(address indexed _contributor, uint8 _newValue);


    TeuToken			                constant private		token = TeuToken(0xeEAc3F8da16bb0485a4A11c5128b0518DaC81448);  
    address		                        constant private		etherHolderWallet = 0x00222EaD2D0F83A71F645d3d9634599EC8222830;  
    uint256		                        constant private 	    minContribution = 100 finney;
    uint                                         public         saleStart = 1523498400;
    uint                                         public         saleEnd = 1526090400;
    uint                                constant private        etherToTokenConversionRate = 400;
    uint                                constant private        referralAwardPercent = 20;
    uint256                             constant private        maxCollectableToken = 20 * 10 ** 6 * 10 ** 18;

    mapping (address => uint256)                private     referralContribution;   
    mapping (address => uint)                   private     lastContribitionDate;   

    mapping (address => uint256)                private     collectableToken;   
    mapping (address => uint8)                  private     clientIdentRejectList;   
    bool                                        public      isCollectTokenStart = false;   
    bool                                        public      isAllowContribution = true;  
    uint256                                     public      totalCollectableToken;   

     

    

        
    function getCurrentDatetime() private constant returns (uint) {
        return now; 
    }

        
    function getCurrentSaleDay() private saleIsOn returns (uint) {
        return getCurrentDatetime().sub256(saleStart).div256(86400).add256(1);
    }

           
    function getTimeBonusPercent(uint _days) private pure returns (uint) {
        if (_days <= 20)
            return 50;
        return 0;
    }

               
    function getVolumeBonusPercent(uint256 _etherAmount) private pure returns (uint) {

        if (_etherAmount < 1 ether)
            return 0;
        if (_etherAmount < 2 ether)
            return 35;
        if (_etherAmount < 3 ether)
            return 40;
        if (_etherAmount < 4 ether)
            return 45;
        if (_etherAmount < 5 ether)
            return 50;
        if (_etherAmount < 10 ether)
            return 55;
        if (_etherAmount < 20 ether)
            return 60;
        if (_etherAmount < 30 ether)
            return 65;
        if (_etherAmount < 40 ether)
            return 70;
        if (_etherAmount < 50 ether)
            return 75;
        if (_etherAmount < 100 ether)
            return 80;
        if (_etherAmount < 200 ether)
            return 90;
        if (_etherAmount >= 200 ether)
            return 100;
        return 0;
    }
    
      
    function getTimeBonusAmount(uint256 _tokenAmount) private returns (uint256) {
        return _tokenAmount.mul256(getTimeBonusPercent(getCurrentSaleDay())).div256(100);
    }
    
     
    function getVolumeBonusAmount(uint256 _tokenAmount, uint256 _etherAmount) private returns (uint256) {
        return _tokenAmount.mul256(getVolumeBonusPercent(_etherAmount)).div256(100);
    }
    
     
    function getReferralBonusAmount(uint256 _etherAmount) private returns (uint256) {
        return _etherAmount.mul256(etherToTokenConversionRate).mul256(referralAwardPercent).div256(100);
    }
    
     
    function getBasicTokenAmount(uint256 _etherAmount) private returns (uint256) {
        return _etherAmount.mul256(etherToTokenConversionRate);
    }
  
  
     

     
    modifier saleIsOn() {
        require(getCurrentDatetime() >= saleStart && getCurrentDatetime() < saleEnd);
        _;
    }

         
    modifier saleIsEnd() {
        require(getCurrentDatetime() >= saleEnd);
        _;
    }

         
    modifier tokenIsCollectable() {
        require(isCollectTokenStart);
        _;
    }
    
         
    modifier overMinContribution(uint256 _etherAmount) {
        require(_etherAmount >= minContribution);
        _;
    }
    
     
    modifier underMaxTokenPool() {
        require(maxCollectableToken > totalCollectableToken);
        _;
    }

     
    modifier contributionAllowed() {
        require(isAllowContribution);
        _;
    }


     
     
    function setNewStart(uint _newStart) public onlyOwner {
	require(saleStart > getCurrentDatetime());
        require(_newStart > getCurrentDatetime());
	require(saleEnd > _newStart);
        saleStart = _newStart;
    }

     
    function setNewEnd(uint _newEnd) public onlyOwner {
	require(saleEnd < getCurrentDatetime());
        require(_newEnd < getCurrentDatetime());
	require(_newEnd > saleStart);
        saleEnd = _newEnd;
    }

     
    function enableContribution(bool _isAllow) public onlyOwner {
        isAllowContribution = _isAllow;
    }


     
    function contribute() public payable saleIsOn overMinContribution(msg.value) underMaxTokenPool contributionAllowed {
        uint256 _basicToken = getBasicTokenAmount(msg.value);
        uint256 _timeBonus = getTimeBonusAmount(_basicToken);
        uint256 _volumeBonus = getVolumeBonusAmount(_basicToken, msg.value);
        uint256 _totalToken = _basicToken.add256(_timeBonus).add256(_volumeBonus);
        
        lastContribitionDate[msg.sender] = getCurrentDatetime();
        referralContribution[msg.sender] = referralContribution[msg.sender].add256(msg.value);
        
        collectableToken[msg.sender] = collectableToken[msg.sender].add256(_totalToken);
        totalCollectableToken = totalCollectableToken.add256(_totalToken);
        assert(etherHolderWallet.send(msg.value));

        LogContribution(msg.sender, msg.value, _basicToken, _timeBonus, _volumeBonus);
    }

     
    function contributeByBitcoin(uint256 _bitcoinAmount, uint256 _etherAmount, address _contributorWallet, uint _contributionDatetime) public overMinContribution(_etherAmount) onlyOwner contributionAllowed {
        require(_contributionDatetime <= getCurrentDatetime());

        uint256 _basicToken = getBasicTokenAmount(_etherAmount);
        uint256 _timeBonus = getTimeBonusAmount(_basicToken);
        uint256 _volumeBonus = getVolumeBonusAmount(_basicToken, _etherAmount);
        uint256 _totalToken = _basicToken.add256(_timeBonus).add256(_volumeBonus);
        
	    if (_contributionDatetime > lastContribitionDate[_contributorWallet])
            lastContribitionDate[_contributorWallet] = _contributionDatetime;
        referralContribution[_contributorWallet] = referralContribution[_contributorWallet].add256(_etherAmount);
    
        collectableToken[_contributorWallet] = collectableToken[_contributorWallet].add256(_totalToken);
        totalCollectableToken = totalCollectableToken.add256(_totalToken);
        LogContributionBitcoin(_contributorWallet, _bitcoinAmount, _etherAmount, _basicToken, _timeBonus, _volumeBonus, _contributionDatetime);
    }
    
     
    function recordOffChainContribute(uint256 _etherAmount, address _contributorWallet, uint256 _tokenAmount) public overMinContribution(_etherAmount) onlyOwner {

        lastContribitionDate[_contributorWallet] = getCurrentDatetime();
        LogOffChainContribution(_contributorWallet, _etherAmount, _tokenAmount);
    }    

     
    function migrateContributors(address[] _contributorWallets) public onlyOwner {
	for (uint i = 0; i < _contributorWallets.length; i++) {
        	lastContribitionDate[_contributorWallets[i]] = getCurrentDatetime();
	}
    }  

     
    function referral(address _referrerWallet) public {
	require (msg.sender != _referrerWallet);
        require (referralContribution[msg.sender] > 0);
        require (lastContribitionDate[_referrerWallet] > 0);
        require (getCurrentDatetime() - lastContribitionDate[msg.sender] <= (4 * 24 * 60 * 60));
        
        uint256 _referralBonus = getReferralBonusAmount(referralContribution[msg.sender]);
        referralContribution[msg.sender] = 0;
        
        collectableToken[msg.sender] = collectableToken[msg.sender].add256(_referralBonus);
        collectableToken[_referrerWallet] = collectableToken[_referrerWallet].add256(_referralBonus);
        totalCollectableToken = totalCollectableToken.add256(_referralBonus).add256(_referralBonus);
        LogReferralAward(msg.sender, _referrerWallet, _referralBonus);
    }
    
     
    function setClientIdentRejectList(address[] _clients, uint8 _valueToSet) public onlyOwner {
        for (uint i = 0; i < _clients.length; i++) {
            if (_clients[i] != address(0) && clientIdentRejectList[_clients[i]] != _valueToSet) {
                clientIdentRejectList[_clients[i]] = _valueToSet;
                LogClientIdentRejectListChange(_clients[i], _valueToSet);
            }
        }
    }
    
     
    function setTokenCollectable(bool _enable) public onlyOwner saleIsEnd {
        isCollectTokenStart = _enable;
    }
    
     
    function collectToken() public tokenIsCollectable {
	uint256 _collToken = collectableToken[msg.sender];

	require(clientIdentRejectList[msg.sender] <= 0);
        require(_collToken > 0);

        collectableToken[msg.sender] = 0;

        token.transfer(msg.sender, _collToken);
        LogTokenCollected(msg.sender, _collToken);
    }

       
    function transferTokenOut(address _to, uint256 _amount) public onlyOwner {
        token.transfer(_to, _amount);
    }
    
       
    function transferEtherOut(address _to, uint256 _amount) public onlyOwner {
        assert(_to.send(_amount));
    }  
    

     

       
    function collectableTokenOf(address _contributor) public constant returns (uint256) {
        return collectableToken[_contributor] ;
    }
    
       
    function isClientIdentRejectedOf(address _contributor) public constant returns (uint8) {
        return clientIdentRejectList[_contributor];
    }    
    
     
    function() external payable {
        contribute();
    }

}