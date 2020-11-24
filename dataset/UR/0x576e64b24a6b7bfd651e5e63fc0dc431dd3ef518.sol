 

pragma solidity ^0.5.5;
pragma experimental ABIEncoderV2;

contract IParityRegistry {
    mapping (bytes4 => string) public entries;
    
    function register(string memory _method)
    public
    returns (bool);
}

contract MassParityRegistry {
    address constant internal PARITY_ADDRESS = 0x44691B39d1a75dC4E0A0346CBB15E310e6ED1E86;
    
    function getEntries(bytes4[] memory selectors) 
    public
    view
    returns (string[] memory)
    {
        string[] memory entries = new string[](selectors.length);
        for (uint256 i = 0; i != selectors.length; i++) {
            entries[i] = IParityRegistry(PARITY_ADDRESS).entries(selectors[i]);
        }
        return entries;
    }
    
    function registerSignatures(string[] memory signatures) 
    public
    returns (bool[] memory)
    {
        bool[] memory entries = new bool[](signatures.length);
        for (uint256 i = 0; i != signatures.length; i++) {
            entries[i] = IParityRegistry(PARITY_ADDRESS).register(signatures[i]);
        }
        return entries;
    }
}