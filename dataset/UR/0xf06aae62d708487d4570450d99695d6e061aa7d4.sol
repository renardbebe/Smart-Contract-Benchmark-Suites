 

pragma solidity ^0.4.18;

import './DetailedERC20.sol';
import './MintableToken.sol';
import './ServiceRegistry.sol';
import './RegulatorService.sol';

 
contract RegulatedToken is DetailedERC20, MintableToken {

   
  uint8 constant public RTOKEN_DECIMALS = 18;

   
  event CheckStatus(uint8 reason, address indexed spender, address indexed from, address indexed to, uint256 value);

   
  ServiceRegistry public registry;

   
  function RegulatedToken(ServiceRegistry _registry, string _name, string _symbol) public
    DetailedERC20(_name, _symbol, RTOKEN_DECIMALS)
  {
    require(_registry != address(0));

    registry = _registry;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
      return super.transfer(_to, _value);
  }
 

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (_check(_from, _to, _value)) {
      return super.transferFrom(_from, _to, _value);
    } else {
      return false;
    }
  }

   
  function _check(address _from, address _to, uint256 _value) private returns (bool) {
    var reason = _service().check(this, msg.sender, _from, _to, _value);

    CheckStatus(reason, msg.sender, _from, _to, _value);

    return reason == 0;
  }

   
  function _service() constant public returns (RegulatorService) {
    return RegulatorService(registry.service());
  }
}
