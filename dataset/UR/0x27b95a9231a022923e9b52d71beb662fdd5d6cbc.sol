 

pragma solidity 0.4.24;

contract ItemsStorage {

     

    uint256[] private ships;
    uint256[] private radars;
    uint256[] private scanners;
    uint256[] private droids;
    uint256[] private engines;
    uint256[] private fuels;
    uint256[] private generators;
    uint256[] private guns;
    uint256[] private microModules;
    uint256[] private artefacts;

    uint256[] private usersShips;
    uint256[] private usersRadars;
    uint256[] private usersScanners;
    uint256[] private usersDroids;
    uint256[] private usersEngines;
    uint256[] private usersFuels;
    uint256[] private usersGenerators;
    uint256[] private usersGuns;
    uint256[] private usersMicroModules;
    uint256[] private usersArtefacts;

    address private ownerOfItemsStorage;
    address private logicContractAddress;
    address private eternalStorageContractAddress;

    constructor() public {
        ownerOfItemsStorage = msg.sender;
    }

     

    modifier onlyOwnerOfItemsStorage() {
        require(msg.sender == ownerOfItemsStorage);
        _;
    }

    modifier onlyLogicContract() {
        require(msg.sender == logicContractAddress);
        _;
    }

    modifier onlyEternalStorageContract() {
        require(msg.sender == eternalStorageContractAddress);
        _;
    }

     

    function _compareStrings (string _string1, string _string2) private pure returns (bool) {
       return keccak256(abi.encodePacked(_string1)) == keccak256(abi.encodePacked(_string2));
    }

    function addItem(string _itemType) public onlyEternalStorageContract returns(uint256) {

        uint256 newItemId;
        if (_compareStrings(_itemType, "ship")) {
            newItemId = usersShips.length + 1;
            usersShips.push(newItemId);
        } else if (_compareStrings(_itemType, "radar")) {
            newItemId = usersRadars.length + 1;
            usersRadars.push(newItemId);
        } else if (_compareStrings(_itemType, "scanner")) {
            newItemId = usersScanners.length + 1;
            usersScanners.push(newItemId);
        } else if (_compareStrings(_itemType, "droid")) {
            newItemId = usersDroids.length + 1;
            usersDroids.push(newItemId);
        } else if (_compareStrings(_itemType, "engine")) {
            newItemId = usersEngines.length + 1;
            usersEngines.push(newItemId);
        } else if (_compareStrings(_itemType, "fuel")) {
            newItemId = usersFuels.length + 1;
            usersFuels.push(newItemId);
        } else if (_compareStrings(_itemType, "generator")) {
            newItemId = usersGenerators.length + 1;
            usersGenerators.push(newItemId);
        } else if (_compareStrings(_itemType, "gun")) {
            newItemId = usersGuns.length + 1;
            usersGuns.push(newItemId);
        } else if (_compareStrings(_itemType, "microModule")) {
            newItemId = usersMicroModules.length + 1;
            usersMicroModules.push(newItemId);
        }

        return newItemId;
    }

     

    function getUsersShipsIds() public onlyLogicContract view returns(uint256[]) {
        return usersShips;
    }

    function getUsersRadarsIds() public onlyLogicContract view returns(uint256[]) {
        return usersRadars;
    }

    function getUsersScannersIds() public onlyLogicContract view returns(uint256[]) {
        return usersScanners;
    }

    function getUsersDroidsIds() public onlyLogicContract view returns(uint256[]) {
        return usersDroids;
    }

    function getUsersEnginesIds() public onlyLogicContract view returns(uint256[]) {
        return usersEngines;
    }

    function getUsersFuelsIds() public onlyLogicContract view returns(uint256[]) {
        return usersFuels;
    }

    function getUsersGeneratorsIds() public onlyLogicContract view returns(uint256[]) {
        return usersGenerators;
    }

    function getUsersGunsIds() public onlyLogicContract view returns(uint256[]) {
        return usersGuns;
    }

    function getUsersMicroModulesIds() public onlyLogicContract view returns(uint256[]) {
        return usersMicroModules;
    }

    function getUsersArtefactsIds() public onlyLogicContract view returns(uint256[]) {
        return usersArtefacts;
    }

      


    function getShipsIds() public onlyLogicContract view returns(uint256[]) {
        return ships;
    }

    function getRadarsIds() public onlyLogicContract view returns(uint256[]) {
        return radars;
    }

    function getScannersIds() public onlyLogicContract view returns(uint256[]) {
        return scanners;
    }

    function getDroidsIds() public onlyLogicContract view returns(uint256[]) {
        return droids;
    }

    function getEnginesIds() public onlyLogicContract view returns(uint256[]) {
        return engines;
    }

    function getFuelsIds() public onlyLogicContract view returns(uint256[]) {
        return fuels;
    }

    function getGeneratorsIds() public onlyLogicContract view returns(uint256[]) {
        return generators;
    }

    function getGunsIds() public onlyLogicContract view returns(uint256[]) {
        return guns;
    }

    function getMicroModulesIds() public onlyLogicContract view returns(uint256[]) {
        return microModules;
    }

    function getArtefactsIds() public onlyLogicContract view returns(uint256[]) {
        return artefacts;
    }
    
     

     
    function createShip(uint256 _shipId) public onlyEternalStorageContract {
        ships.push(_shipId);
    }

     
    function createRadar(uint256 _radarId) public onlyEternalStorageContract {
        radars.push(_radarId);
    }

     
    function createScanner(uint256 _scannerId) public onlyEternalStorageContract {
        scanners.push(_scannerId);
    }

     
    function createDroid(uint256 _droidId) public onlyEternalStorageContract {
        droids.push(_droidId);
    }

     
    function createFuel(uint256 _fuelId) public onlyEternalStorageContract {
        fuels.push(_fuelId);
    }

     
    function createGenerator(uint256 _generatorId) public onlyEternalStorageContract {
        generators.push(_generatorId);
    }

     
    function createEngine(uint256 _engineId) public onlyEternalStorageContract {
        engines.push(_engineId);
    }

     
    function createGun(uint256 _gunId) public onlyEternalStorageContract {
        guns.push(_gunId);
    }

     
    function createMicroModule(uint256 _microModuleId) public onlyEternalStorageContract {
        microModules.push(_microModuleId);
    }

     
    function createArtefact(uint256 _artefactId) public onlyEternalStorageContract {
        artefacts.push(_artefactId);
    }


     

    function transferOwnershipOfItemsStorage(address _newOwnerOfItemsStorage) public onlyOwnerOfItemsStorage {
        _transferOwnershipOfItemsStorage(_newOwnerOfItemsStorage);
    }

    function _transferOwnershipOfItemsStorage(address _newOwnerOfItemsStorage) private {
        require(_newOwnerOfItemsStorage != address(0));
        ownerOfItemsStorage = _newOwnerOfItemsStorage;
    }

     

    function changeLogicContractAddress(address _newLogicContractAddress) public onlyOwnerOfItemsStorage {
        _changeLogicContractAddress(_newLogicContractAddress);
    }

    function _changeLogicContractAddress(address _newLogicContractAddress) private {
        require(_newLogicContractAddress != address(0));
        logicContractAddress = _newLogicContractAddress;
    }

     

    function changeEternalStorageContractAddress(address _newEternalStorageContractAddress) public onlyOwnerOfItemsStorage {
        _changeEternalStorageContractAddress(_newEternalStorageContractAddress);
    }

    function _changeEternalStorageContractAddress(address _newEternalStorageContractAddress) private {
        require(_newEternalStorageContractAddress != address(0));
        eternalStorageContractAddress = _newEternalStorageContractAddress;
    }
}