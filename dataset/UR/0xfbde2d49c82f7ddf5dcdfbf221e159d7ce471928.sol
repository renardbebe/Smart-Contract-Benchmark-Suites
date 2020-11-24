 

pragma solidity ^0.4.15;

 

 
 
contract RDFDM {

   
   
  event FiatCollectedEvent(uint indexed charity, uint usd, uint ref);
  event FiatToEthEvent(uint indexed charity, uint usd, uint eth);
  event EthToFiatEvent(uint indexed charity, uint eth, uint usd);
  event FiatDeliveredEvent(uint indexed charity, uint usd, uint ref);
  event EthDonationEvent(uint indexed charity, uint eth);

   
   
  event CharityAddedEvent(uint indexed charity, string name, uint8 currency);

   
   
  uint constant  CURRENCY_USD  = 0x01;
  uint constant  CURRENCY_EURO = 0x02;
  uint constant  CURRENCY_NIS  = 0x03;
  uint constant  CURRENCY_YUAN = 0x04;


  struct Charity {
    uint fiatBalanceIn;           
    uint fiatBalanceOut;          
    uint fiatCollected;           
    uint fiatDelivered;           
    uint ethDonated;              
    uint ethCredited;             
    uint ethBalance;              
    uint fiatToEthPriceAccEth;    
    uint fiatToEthPriceAccFiat;   
    uint ethToFiatPriceAccEth;    
    uint ethToFiatPriceAccFiat;   
    uint8 currency;               
    string name;                  
  }

  uint public charityCount;
  address public owner;
  address public manager;
  address public operator;        
  address public token;           
  mapping (uint => Charity) public charities;
  bool public isLocked;

  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  modifier managerOnly {
    require(msg.sender == owner || msg.sender == manager);
    _;
  }

  modifier unlockedOnly {
    require(!isLocked);
    _;
  }


   
   
   
  function RDFDM() {
    owner = msg.sender;
    manager = msg.sender;
  }
  function lock() public ownerOnly {
    isLocked = true;
  }
  function setOperator(address _operator) public ownerOnly { operator = _operator; }
  function setManager(address _manager) public managerOnly { manager = _manager; }
  function deleteManager() public managerOnly { manager = owner; }


  function addCharity(string _name, uint8 _currency) public managerOnly {
    charities[charityCount].name = _name;
    charities[charityCount].currency = _currency;
    CharityAddedEvent(charityCount, _name, _currency);
    ++charityCount;
  }



   

  function fiatCollected(uint _charity, uint _fiat, uint _ref) public managerOnly {
    require(_charity < charityCount);
    charities[charityCount].fiatBalanceIn += _fiat;
    charities[charityCount].fiatCollected += _fiat;
    FiatCollectedEvent(_charity, _fiat, _ref);
  }

  function fiatToEth(uint _charity, uint _fiat) public managerOnly payable {
    require(_charity < charityCount);
     
    charities[charityCount].fiatToEthPriceAccFiat += _fiat;
    charities[charityCount].fiatToEthPriceAccEth += msg.value;
    charities[charityCount].fiatBalanceIn -= _fiat;
    uint _tokenCut = (msg.value * 4) / 100;
    uint _operatorCut = (msg.value * 16) / 100;
    uint _charityCredit = (msg.value - _operatorCut) - _tokenCut;
    operator.transfer(_operatorCut);
    token.transfer(_tokenCut);
    charities[charityCount].ethBalance += _charityCredit;
    charities[charityCount].ethCredited += _charityCredit;
    FiatToEthEvent(_charity, _fiat, msg.value);
  }

  function ethToFiat(uint _charity, uint _eth, uint _fiat) public managerOnly {
    require(_charity < charityCount);
    require(charities[_charity].ethBalance >= _eth);
     
    charities[charityCount].ethToFiatPriceAccFiat += _fiat;
    charities[charityCount].ethToFiatPriceAccEth += _eth;
    charities[charityCount].ethBalance -= _eth;
    charities[charityCount].fiatBalanceOut += _fiat;
     
    msg.sender.transfer(_eth);
    EthToFiatEvent(_charity, _eth, _fiat);
  }

  function fiatDelivered(uint _charity, uint _fiat, uint _ref) public managerOnly {
    require(_charity < charityCount);
    require(charities[_charity].fiatBalanceOut >= _fiat);
    charities[_charity].fiatBalanceOut -= _fiat;
    charities[charityCount].fiatDelivered += _fiat;
    FiatDeliveredEvent(_charity, _fiat, _ref);
  }

   
  function ethDonation(uint _charity) public payable {
    require(_charity < charityCount);
    uint _tokenCut = (msg.value * 1) / 200;
    uint _operatorCut = (msg.value * 3) / 200;
    uint _charityCredit = (msg.value - _operatorCut) - _tokenCut;
    operator.transfer(_operatorCut);
    token.transfer(_tokenCut);
    charities[charityCount].ethDonated += _charityCredit;
    charities[charityCount].ethBalance += _charityCredit;
    charities[charityCount].ethCredited += _charityCredit;
    EthDonationEvent(_charity, msg.value);
  }


   
  function fiatCollectedToEth(uint _charity, uint _fiat, uint _ref) public managerOnly payable {
    require(token != 0);
    require(_charity < charityCount);
    charities[charityCount].fiatCollected += _fiat;
     
     
    charities[charityCount].fiatToEthPriceAccFiat += _fiat;
    charities[charityCount].fiatToEthPriceAccEth += msg.value;
    uint _tokenCut = (msg.value * 4) / 100;
    uint _operatorCut = (msg.value * 16) / 100;
    uint _charityCredit = (msg.value - _operatorCut) - _tokenCut;
    operator.transfer(_operatorCut);
    token.transfer(_tokenCut);
    charities[charityCount].ethBalance += _charityCredit;
    charities[charityCount].ethCredited += _charityCredit;
    FiatCollectedEvent(_charity, _fiat, _ref);
    FiatToEthEvent(_charity, _fiat, msg.value);
  }

  function ethToFiatDelivered(uint _charity, uint _eth, uint _fiat, uint _ref) public managerOnly {
    require(_charity < charityCount);
    require(charities[_charity].ethBalance >= _eth);
     
    charities[charityCount].ethToFiatPriceAccFiat += _fiat;
    charities[charityCount].ethToFiatPriceAccEth += _eth;
    charities[charityCount].ethBalance -= _eth;
     
     
    msg.sender.transfer(_eth);
    EthToFiatEvent(_charity, _eth, _fiat);
    charities[charityCount].fiatDelivered += _fiat;
    FiatDeliveredEvent(_charity, _fiat, _ref);
  }


   
  function quickAuditEthCredited(uint _charity) public constant returns (uint _fiatCollected,
                                                              uint _fiatToEthNotProcessed,
                                                              uint _fiatToEthProcessed,
                                                              uint _fiatToEthPricePerEth,
                                                              uint _fiatToEthCreditedFinney,
                                                              uint _fiatToEthAfterFeesFinney,
                                                              uint _ethDonatedFinney,
                                                              uint _ethDonatedAfterFeesFinney,
                                                              uint _totalEthCreditedFinney,
                                                               int _quickDiscrepancy) {
    require(_charity < charityCount);
    _fiatCollected = charities[charityCount].fiatCollected;                                                 
    _fiatToEthNotProcessed = charities[charityCount].fiatBalanceIn;                                         
    _fiatToEthProcessed = _fiatCollected - _fiatToEthNotProcessed;                                          
    if (charities[charityCount].fiatToEthPriceAccEth == 0) {
      _fiatToEthPricePerEth = 0;
      _fiatToEthCreditedFinney = 0;
    } else {
      _fiatToEthPricePerEth = (charities[charityCount].fiatToEthPriceAccFiat * (1 ether)) /                 
                               charities[charityCount].fiatToEthPriceAccEth;                                
                                                                                                            
                                                                                                            
      _fiatToEthCreditedFinney = _fiatToEthProcessed * (1 ether / 1 finney) / _fiatToEthPricePerEth;        
      _fiatToEthAfterFeesFinney = _fiatToEthCreditedFinney * 8 / 10;                                        
    }
    _ethDonatedFinney = charities[charityCount].ethDonated / (1 finney);                                    
    _ethDonatedAfterFeesFinney = _ethDonatedFinney * 98 / 100;                                              
    _totalEthCreditedFinney = _fiatToEthAfterFeesFinney + _ethDonatedAfterFeesFinney;                       
    uint256 tecf = charities[charityCount].ethCredited * (1 ether / 1 finney);
    _quickDiscrepancy = int256(_totalEthCreditedFinney) - int256(tecf);
  }


   
  function quickAuditFiatDelivered(uint _charity) public constant returns (
                                                              uint _totalEthCreditedFinney,
                                                              uint _ethNotProcessedFinney,
                                                              uint _processedEthCreditedFinney,
                                                              uint _ethToFiatPricePerEth,
                                                              uint _ethToFiatCreditedFiat,
                                                              uint _ethToFiatNotProcessed,
                                                              uint _ethToFiatProcessed,
                                                              uint _fiatDelivered,
                                                               int _quickDiscrepancy) {
    require(_charity < charityCount);
    _totalEthCreditedFinney = charities[charityCount].ethCredited * (1 ether / 1 finney);
    _ethNotProcessedFinney = charities[charityCount].ethBalance / (1 finney);                               
    _processedEthCreditedFinney = _totalEthCreditedFinney - _ethNotProcessedFinney;                         
    if (charities[charityCount].ethToFiatPriceAccEth == 0) {
      _ethToFiatPricePerEth = 0;
      _ethToFiatCreditedFiat = 0;
    } else {
      _ethToFiatPricePerEth = (charities[charityCount].ethToFiatPriceAccFiat * (1 ether)) /                 
                               charities[charityCount].ethToFiatPriceAccEth;                                
                                                                                                            
                                                                                                            
      _ethToFiatCreditedFiat = _processedEthCreditedFinney * _ethToFiatPricePerEth / (1 ether / 1 finney);  
    }
    _ethToFiatNotProcessed = charities[_charity].fiatBalanceOut;
    _ethToFiatProcessed = _ethToFiatCreditedFiat - _ethToFiatNotProcessed;
    _fiatDelivered = charities[charityCount].fiatDelivered;
    _quickDiscrepancy = int256(_ethToFiatProcessed) - int256(_fiatDelivered);
  }


   
   
   
  function () payable {
    revert();
  }

   
   
  function haraKiri() ownerOnly unlockedOnly {
    selfdestruct(owner);
  }

}