 
contract TokenProxy is UpgradeabilityProxy, Ownable {
    TokenStorage private dataStore;


    constructor(address _implementation, address storageAddress)
    UpgradeabilityProxy(_implementation)
    public {
        _owner = msg.sender;
        dataStore = TokenStorage(storageAddress);
    }

     
    function upgradeTo(address newImplementation) public onlyOwner {
        _upgradeTo(newImplementation);
    }

     
    function implementation() public view returns (address) {
        return _implementation();
    }
}