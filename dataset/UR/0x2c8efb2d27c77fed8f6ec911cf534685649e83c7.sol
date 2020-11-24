 

pragma solidity ^0.5.8;

 
contract FactoryStorage {

     

    event NewPositionContract(
        address userAddress,
        address newPositionContractAddress,
        address factoryLogicAddress
    );

    event NewTokenAddedToPositionContract(
        string ticker,
        address tokenAddr,
        address cTokenAddr,
        address exchangeAddr
    );

    event UserAdded(
        address userAddr
    );

    event TickerAdded(
        string ticker
    );

    event FactoryLogicChanged(
        address factoryLogicAddr
    );

     
     
     
    mapping (string => mapping (address => address)) public positionContracts;

     
    mapping (string => address) public tokenAddresses;
    mapping (string => address) public ctokenAddresses;
    mapping (string => address) public exchangeAddresses;

     

    address public factoryLogicAddress;

     
    address[3] public ownerAddresses;

     
    address[] public userAddresses;
    string[] public tickers;

     
    mapping (address => bool) public userAddressesSet;
    mapping (string => bool) public tickerSet;

     
    constructor(address owner1, address owner2) public {
         
        ownerAddresses[0] = msg.sender;
        ownerAddresses[1] = owner1;
        ownerAddresses[2] = owner2;

        tickers = ['DAI','ZRX','BAT','ETH'];
        tickerSet['DAI'] = true;
        tickerSet['ZRX'] = true;
        tickerSet['BAT'] = true;
        tickerSet['ETH'] = true;

         
        tokenAddresses['DAI'] = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
        tokenAddresses['BAT'] = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
        tokenAddresses['ZRX'] = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
        tokenAddresses['REP'] = 0x1985365e9f78359a9B6AD760e32412f4a445E862;

        ctokenAddresses['DAI'] = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;
        ctokenAddresses['BAT'] = 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E;
        ctokenAddresses['ZRX'] = 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407;
        ctokenAddresses['REP'] = 0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1;
        ctokenAddresses['ETH'] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

        exchangeAddresses['DAI'] = 0x09cabEC1eAd1c0Ba254B09efb3EE13841712bE14;
        exchangeAddresses['BAT'] = 0x2E642b8D59B45a1D8c5aEf716A84FF44ea665914;
        exchangeAddresses['ZRX'] = 0xaE76c84C9262Cdb9abc0C2c8888e62Db8E22A0bF;
        exchangeAddresses['REP'] = 0x48B04d2A05B6B604d8d5223Fd1984f191DED51af;
    }

     
    function setFactoryLogicAddress(address newAddress) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
         
        factoryLogicAddress = newAddress;
        emit FactoryLogicChanged(newAddress);
    }

     
    function addUser(address newAddress) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
         
        if (!userAddressesSet[newAddress]) {
            userAddresses.push(newAddress);
            userAddressesSet[newAddress] = true;
            emit UserAdded(newAddress);
        }
    }

     
    function addTicker(string memory ticker) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
         
        if (!tickerSet[ticker]) {
            tickers.push(ticker);
            tickerSet[ticker] = true;
            emit TickerAdded(ticker);
        }
    }

     
    function updateTokenAddress(string memory ticker, address newAddress) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
        tokenAddresses[ticker] = newAddress;
    }

     
    function updatecTokenAddress(string memory ticker, address newAddress) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
        ctokenAddresses[ticker] = newAddress;
    }

     
    function updateExchangeAddress(string memory ticker, address newAddress) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
        exchangeAddresses[ticker] = newAddress;
    }

     
     
    function addNewTokenToPositionContracts(string memory ticker, address tokenAddr, address cTokenAddr, address exchangeAddr) public {
        require(factoryLogicAddress == msg.sender|| ownerAddresses[0] == msg.sender || ownerAddresses[1] == msg.sender || ownerAddresses[2] == msg.sender);
         
        tokenAddresses[ticker] = tokenAddr;
        ctokenAddresses[ticker] = cTokenAddr;
        exchangeAddresses[ticker] = exchangeAddr;
        emit NewTokenAddedToPositionContract(ticker, tokenAddr, cTokenAddr, exchangeAddr);
    }

     
    function addNewPositionContract(string memory ticker, address userAddress, address newContractAddress) public {
         
        require(factoryLogicAddress == msg.sender);
        positionContracts[ticker][userAddress] = newContractAddress;
        addUser(userAddress);
         
        emit NewPositionContract(userAddress, newContractAddress, msg.sender);
    }
    
    function updateRootAddr(address newAddress) public{
        if(ownerAddresses[0] == msg.sender){
            ownerAddresses[0] = newAddress;
        } else if (ownerAddresses[1] == msg.sender) {
            ownerAddresses[1] = newAddress;
        } else if (ownerAddresses[2] == msg.sender) {
            ownerAddresses[2] = newAddress;
        }
    }
}