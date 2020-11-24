 

pragma solidity 0.4.17;

 

contract PreSale {

  address private deployer;

   
  address private FunderSmartTokenAddress = 0x0;
  address private FundersTokenCentral = 0x0;

   
  uint256 public oneEtherIsHowMuchFST = 150;

   
  uint256 public startTime = 1506052800;  
  uint256 public endTime   = 1508731200;  

  uint256 public soldTokenValue = 0;
  uint256 public preSaleHardCap = 330000000 * (10 ** 18) * 2 / 100;  

  event BuyEvent (address buyer, string email, uint256 etherValue, uint256 tokenValue);

  function PreSale () public {
    deployer = msg.sender;
  }

   
  function buyFunderSmartToken (string _email, string _code) payable public returns (bool) {
    require(FunderSmartTokenAddress != 0x0);  
    require(FundersTokenCentral != 0x0);  
    require(msg.value >= 1 ether);  
    require(now >= startTime && now <= endTime);  
    require(soldTokenValue <= preSaleHardCap);  

    uint256 _tokenValue = msg.value * oneEtherIsHowMuchFST;

     
    if (keccak256(_code) == 0xde7683d6497212fbd59b6a6f902a01c91a09d9a070bba7506dcc0b309b358eed) {
      _tokenValue = _tokenValue * 135 / 100;
    }

     
    if (keccak256(_code) == 0x65b236bfb931f493eb9e6f3db8d461f1f547f2f3a19e33a7aeb24c7e297c926a) {
      _tokenValue = _tokenValue * 130 / 100;
    }

     
    if (keccak256(_code) == 0x274125681e11c33f71574f123a20cfd59ed25e64d634078679014fa3a872575c) {
      _tokenValue = _tokenValue * 125 / 100;
    }

     
    if (FunderSmartTokenAddress.call(bytes4(keccak256("transferFrom(address,address,uint256)")), FundersTokenCentral, msg.sender, _tokenValue) != true) {
      revert();
    }

    BuyEvent(msg.sender, _email, msg.value, _tokenValue);

    soldTokenValue = soldTokenValue + _tokenValue;

    return true;
  }

   
  function transferOut (address _to, uint256 _etherValue) public returns (bool) {
    require(msg.sender == deployer);
    _to.transfer(_etherValue);
    return true;
  }

   
  function setFSTAddress (address _funderSmartTokenAddress) public returns (bool) {
    require(msg.sender == deployer);
    FunderSmartTokenAddress = _funderSmartTokenAddress;
    return true;
  }

   
  function setFSTKCentral (address _fundersTokenCentral) public returns (bool) {
    require(msg.sender == deployer);
    FundersTokenCentral = _fundersTokenCentral;
    return true;
  }

  function () public {}

}