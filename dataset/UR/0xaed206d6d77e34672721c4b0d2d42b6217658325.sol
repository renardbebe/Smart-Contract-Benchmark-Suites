 

pragma solidity ^0.4.18;

 

contract RDFDM {

   
   
  event FiatCollectedEvent(uint indexed charity, uint usd, string ref);
  event FiatToEthEvent(uint indexed charity, uint usd, uint eth);
  event EthToFiatEvent(uint indexed charity, uint eth, uint usd);
  event FiatDeliveredEvent(uint indexed charity, uint usd, string ref);
  event EthDonationEvent(uint indexed charity, uint eth);

   
   
  event CharityAddedEvent(uint indexed charity, string name, uint8 currency);
  event CharityModifiedEvent(uint indexed charity, string name, uint8 currency);

   
   
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
  address public token;            
  address public operatorFeeAcct;  
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


   
   
   
  function RDFDM() public {
    owner = msg.sender;
    manager = msg.sender;
    token = msg.sender;
    operatorFeeAcct = msg.sender;
  }
  function lock() public ownerOnly { isLocked = true; }
  function setToken(address _token) public ownerOnly unlockedOnly { token = _token; }
  function setOperatorFeeAcct(address _operatorFeeAcct) public ownerOnly { operatorFeeAcct = _operatorFeeAcct; }
  function setManager(address _manager) public managerOnly { manager = _manager; }
  function deleteManager() public managerOnly { manager = owner; }


  function addCharity(string _name, uint8 _currency) public managerOnly {
    charities[charityCount].name = _name;
    charities[charityCount].currency = _currency;
    CharityAddedEvent(charityCount, _name, _currency);
    ++charityCount;
  }

  function modifyCharity(uint _charity, string _name, uint8 _currency) public managerOnly {
    require(_charity < charityCount);
    charities[_charity].name = _name;
    charities[_charity].currency = _currency;
    CharityModifiedEvent(_charity, _name, _currency);
  }



   

  function fiatCollected(uint _charity, uint _fiat, string _ref) public managerOnly {
    require(_charity < charityCount);
    charities[_charity].fiatBalanceIn += _fiat;
    charities[_charity].fiatCollected += _fiat;
    FiatCollectedEvent(_charity, _fiat, _ref);
  }

  function fiatToEth(uint _charity, uint _fiat) public managerOnly payable {
    require(token != 0);
    require(_charity < charityCount);
     
    charities[_charity].fiatToEthPriceAccFiat += _fiat;
    charities[_charity].fiatToEthPriceAccEth += msg.value;
    charities[_charity].fiatBalanceIn -= _fiat;
    uint _tokenCut = (msg.value * 4) / 100;
    uint _operatorCut = (msg.value * 16) / 100;
    uint _charityCredit = (msg.value - _operatorCut) - _tokenCut;
    operatorFeeAcct.transfer(_operatorCut);
    token.transfer(_tokenCut);
    charities[_charity].ethBalance += _charityCredit;
    charities[_charity].ethCredited += _charityCredit;
    FiatToEthEvent(_charity, _fiat, msg.value);
  }

  function ethToFiat(uint _charity, uint _eth, uint _fiat) public managerOnly {
    require(_charity < charityCount);
    require(charities[_charity].ethBalance >= _eth);
     
    charities[_charity].ethToFiatPriceAccFiat += _fiat;
    charities[_charity].ethToFiatPriceAccEth += _eth;
    charities[_charity].ethBalance -= _eth;
    charities[_charity].fiatBalanceOut += _fiat;
     
    msg.sender.transfer(_eth);
    EthToFiatEvent(_charity, _eth, _fiat);
  }

  function fiatDelivered(uint _charity, uint _fiat, string _ref) public managerOnly {
    require(_charity < charityCount);
    require(charities[_charity].fiatBalanceOut >= _fiat);
    charities[_charity].fiatBalanceOut -= _fiat;
    charities[_charity].fiatDelivered += _fiat;
    FiatDeliveredEvent(_charity, _fiat, _ref);
  }

   
  function ethDonation(uint _charity) public payable {
    require(token != 0);
    require(_charity < charityCount);
    uint _tokenCut = (msg.value * 1) / 200;
    uint _operatorCut = (msg.value * 3) / 200;
    uint _charityCredit = (msg.value - _operatorCut) - _tokenCut;
    operatorFeeAcct.transfer(_operatorCut);
    token.transfer(_tokenCut);
    charities[_charity].ethDonated += _charityCredit;
    charities[_charity].ethBalance += _charityCredit;
    charities[_charity].ethCredited += _charityCredit;
    EthDonationEvent(_charity, msg.value);
  }


   
  function fiatCollectedToEth(uint _charity, uint _fiat, string _ref) public managerOnly payable {
    require(token != 0);
    require(_charity < charityCount);
    charities[_charity].fiatCollected += _fiat;
     
     
    charities[_charity].fiatToEthPriceAccFiat += _fiat;
    charities[_charity].fiatToEthPriceAccEth += msg.value;
    uint _tokenCut = (msg.value * 4) / 100;
    uint _operatorCut = (msg.value * 16) / 100;
    uint _charityCredit = (msg.value - _operatorCut) - _tokenCut;
    operatorFeeAcct.transfer(_operatorCut);
    token.transfer(_tokenCut);
    charities[_charity].ethBalance += _charityCredit;
    charities[_charity].ethCredited += _charityCredit;
    FiatCollectedEvent(_charity, _fiat, _ref);
    FiatToEthEvent(_charity, _fiat, msg.value);
  }

  function ethToFiatDelivered(uint _charity, uint _eth, uint _fiat, string _ref) public managerOnly {
    require(_charity < charityCount);
    require(charities[_charity].ethBalance >= _eth);
     
    charities[_charity].ethToFiatPriceAccFiat += _fiat;
    charities[_charity].ethToFiatPriceAccEth += _eth;
    charities[_charity].ethBalance -= _eth;
     
     
    msg.sender.transfer(_eth);
    EthToFiatEvent(_charity, _eth, _fiat);
    charities[_charity].fiatDelivered += _fiat;
    FiatDeliveredEvent(_charity, _fiat, _ref);
  }


   
  function divRound(uint256 _x, uint256 _y) pure internal returns (uint256) {
    uint256 z = (_x + (_y / 2)) / _y;
    return z;
  }

  function quickAuditEthCredited(uint _charityIdx) public constant returns (uint _fiatCollected,
                                                                            uint _fiatToEthNotProcessed,
                                                                            uint _fiatToEthProcessed,
                                                                            uint _fiatToEthPricePerEth,
                                                                            uint _fiatToEthCreditedSzabo,
                                                                            uint _fiatToEthAfterFeesSzabo,
                                                                            uint _ethDonatedSzabo,
                                                                            uint _ethDonatedAfterFeesSzabo,
                                                                            uint _totalEthCreditedSzabo,
                                                                            int _quickDiscrepancy) {
    require(_charityIdx < charityCount);
    Charity storage _charity = charities[_charityIdx];
    _fiatCollected = _charity.fiatCollected;                                                    
    _fiatToEthNotProcessed = _charity.fiatBalanceIn;                                            
    _fiatToEthProcessed = _fiatCollected - _fiatToEthNotProcessed;                              
    if (_charity.fiatToEthPriceAccEth == 0) {
      _fiatToEthPricePerEth = 0;
      _fiatToEthCreditedSzabo = 0;
    } else {
      _fiatToEthPricePerEth = divRound(_charity.fiatToEthPriceAccFiat * (1 ether),              
                                       _charity.fiatToEthPriceAccEth);                          
                                                                                                
                                                                                                
      uint _szaboPerEth = 1 ether / 1 szabo;
      _fiatToEthCreditedSzabo = divRound(_fiatToEthProcessed * _szaboPerEth,                   
                                          _fiatToEthPricePerEth);
      _fiatToEthAfterFeesSzabo = divRound(_fiatToEthCreditedSzabo * 8, 10);                    
    }
    _ethDonatedSzabo = divRound(_charity.ethDonated, 1 szabo);                                 
    _ethDonatedAfterFeesSzabo = divRound(_ethDonatedSzabo * 98, 100);                          
    _totalEthCreditedSzabo = _fiatToEthAfterFeesSzabo + _ethDonatedAfterFeesSzabo;             
    uint256 tecf = divRound(_charity.ethCredited, 1 szabo);                                    
    _quickDiscrepancy = int256(_totalEthCreditedSzabo) - int256(tecf);                         
  }




   
  function quickAuditFiatDelivered(uint _charityIdx) public constant returns (uint _totalEthCreditedSzabo,
                                                                              uint _ethNotProcessedSzabo,
                                                                              uint _processedEthCreditedSzabo,
                                                                              uint _ethToFiatPricePerEth,
                                                                              uint _ethToFiatCreditedFiat,
                                                                              uint _ethToFiatNotProcessed,
                                                                              uint _ethToFiatProcessed,
                                                                              uint _fiatDelivered,
                                                                              int _quickDiscrepancy) {
    require(_charityIdx < charityCount);
    Charity storage _charity = charities[_charityIdx];
    _totalEthCreditedSzabo = divRound(_charity.ethCredited, 1 szabo);                           
    _ethNotProcessedSzabo = divRound(_charity.ethBalance, 1 szabo);                             
    _processedEthCreditedSzabo = _totalEthCreditedSzabo - _ethNotProcessedSzabo;                
    if (_charity.ethToFiatPriceAccEth == 0) {
      _ethToFiatPricePerEth = 0;
      _ethToFiatCreditedFiat = 0;
    } else {
      _ethToFiatPricePerEth = divRound(_charity.ethToFiatPriceAccFiat * (1 ether),              
                                       _charity.ethToFiatPriceAccEth);                          
                                                                                                
                                                                                                
      uint _szaboPerEth = 1 ether / 1 szabo;
      _ethToFiatCreditedFiat = divRound(_processedEthCreditedSzabo * _ethToFiatPricePerEth,     
                                        _szaboPerEth);
    }
    _ethToFiatNotProcessed = _charity.fiatBalanceOut;
    _ethToFiatProcessed = _ethToFiatCreditedFiat - _ethToFiatNotProcessed;
    _fiatDelivered = _charity.fiatDelivered;
    _quickDiscrepancy = int256(_ethToFiatProcessed) - int256(_fiatDelivered);
  }


   
   
   
  function () public payable {
    revert();
  }

   
   
  function haraKiri() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }

}