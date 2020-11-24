 

pragma solidity ^0.4.11;

contract ForklogBlockstarter {
    
    string public constant contract_md5 = "847df4b1ba31f28b9399b52d784e4a8e";
    string public constant contract_sha256 = "cd195ff7ac4743a1c878f0100e138e36471bb79c0254d58806b8244080979116";
    
    mapping (address => bool) private signs;

    address private alex = 0x8D5bd2aBa04A07Bfa0cc976C73eD45B23cC6D6a2;
    address private andrey = 0x688d12D97D0E480559B6bEB6EE9907B625c14Adb;
    address private toly = 0x34972356Af9B8912c1DC2737fd43352A8146D23D;
    address private eugene = 0x259BBd479Bd174129a3ccb007f608D52cd2630e9;

     
    function() {
        sing();
    }
    
    function sing() {
        singBy(msg.sender);
    }
    
    function singBy(address signer) {
        if (isSignedBy(signer)) return;
        signs[signer] = true;
    }
    
    function isSignedBy(address signer) constant returns (bool) {
        return signs[signer] == true;
    }
    
    function isSignedByAlex() constant returns (bool) {
        return isSignedBy(alex);
    }
    
    function isSignedByAndrey() constant returns (bool) {
        return isSignedBy(andrey);
    }
    
    function isSignedByToly() constant returns (bool) {
        return isSignedBy(toly);
    }
    
    function isSignedByEugene() constant returns (bool) {
        return isSignedBy(eugene);
    }
    
    function isSignedByAll() constant returns (bool) {
        return (
            isSignedByAlex() && 
            isSignedByAndrey() && 
            isSignedByToly() && 
            isSignedByEugene()
        );
    }
}

 