 

pragma solidity ^0.4.23;

interface P3D {
  function() payable external;
  function buy(address _playerAddress) payable external returns(uint256);
  function sell(uint256 _amountOfTokens) external;
  function reinvest() external;
  function withdraw() external;
  function exit() external;
  function dividendsOf(address _playerAddress) external view returns(uint256);
  function balanceOf(address _playerAddress) external view returns(uint256);
  function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
  function stakingRequirement() external view returns(uint256);
  function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

contract ProxyCrop {
    address public owner;
    bool public disabled;

    constructor(address _owner, address _referrer) public payable {
      owner = _owner;

       
      if (msg.value > 0) {
        P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).buy.value(msg.value)(_referrer);
      }
    }

    function() public payable {
      assembly {
         
         
         
        calldatacopy(0, 0, calldatasize)

         
         
        let result := delegatecall(gas, 0x0D6C969d0004B431189f834203CE0f5530e06259, 0, calldatasize, 0, 0)

         
        returndatacopy(0, 0, returndatasize)

        switch result
         
        case 0 { revert(0, returndatasize) }
        default { return(0, returndatasize) }
      }
    }
}