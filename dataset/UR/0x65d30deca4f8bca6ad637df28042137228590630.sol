 

 


pragma solidity ^0.4.24;

 

 
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

 

 
contract IRatesProvider {
  function rateWEIPerCHFCent() public view returns (uint256);
  function convertWEIToCHFCent(uint256 _amountWEI)
    public view returns (uint256);

  function convertCHFCentToWEI(uint256 _amountCHFCent)
    public view returns (uint256);
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract Authority is Ownable {

  address authority;

   
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

   
  function authorityAddress() public view returns (address) {
    return authority;
  }

   
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

 

 
contract RatesProvider is IRatesProvider, Authority {
  using SafeMath for uint256;

   
  uint256 public rateWEIPerCHFCent;

   
  constructor() public {
  }

   
  function convertRateFromETHCHF(
    uint256 _rateETHCHF,
    uint256 _rateETHCHFDecimal)
    public pure returns (uint256)
  {
    if (_rateETHCHF == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateETHCHF);
  }

   
  function convertRateToETHCHF(
    uint256 _rateWEIPerCHFCent,
    uint256 _rateETHCHFDecimal)
    public pure returns (uint256)
  {
    if (_rateWEIPerCHFCent == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateWEIPerCHFCent);
  }

   
  function convertCHFCentToWEI(uint256 _amountCHFCent)
    public view returns (uint256)
  {
    return _amountCHFCent.mul(rateWEIPerCHFCent);
  }

   
  function convertWEIToCHFCent(uint256 _amountETH)
    public view returns (uint256)
  {
    if (rateWEIPerCHFCent == 0) {
      return 0;
    }

    return _amountETH.div(rateWEIPerCHFCent);
  }

   
  function rateWEIPerCHFCent() public view returns (uint256) {
    return rateWEIPerCHFCent;
  }
  
   
  function rateETHCHF(uint256 _rateETHCHFDecimal)
    public view returns (uint256)
  {
    return convertRateToETHCHF(rateWEIPerCHFCent, _rateETHCHFDecimal);
  }

   
  function defineRate(uint256 _rateWEIPerCHFCent)
    public onlyAuthority
  {
    rateWEIPerCHFCent = _rateWEIPerCHFCent;
    emit Rate(currentTime(), _rateWEIPerCHFCent);
  }

   
  function defineETHCHFRate(uint256 _rateETHCHF, uint256 _rateETHCHFDecimal)
    public onlyAuthority
  {
     
    defineRate(convertRateFromETHCHF(_rateETHCHF, _rateETHCHFDecimal));
  }

   
  function currentTime() private view returns (uint256) {
     
    return now;
  }

  event Rate(uint256 at, uint256 rateWEIPerCHFCent);
}