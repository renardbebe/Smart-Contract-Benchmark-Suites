 

pragma solidity ^0.4.2;
 
contract StampdPostHash {
  mapping (string => bool) private stampdLedger;
  function _storeProof(string hashResult) {
    stampdLedger[hashResult] = true;
  }
  function _checkLedger(string hashResult) constant returns (bool) {
    return stampdLedger[hashResult];
  }
  function postProof(string hashResult) {
    _storeProof(hashResult);
  }
  function proofExists(string hashResult) constant returns(bool) {
    return _checkLedger(hashResult);
  }
}