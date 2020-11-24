 

pragma solidity ^0.5.4;

contract Registry {
    address private minter;
    address private core;
    address private oracleAggregator;
    address private syntheticAggregator;
    address private opiumAddress;
    address private tokenSpender;
    address private wethAddress;

    address public initializer;

    modifier onlyInitializer() {
        require(msg.sender == initializer, "REGISTRY:ONLY_INITIALIZER");
        _;
    }

    constructor() public {
        initializer = msg.sender;
    }

     

    function setMinter(address _minter) external onlyInitializer {
        require(minter == address(0), "REGISTRY:ALREADY_SET");
        minter = _minter;
    }

    function setCore(address _core) external onlyInitializer {
        require(core == address(0), "REGISTRY:ALREADY_SET");
        core = _core;
    }

    function setOracleAggregator(address _oracleAggregator) external onlyInitializer {
        require(oracleAggregator == address(0), "REGISTRY:ALREADY_SET");
        oracleAggregator = _oracleAggregator;
    }

    function setSyntheticAggregator(address _syntheticAggregator) external onlyInitializer {
        require(syntheticAggregator == address(0), "REGISTRY:ALREADY_SET");
        syntheticAggregator = _syntheticAggregator;
    }

    function setOpiumAddress(address _opiumAddress) external onlyInitializer {
        require(opiumAddress == address(0), "REGISTRY:ALREADY_SET");
        opiumAddress = _opiumAddress;
    }

    function setTokenSpender(address _tokenSpender) external onlyInitializer {
        require(tokenSpender == address(0), "REGISTRY:ALREADY_SET");
        tokenSpender = _tokenSpender;
    }

    function setWethAddress(address _wethAddress) external onlyInitializer {
        require(wethAddress == address(0), "REGISTRY:ALREADY_SET");
        wethAddress = _wethAddress;
    }

    function changeOpiumAddress(address _opiumAddress) external {
        require(opiumAddress == msg.sender, "REGISTRY:ONLY_OPIUM_ADDRESS_ALLOWED");
        opiumAddress = _opiumAddress;
    }

     

    function getCore() external view returns (address) {
        return core;
    }

    function getMinter() external view returns (address) {
        return minter;
    }

    function getOracleAggregator() external view returns (address) {
        return oracleAggregator;
    }

    function getSyntheticAggregator() external view returns (address) {
        return syntheticAggregator;
    }

    function getOpiumAddress() external view returns (address) {
        return opiumAddress;
    }

    function getTokenSpender() external view returns (address) {
        return tokenSpender;
    }

    function getWethAddress() external view returns (address) {
        return wethAddress;
    }
}