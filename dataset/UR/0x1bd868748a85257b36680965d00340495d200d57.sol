 

pragma solidity 0.5.9;

 
contract BatchAttestationLogic {
  event BatchTraitAttested(
    bytes32 rootHash
    );

   
  function batchAttest(
    bytes32 _dataHash
  ) external {
    emit BatchTraitAttested(_dataHash);
  }
}