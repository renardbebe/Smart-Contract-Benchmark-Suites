 

pragma solidity ^0.4.18;

 

contract PlayCryptoGaming {

    address contractOwnerAddress = 0x46d9112533ef677059c430E515775e358888e38b;
    uint256 priceContract = 26000000000000000000;


    modifier onlyOwner() {
        require (msg.sender == contractOwnerAddress);
        _;
    }
    
    struct CryptoGamer {
        string name;
        address ownerAddress;
        uint256 curPrice;
        address CryptoGamerAddress;
    }
    CryptoGamer[] cryptoGamers;

    bool cryptoGamersAreInitiated;
    bool isPaused;
    
     
    function pauseGame() public onlyOwner {
        isPaused = true;
    }
    function unPauseGame() public onlyOwner {
        isPaused = false;
    }
    function GetIsPaused() public view returns(bool) {
       return(isPaused);
    }

     
    function purchaseCryptoGamer(uint _cryptoGamerId) public payable {
        require(msg.value == cryptoGamers[_cryptoGamerId].curPrice);
        require(isPaused == false);

         
        uint256 commission1percent = (msg.value / 100);
        
         
        address leastExpensiveCryptoGamerOwner = cryptoGamers[getLeastExpensiveCryptoGamer()].ownerAddress;
        address mostExpensiveCryptoGamerOwner = cryptoGamers[getMostExpensiveCryptoGamer()].ownerAddress;
        
         
        if(leastExpensiveCryptoGamerOwner == address(this)) { 
            leastExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        if(mostExpensiveCryptoGamerOwner == address(this)) { 
            mostExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        
        leastExpensiveCryptoGamerOwner.transfer(commission1percent * 5);  
        mostExpensiveCryptoGamerOwner.transfer(commission1percent * 5);  

         
        uint256 commissionOwner = msg.value - (commission1percent * 15);  
        
         
        if(cryptoGamers[_cryptoGamerId].ownerAddress == address(this)) {
            contractOwnerAddress.transfer(commissionOwner);

        } else {
             
            cryptoGamers[_cryptoGamerId].ownerAddress.transfer(commissionOwner);
        }
        

         
        contractOwnerAddress.transfer(commission1percent * 3);  
        
         
        if(cryptoGamers[_cryptoGamerId].CryptoGamerAddress != 0x0) {
            cryptoGamers[_cryptoGamerId].CryptoGamerAddress.transfer(commission1percent * 2);  
        } else {
             
            contractOwnerAddress.transfer(commission1percent * 2);  
        }
        

         
        cryptoGamers[_cryptoGamerId].ownerAddress = msg.sender;
        cryptoGamers[_cryptoGamerId].curPrice = cryptoGamers[_cryptoGamerId].curPrice + (cryptoGamers[_cryptoGamerId].curPrice / 2);
    }

     
    function purchaseContract() public payable {
        require(msg.value == priceContract);
        
         
        uint256 commission5percent = ((msg.value / 10)/2);
        
         
        address leastExpensiveCryptoGamerOwner = cryptoGamers[getLeastExpensiveCryptoGamer()].ownerAddress;
        address mostExpensiveCryptoGamerOwner = cryptoGamers[getMostExpensiveCryptoGamer()].ownerAddress;
        
         
        if(leastExpensiveCryptoGamerOwner == address(this)) { 
            leastExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        if(mostExpensiveCryptoGamerOwner == address(this)) { 
            mostExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        
         
        leastExpensiveCryptoGamerOwner.transfer(commission5percent);  
        mostExpensiveCryptoGamerOwner.transfer(commission5percent);  

         
        uint256 commissionOwner = msg.value - (commission5percent * 2);  
        
        contractOwnerAddress.transfer(commissionOwner);
        contractOwnerAddress = msg.sender;
    }

    function getPriceContract() public view returns(uint) {
        return(priceContract);
    }

     
    function updatePriceContract(uint256 _newPrice) public onlyOwner {
        priceContract = _newPrice;
    }

     
    function getContractOwnerAddress() public view returns(address) {
        return(contractOwnerAddress);
    }

     
    function updateCryptoGamerPrice(uint _cryptoGamerId, uint256 _newPrice) public {
        require(_newPrice > 0);
        require(cryptoGamers[_cryptoGamerId].ownerAddress == msg.sender);
        require(_newPrice < cryptoGamers[_cryptoGamerId].curPrice);
        cryptoGamers[_cryptoGamerId].curPrice = _newPrice;
    }
    
     
    function getCryptoGamer(uint _cryptoGamerId) public view returns (
        string name,
        address ownerAddress,
        uint256 curPrice,
        address CryptoGamerAddress
    ) {
        CryptoGamer storage _cryptoGamer = cryptoGamers[_cryptoGamerId];

        name = _cryptoGamer.name;
        ownerAddress = _cryptoGamer.ownerAddress;
        curPrice = _cryptoGamer.curPrice;
        CryptoGamerAddress = _cryptoGamer.CryptoGamerAddress;
    }
    
     
    function getLeastExpensiveCryptoGamer() public view returns(uint) {
        uint _leastExpensiveGamerId = 0;
        uint256 _leastExpensiveGamerPrice = 9999000000000000000000;

         
        for (uint8 i = 0; i < cryptoGamers.length; i++) {
            if(cryptoGamers[i].curPrice < _leastExpensiveGamerPrice) {
                _leastExpensiveGamerPrice = cryptoGamers[i].curPrice;
                _leastExpensiveGamerId = i;
            }
        }
        return(_leastExpensiveGamerId);
    }

     
    function getMostExpensiveCryptoGamer() public view returns(uint) {
        uint _mostExpensiveGamerId = 0;
        uint256 _mostExpensiveGamerPrice = 9999000000000000000000;

         
        for (uint8 i = 0; i < cryptoGamers.length; i++) {
            if(cryptoGamers[i].curPrice > _mostExpensiveGamerPrice) {
                _mostExpensiveGamerPrice = cryptoGamers[i].curPrice;
                _mostExpensiveGamerId = i;
            }
        }
        return(_mostExpensiveGamerId);
    }
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
     
    function updateCryptoGamerVerifiedAddress(uint _cryptoGamerId, address _newAddress) public onlyOwner {
        cryptoGamers[_cryptoGamerId].CryptoGamerAddress = _newAddress;
    }
    
     
    function createCryptoGamer(string _cryptoGamerName, uint256 _cryptoGamerPrice, address _verifiedAddress) public onlyOwner {
        cryptoGamers.push(CryptoGamer(_cryptoGamerName, address(this), _cryptoGamerPrice, _verifiedAddress));
    }
    
     
    function InitiateCryptoGamers() public onlyOwner {
        require(cryptoGamersAreInitiated == false);
        cryptoGamers.push(CryptoGamer("Phil", 0x183febd8828a9ac6c70c0e27fbf441b93004fc05, 1012500000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Carlini8", address(this), 310000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Ferocious", 0x1A5fe261E8D9e8efC5064EEccC09B531E6E24BD3, 375000000000000000, 0x1A5fe261E8D9e8efC5064EEccC09B531E6E24BD3));
        cryptoGamers.push(CryptoGamer("Pranked", address(this), 224000000000000000, 0xD387A6E4e84a6C86bd90C158C6028A58CC8Ac459));
        cryptoGamers.push(CryptoGamer("SwagDaPanda", address(this), 181000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Slush", address(this), 141000000000000000, 0x70580eA14d98a53fd59376dC7e959F4a6129bB9b));
        cryptoGamers.push(CryptoGamer("Acapuck", address(this), 107000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Arwynian", address(this), 131000000000000000, 0xA3b61695E46432E5CCCd0427AD956fa146379D08));
        cryptoGamers.push(CryptoGamer("Bohl", address(this), 106000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Corgi", address(this), 91500000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Enderhero", address(this), 104000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Hecatonquiro", address(this), 105000000000000000, 0xB87e73ad25086C43a16fE5f9589Ff265F8A3A9Eb));
        cryptoGamers.push(CryptoGamer("herb", address(this), 101500000000000000, 0x466aCFE9f93D167EA8c8fa6B8515A65Aa47784dD));
        cryptoGamers.push(CryptoGamer("Kail", address(this), 103000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("karupin the cat", 0x5632ca98e5788eddb2397757aa82d1ed6171e5ad, 108100000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("LiveFree", 0x3177abbe93422c9525652b5d4e1101a248a99776, 90100000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Prokiller", address(this), 100200000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Sanko", address(this), 101000000000000000, 0x71f35825a3B1528859dFa1A64b24242BC0d12990));
        cryptoGamers.push(CryptoGamer("TheHermitMonk", address(this), 100000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("TomiSharked", 0x9afbaa3003d9e75c35fde2d1fd283b13d3335f00, 89000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Zalman", 0x9afbaa3003d9e75c35fde2d1fd283b13d3335f00, 92000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("xxFyMxx", address(this), 110000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("UncleTom", address(this), 90000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("legal", address(this), 115000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Terpsicores", address(this), 102000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("triceratops", 0x9afbaa3003d9e75c35fde2d1fd283b13d3335f00, 109000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("souto", address(this), 85000000000000000, 0x0));
        cryptoGamers.push(CryptoGamer("Danimal", 0xa586a3b8939e9c0dc72d88166f6f6bb7558eedce, 85000000000000000, 0x3177Abbe93422c9525652b5d4e1101a248A99776));

    }
}